import { mockLatency } from "@/lib/mock/delay";
import type { AdminUser } from "@/lib/types";
import type { AuthRepository } from "@/lib/repositories/types";

interface SeedAdmin {
  email: string;
  password: string;
  user: AdminUser;
}

// Demo credentials for the thesis prototype. Override via ADMIN_EMAIL /
// ADMIN_PASSWORD in .env.local. See README.md "Demo access".
const SEED_ADMINS: SeedAdmin[] = [
  {
    email: process.env.ADMIN_EMAIL?.toLowerCase() ?? "admin@blackhole.dev",
    password: process.env.ADMIN_PASSWORD ?? "BlackHole#2026",
    user: {
      id: "admin_1",
      email: process.env.ADMIN_EMAIL?.toLowerCase() ?? "admin@blackhole.dev",
      name: "Research Admin",
      role: "superadmin",
    },
  },
  {
    email: "analyst@blackhole.dev",
    password: "Analyst#2026",
    user: {
      id: "admin_2",
      email: "analyst@blackhole.dev",
      name: "Data Analyst",
      role: "analyst",
    },
  },
];

export const mockAuthRepository: AuthRepository = {
  async signIn(email: string, password: string): Promise<AdminUser | null> {
    await mockLatency(200, 500);
    const match = SEED_ADMINS.find(
      (a) => a.email === email.trim().toLowerCase() && a.password === password,
    );
    return match ? match.user : null;
  },
};

export const DEMO_ADMIN_EMAIL = SEED_ADMINS[0].email;
export const DEMO_ADMIN_PASSWORD = SEED_ADMINS[0].password;
