import { cookies } from "next/headers";
import { NextResponse } from "next/server";
import { SESSION_COOKIE, verifySessionToken } from "@/lib/auth/session";
import type { AdminUser } from "@/lib/types";

/**
 * Route-handler guard. Returns the authenticated admin, or a ready-to-return
 * 401 NextResponse. Middleware already protects /dashboard/** page loads;
 * this covers the /api/** routes those pages call.
 */
export async function requireAdmin(): Promise<AdminUser | NextResponse> {
  const cookieStore = await cookies();
  const token = cookieStore.get(SESSION_COOKIE)?.value;
  const user = await verifySessionToken(token);
  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
  return user;
}
