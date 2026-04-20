export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { clearCart } from "@/lib/cart";

export async function POST() {
  await clearCart();
  return NextResponse.json({ ok: true });
}

