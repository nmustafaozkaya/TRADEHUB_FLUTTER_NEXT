export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { cartCount, cartTotal, removeFromCart } from "@/lib/cart";

export async function POST(req: Request) {
  const body = (await req.json().catch(() => null)) as null | { itemId?: number };
  const itemId = Number(body?.itemId);

  if (!Number.isFinite(itemId) || itemId <= 0) {
    return NextResponse.json({ error: "itemId required" }, { status: 400 });
  }

  const cart = await removeFromCart(itemId);
  return NextResponse.json({ ok: true, count: cartCount(cart), total: cartTotal(cart) });
}

