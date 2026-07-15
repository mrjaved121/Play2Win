import type { AdminUser, AdminRole } from "@/lib/types";

// HMAC-signed session token using Web Crypto (works in both the Node.js and
// Edge runtimes, so the same code runs in middleware and route handlers).
// This is a lightweight home-grown JWT-alike, sized for a thesis prototype —
// swap for @supabase/ssr session cookies if you move auth fully to Supabase.

export const SESSION_COOKIE = "bh_session";

const SESSION_SECRET = process.env.SESSION_SECRET ?? "dev-only-insecure-secret-change-me";
if (process.env.NODE_ENV === "production" && !process.env.SESSION_SECRET) {
  console.warn(
    "[auth] SESSION_SECRET is not set — using an insecure default. Set it in .env.local before deploying.",
  );
}

interface SessionPayload {
  sub: string;
  email: string;
  name: string;
  role: AdminRole;
  exp: number;
}

const encoder = new TextEncoder();

function base64UrlEncode(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function base64UrlDecode(value: string): Uint8Array<ArrayBuffer> {
  const padLength = (4 - (value.length % 4)) % 4;
  const padded = value.replace(/-/g, "+").replace(/_/g, "/") + "=".repeat(padLength);
  const binary = atob(padded);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

async function getKey(): Promise<CryptoKey> {
  return crypto.subtle.importKey(
    "raw",
    encoder.encode(SESSION_SECRET),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign", "verify"],
  );
}

export async function createSessionToken(user: AdminUser, maxAgeSec: number): Promise<string> {
  const payload: SessionPayload = {
    sub: user.id,
    email: user.email,
    name: user.name,
    role: user.role,
    exp: Math.floor(Date.now() / 1000) + maxAgeSec,
  };
  const payloadBytes = encoder.encode(JSON.stringify(payload));
  const key = await getKey();
  const signature = await crypto.subtle.sign("HMAC", key, payloadBytes);
  return `${base64UrlEncode(payloadBytes)}.${base64UrlEncode(new Uint8Array(signature))}`;
}

export async function verifySessionToken(token: string | undefined | null): Promise<AdminUser | null> {
  if (!token) return null;
  const [payloadPart, signaturePart] = token.split(".");
  if (!payloadPart || !signaturePart) return null;

  try {
    const payloadBytes = base64UrlDecode(payloadPart);
    const key = await getKey();
    const isValid = await crypto.subtle.verify(
      "HMAC",
      key,
      base64UrlDecode(signaturePart),
      payloadBytes,
    );
    if (!isValid) return null;

    const payload = JSON.parse(new TextDecoder().decode(payloadBytes)) as SessionPayload;
    if (payload.exp * 1000 < Date.now()) return null;

    return { id: payload.sub, email: payload.email, name: payload.name, role: payload.role };
  } catch {
    return null;
  }
}
