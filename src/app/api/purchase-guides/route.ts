import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/requireAdmin";
import { getPurchaseGuideRepository } from "@/lib/repositories";
import type { NewPurchaseGuideInput } from "@/lib/types";

export async function GET() {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const guides = await getPurchaseGuideRepository().list();
  return NextResponse.json({ guides });
}

export async function POST(request: Request) {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const body = await request.json().catch(() => null);
  const title = typeof body?.title === "string" ? body.title.trim() : "";
  const content = typeof body?.content === "string" ? body.content.trim() : "";
  const isActive = typeof body?.isActive === "boolean" ? body.isActive : true;

  if (!title) {
    return NextResponse.json({ error: "title is required." }, { status: 400 });
  }
  if (!content) {
    return NextResponse.json({ error: "content is required." }, { status: 400 });
  }

  const input: NewPurchaseGuideInput = { title, content, isActive };
  const guide = await getPurchaseGuideRepository().create(input);
  return NextResponse.json({ guide }, { status: 201 });
}
