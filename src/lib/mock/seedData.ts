import { mulberry32 } from "@/lib/utils";
import type {
  Game,
  GameCategory,
  NewsItem,
  Player,
  PlayerStatus,
  PurchaseGuideEntry,
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
  /** Set only for catalog rows that back a real in-app screen. */
  appEntryPoint?: "slots" | "crash" | "wheel" | "scratch";
}> = [
  { name: "Nova Slots", category: "slots", rtp: 96.2, releaseDaysAgo: 540, appEntryPoint: "slots" },
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
  { name: "Multiplier Climb", category: "arcade", rtp: 95.0, releaseDaysAgo: 5, appEntryPoint: "crash" },
  { name: "Lucky Wheel", category: "arcade", rtp: 92.0, releaseDaysAgo: 2, appEntryPoint: "wheel" },
  { name: "Scratch Card", category: "arcade", rtp: 92.4, releaseDaysAgo: 1, appEntryPoint: "scratch" },
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
      // Keep the real, in-app-playable games always active — a random
      // "maintenance" flip on dev-server restart would otherwise lock one
      // out of the lobby unpredictably.
      status: def.appEntryPoint !== undefined || rand() <= 0.93 ? "active" : "maintenance",
      rtp: def.rtp,
      totalSessions,
      totalWagered,
      totalPayout,
      releaseDate: daysAgoIso(def.releaseDaysAgo, 0),
      accentSeed: i,
      appEntryPoint: def.appEntryPoint,
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

const HELP_SUPPORT_DEFINITIONS: Array<{
  title: string;
  content: string;
  isActive: boolean;
  daysAgo: number;
}> = [
  {
    title: "How do I contact support?",
    content:
      "Reach our support team 24/7 via the in-app chat or email support@blackhole.example. Average response time is under 10 minutes.",
    isActive: true,
    daysAgo: 1,
  },
  {
    title: "Deposit & withdrawal limits",
    content:
      "Minimum deposit is 10 credits; minimum withdrawal is 25 credits. Withdrawals are typically processed within 24 hours.",
    isActive: true,
    daysAgo: 5,
  },
  {
    title: "Verifying your account",
    content:
      "To verify your account, go to Settings > Verification and upload a valid government-issued ID. Verification usually completes within one business day.",
    isActive: true,
    daysAgo: 8,
  },
  {
    title: "Responsible gaming tools",
    content:
      "You can set deposit limits, session reminders, and self-exclusion periods any time from Settings > Responsible Gaming.",
    isActive: true,
    daysAgo: 20,
  },
  {
    title: "Scheduled maintenance window",
    content:
      "The platform may be briefly unavailable Thursdays between 02:00-02:30 UTC for routine maintenance.",
    isActive: false,
    daysAgo: 45,
  },
];

function buildNews(): NewsItem[] {
  return HELP_SUPPORT_DEFINITIONS.map((def, i) => {
    const timestamp = daysAgoIso(def.daysAgo, 0);
    return {
      id: `nw_${(i + 1).toString().padStart(3, "0")}`,
      title: def.title,
      content: def.content,
      isActive: def.isActive,
      displayOrder: i,
      createdAt: timestamp,
      updatedAt: timestamp,
    };
  });
}

const PURCHASE_GUIDE_DEFINITIONS: Array<{
  title: string;
  content: string;
  isActive: boolean;
  daysAgo: number;
}> = [
  {
    title: "Bank Transfer",
    content:
      "Transfer to our research account (details available from support) and include your in-app Guest ID as the reference. Credits are added manually within one business day — this is a non-commercial research prototype, not a live payment processor.",
    isActive: true,
    daysAgo: 3,
  },
  {
    title: "Mobile Wallet — JazzCash / EasyPaisa",
    content:
      "Send to the wallet number provided by support and share the transaction ID along with your Guest ID. Confirmation typically takes a few hours during business hours.",
    isActive: true,
    daysAgo: 3,
  },
  {
    title: "Cryptocurrency",
    content:
      "USDT (TRC20) deposits are accepted for research participants outside standard banking hours. Contact support first to get a deposit address — never send funds to an address you haven't confirmed with us directly.",
    isActive: true,
    daysAgo: 3,
  },
  {
    title: "Contact Support for Bulk Purchases",
    content:
      "Need a larger credit balance for extended testing? Reach out via Help & Support and we'll arrange it directly — no need to make multiple smaller purchases.",
    isActive: true,
    daysAgo: 2,
  },
];

function buildPurchaseGuides(): PurchaseGuideEntry[] {
  return PURCHASE_GUIDE_DEFINITIONS.map((def, i) => {
    const timestamp = daysAgoIso(def.daysAgo, 0);
    return {
      id: `pg_${(i + 1).toString().padStart(3, "0")}`,
      title: def.title,
      content: def.content,
      isActive: def.isActive,
      displayOrder: i,
      createdAt: timestamp,
      updatedAt: timestamp,
    };
  });
}

export const seedPlayers: Player[] = buildPlayers(340);
export const seedGames: Game[] = buildGames();
export const seedTransactions: Transaction[] = buildTransactions(
  seedPlayers,
  seedGames,
  2400,
);
export const seedNews: NewsItem[] = buildNews();
export const seedPurchaseGuides: PurchaseGuideEntry[] = buildPurchaseGuides();
