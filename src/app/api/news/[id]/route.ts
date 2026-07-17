import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/requireAdmin";
import { getNewsRepository } from "@/lib/repositories";
import type { NewsItem } from "@/lib/types";

export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const { id } = await params;
  const body = await request.json().catch(() => null);
  const patch: Partial<NewsItem> = {};
  if (typeof body?.title === "string") patch.title = body.title.trim();
  if (typeof body?.content === "string") patch.content = body.content.trim();
  if (typeof body?.isActive === "boolean") patch.isActive = body.isActive;
  if (typeof body?.displayOrder === "number" && Number.isFinite(body.displayOrder)) {
    patch.displayOrder = body.displayOrder;
  }

  const item = await getNewsRepository().update(id, patch);
  return NextResponse.json({ news: item });
}

export async function DELETE(
  _request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const { id } = await params;
  await getNewsRepository().remove(id);
  return NextResponse.json({ ok: true });
}
