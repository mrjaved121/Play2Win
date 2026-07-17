import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/requireAdmin";
import { getAppContentRepository } from "@/lib/repositories";
import type { AppContentInput } from "@/lib/types";

export async function GET(
  _request: Request,
  { params }: { params: Promise<{ key: string }> },
) {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const { key } = await params;
  const content = await getAppContentRepository().getByKey(key);
  return NextResponse.json({ content });
}

export async function PUT(
  request: Request,
  { params }: { params: Promise<{ key: string }> },
) {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const { key } = await params;
  const body = await request.json().catch(() => null);
  const title = typeof body?.title === "string" ? body.title.trim() : "";
  const content = typeof body?.content === "string" ? body.content.trim() : "";
  const isActive = typeof body?.isActive === "boolean" ? body.isActive : true;

  const input: AppContentInput = { title, content, isActive };
  const saved = await getAppContentRepository().upsert(key, input);
  return NextResponse.json({ content: saved });
}
