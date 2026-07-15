import { NextResponse } from "next/server";
import { getAuthRepository } from "@/lib/repositories";
import { createSessionToken, SESSION_COOKIE } from "@/lib/auth/session";

const DEFAULT_MAX_AGE_SEC = 60 * 60 * 8; // 8 hours
const REMEMBER_MAX_AGE_SEC = 60 * 60 * 24 * 30; // 30 days

export async function POST(request: Request) {
  const body = await request.json().catch(() => null);
  const email = typeof body?.email === "string" ? body.email : "";
  const password = typeof body?.password === "string" ? body.password : "";
  const rememberMe = Boolean(body?.rememberMe);

  if (!email || !password) {
    return NextResponse.json({ error: "Email and password are required." }, { status: 400 });
  }

  const user = await getAuthRepository().signIn(email, password);
  if (!user) {
    return NextResponse.json({ error: "Invalid email or password." }, { status: 401 });
  }

  const maxAge = rememberMe ? REMEMBER_MAX_AGE_SEC : DEFAULT_MAX_AGE_SEC;
  const token = await createSessionToken(user, maxAge);

  const response = NextResponse.json({ user });
  response.cookies.set(SESSION_COOKIE, token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    path: "/",
    maxAge,
  });
  return response;
}
