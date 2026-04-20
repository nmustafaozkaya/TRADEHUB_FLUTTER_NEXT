export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { getOrderDetailForAdmin, listOrderLinesForAdmin } from "@/lib/repos/adminOrders";

export async function GET(_req: Request, ctx: { params: Promise<{ id: string }> }) {
  const params = await ctx.params;
  const orderId = Number(params.id);
  if (!Number.isFinite(orderId) || orderId <= 0) {
    return NextResponse.json({ ok: false, error: "Invalid order id." }, { status: 400 });
  }

  const [order, lines] = await Promise.all([
    getOrderDetailForAdmin(orderId),
    listOrderLinesForAdmin(orderId),
  ]);
  if (!order) {
    return NextResponse.json({ ok: false, error: "Order not found." }, { status: 404 });
  }

  return NextResponse.json({ ok: true, order, lines });
}

