export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { cartCount, cartTotal, setCartLineProtection } from "@/lib/cart";

type Body = {
  itemId?: number;
  years?: 1 | 2 | 3 | null;
  price?: number | null;
};

export async function POST(req: Request) {
  const body = (await req.json().catch(() => null)) as Body | null;
  const itemId = Number(body?.itemId);
  if (!Number.isFinite(itemId) || itemId <= 0) {
    return NextResponse.json({ ok: false, error: "itemId required" }, { status: 400 });
  }

  const yearsRaw = body?.years;
  const priceRaw = Number(body?.price ?? 0);
  const hasProtection = yearsRaw === 1 || yearsRaw === 2 || yearsRaw === 3;

  const cart = await setCartLineProtection(
    itemId,
    hasProtection
      ? {
          years: yearsRaw,
          price: Math.max(0, priceRaw),
        }
      : null
  );

  return NextResponse.json({ ok: true, count: cartCount(cart), total: cartTotal(cart) });
}

