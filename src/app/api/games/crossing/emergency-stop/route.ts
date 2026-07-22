import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/requireAdmin";
import { getCrossingRepository } from "@/lib/repositories";

/**
 * Voids and fully refunds every currently-pending round platform-wide —
 * see CrossingRepository.emergencyStopAll's doc comment. Deliberately
 * uniform: there is no way to target one player's round through this
 * endpoint or any other.
 */
export async function POST() {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const result = await getCrossingRepository().emergencyStopAll();
  return NextResponse.json(result);
}
