import { mulberry32 } from "@/lib/utils";
import type {
  Game,
  GameCategory,
  Player,
  PlayerStatus,
  Transaction,
  TransactionStatus,
  TransactionType,
  VipTier,
} from "@/lib/types";

// Deterministic seed so the in-memory dataset is stable within a server
// process. This is a research-prototype data layer — see
// src/lib/repositories/README-datasource.md for how this swaps for Supabase.
const rand = mulberry32(20260716);

function pick<T>(arr: readonly T[]): T {
  return arr[Math.floor(rand() * arr.length)];
}

function randInt(min: number, max: number): number {
  return Math.floor(min + rand() * (max - min + 1));
}

function daysAgoIso(days: number, jitterHours = 24): string {
  const ms =
    Date.now() -
    days * 24 * 60 * 60 * 1000 -
    randInt(0, jitterHours) * 60 * 60 * 1000;
  return new Date(ms).toISOString();
}

const FIRST_NAMES = [
  "Ava", "Liam", "Noor", "Kai", "Zara", "Omar", "Mia", "Theo", "Layla", "Finn",
  "Sana", "Leo", "Priya", "Jonas", "Nadia", "Elin", "Farid", "Ines", "Malik", "Tara",
  "Yusuf", "Chloe", "Arjun", "Sofia", "Ravi", "Nora", "Dmitri", "Amara", "Hugo", "Lina",
];
const LAST_INITIALS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split("");
const COUNTRIES = [
  "United Kingdom", "Ireland", "Germany", "Canada", "Australia", "Sweden",
  "Netherlands", "Malta", "Portugal", "New Zealand", "Finland", "Spain",
];
const PLAYER_STATUS_WEIGHTS: PlayerStatus[] = [
  ...Array(88).fill("active"),
  ...Array(8).fill("suspended"),
  ...Array(4).fill("banned"),
] as PlayerStatus[];
const VIP_TIERS: VipTier[] = ["bronze", "silver", "gold", "platinum"];

export const GAME_DEFINITIONS: Array<{
  name: string;
  category: GameCategory;
  rtp: number;
  releaseDaysAgo: number;
}> = [
  { name: "Nova Slots", category: "slots", rtp: 96.2, releaseDaysAgo: 540 },
  { name: "Event Horizon", category: "slots", rtp: 95.4, releaseDaysAgo: 460 },
  { name: "Quasar Wheel", category: "arcade", rtp: 94.8, releaseDaysAgo: 400 },
  { name: "Pulsar Blackjack", category: "table", rtp: 98.9, releaseDaysAgo: 380 },
  { name: "Singularity Scratch", category: "arcade", rtp: 93.1, releaseDaysAgo: 320 },
  { name: "Nebula Bingo", category: "arcade", rtp: 92.6, releaseDaysAgo: 300 },
  { name: "Orbit Drop", category: "puzzle", rtp: 95.9, releaseDaysAgo: 240 },
  { name: "Meteor Match", category: "puzzle", rtp: 96.7, releaseDaysAgo: 210 },
  { name: "Comet Rush", category: "arcade", rtp: 94.3, releaseDaysAgo: 160 },
  { name: "Supernova Poker", category: "table", rtp: 97.8, releaseDaysAgo: 120 },
  { name: "Dark Matter Dice", category: "table", rtp: 95.1, releaseDaysAgo: 75 },
  { name: "Wormhole Roulette", category: "table", rtp: 97.3, releaseDaysAgo: 30 },
];

function buildPlayers(count: number): Player[] {
  const players: Player[] = [];
  for (let i = 0; i < count; i++) {
    const first = pick(FIRST_NAMES);
    const last = pick(LAST_INITIALS);
    const joinedDaysAgo = randInt(1, 620);
    const totalWagered = randInt(50, 42000);
    const status = pick(PLAYER_STATUS_WEIGHTS);
    players.push({
      id: `pl_${(i + 1).toString().padStart(5, "0")}`,
      displayName: `${first} ${last}.`,
      email: `${first.toLowerCase()}.${last.toLowerCase()}${i}@mailbox.test`,
      status,
      vipTier: VIP_TIERS[Math.min(3, Math.floor(rand() * rand() * 4))],
      creditBalance: randInt(0, 8000),
      totalWagered,
      totalDeposited: Math.round(totalWagered * (0.4 + rand() * 0.5)),
      gamesPlayed: randInt(1, 900),
      country: pick(COUNTRIES),
      joinedAt: daysAgoIso(joinedDaysAgo),
      lastActiveAt: daysAgoIso(randInt(0, Math.min(joinedDaysAgo, 21))),
    });
  }
  return players;
}

function buildGames(): Game[] {
  return GAME_DEFINITIONS.map((def, i) => {
    const totalSessions = randInt(4000, 120000);
    const totalWagered = Math.round(totalSessions * randInt(8, 40));
    const totalPayout = Math.round(totalWagered * (def.rtp / 100));
    return {
      id: `gm_${(i + 1).toString().padStart(3, "0")}`,
      name: def.name,
      category: def.category,
      status: rand() > 0.93 ? "maintenance" : "active",
      rtp: def.rtp,
      totalSessions,
      totalWagered,
      totalPayout,
      releaseDate: daysAgoIso(def.releaseDaysAgo, 0),
      accentSeed: i,
    };
  });
}

function buildTransactions(players: Player[], games: Game[], count: number): Transaction[] {
  const TYPE_WEIGHTS: TransactionType[] = [
    ...Array(30).fill("wager"),
    ...Array(20).fill("payout"),
    ...Array(20).fill("deposit"),
    ...Array(15).fill("withdrawal"),
    ...Array(15).fill("bonus"),
  ] as TransactionType[];
  const STATUS_WEIGHTS: TransactionStatus[] = [
    ...Array(88).fill("completed"),
    ...Array(6).fill("pending"),
    ...Array(4).fill("failed"),
    ...Array(2).fill("reversed"),
  ] as TransactionStatus[];

  const transactions: Transaction[] = [];
  for (let i = 0; i < count; i++) {
    const player = pick(players);
    const type = pick(TYPE_WEIGHTS);
    const usesGame = type === "wager" || type === "payout";
    const game = usesGame ? pick(games) : undefined;
    const daysAgo = rand() * 90;
    // Payout range is kept below wager range so the house holds a positive
    // edge on average (mirroring RTP < 100%) instead of net-losing money.
    const amount =
      type === "withdrawal" || type === "wager"
        ? -randInt(5, 900)
        : type === "payout"
          ? randInt(5, 650)
          : randInt(5, type === "deposit" ? 2500 : 1600);
    transactions.push({
      id: `tx_${(i + 1).toString().padStart(6, "0")}`,
      playerId: player.id,
      playerName: player.displayName,
      type,
      status: pick(STATUS_WEIGHTS),
      amount,
      gameId: game?.id,
      gameName: game?.name,
      createdAt: daysAgoIso(daysAgo, 24),
    });
  }
  return transactions.sort(
    (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
  );
}

export const seedPlayers: Player[] = buildPlayers(340);
export const seedGames: Game[] = buildGames();
export const seedTransactions: Transaction[] = buildTransactions(
  seedPlayers,
  seedGames,
  2400,
);
