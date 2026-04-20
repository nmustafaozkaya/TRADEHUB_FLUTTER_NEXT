export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { cartCount, cartTotal, updateCartQty } from "@/lib/cart";

export async function POST(req: Request) {
  const body = (await req.json().catch(() => null)) as null | { itemId?: number; qty?: number };
  const itemId = Number(body?.itemId);
  const qty = Math.max(0, Number(body?.qty ?? 0));

  if (!Number.isFinite(itemId) || itemId <= 0) {
    return NextResponse.json({ error: "itemId required" }, { status: 400 });
  }

  const cart = await updateCartQty(itemId, qty);
  return NextResponse.json({ ok: true, count: cartCount(cart), total: cartTotal(cart) });
}

