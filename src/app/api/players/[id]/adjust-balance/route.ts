import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/requireAdmin";
import { getPlayersRepository } from "@/lib/repositories";

export async function POST(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const { id } = await params;
  const body = await request.json().catch(() => null);
  const amount = Number(body?.amount);
  const note = typeof body?.note === "string" ? body.note.trim() || undefined : undefined;

  if (!Number.isFinite(amount) || !Number.isInteger(amount) || amount === 0) {
    return NextResponse.json({ error: "amount must be a non-zero whole number." }, { status: 400 });
  }

  try {
    const player = await getPlayersRepository().adjustBalance(id, { amount, note });
    return NextResponse.json({ player });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Failed to adjust balance.";
    return NextResponse.json({ error: message }, { status: 400 });
  }
}
