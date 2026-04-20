export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { cartCount, getCart, cartTotal } from "@/lib/cart";

export async function GET() {
  const cart = await getCart();
  return NextResponse.json({
    cart,
    count: cartCount(cart),
    total: cartTotal(cart),
  });
}

