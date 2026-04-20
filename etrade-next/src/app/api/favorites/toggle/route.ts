export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { toggleFavorite } from "@/lib/favorites";

export async function POST(req: Request) {
  const body = (await req.json().catch(() => null)) as null | { itemId?: number };
  const itemId = Number(body?.itemId);
  if (!itemId) return NextResponse.json({ error: "itemId required" }, { status: 400 });
  const favs = await toggleFavorite(itemId);
  return NextResponse.json({ ok: true, ids: favs.ids });
}

