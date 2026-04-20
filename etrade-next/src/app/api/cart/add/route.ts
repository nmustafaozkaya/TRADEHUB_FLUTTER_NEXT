export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { addToCart, cartCount, cartTotal } from "@/lib/cart";

export async function POST(req: Request) {
  const body = (await req.json().catch(() => null)) as null | {
    itemId?: number;
    name?: string;
    unitPrice?: number;
    qty?: number;
  };

  const itemId = Number(body?.itemId);
  const qty = Math.max(1, Number(body?.qty ?? 1));
  const name = String(body?.name ?? "");
  const unitPrice = Number(body?.unitPrice ?? 0);

  if (!Number.isFinite(itemId) || itemId <= 0) {
    return NextResponse.json({ error: "itemId required" }, { status: 400 });
  }

  const cart = await addToCart({ itemId, qty, name: name || `Item #${itemId}`, unitPrice });
  return NextResponse.json({ ok: true, count: cartCount(cart), total: cartTotal(cart) });
}

