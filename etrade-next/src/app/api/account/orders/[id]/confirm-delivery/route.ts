export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { getUser } from "@/lib/auth";
import { confirmDeliveredByUser } from "@/lib/repos/adminOrders";

export async function POST(_req: Request, ctx: { params: Promise<{ id: string }> }) {
  const user = await getUser();
  if (!user) {
    return NextResponse.json({ ok: false, error: "Authentication required." }, { status: 401 });
  }

  const params = await ctx.params;
  const orderId = Number(params.id);
  if (!Number.isFinite(orderId) || orderId <= 0) {
    return NextResponse.json({ ok: false, error: "Invalid order id." }, { status: 400 });
  }

  try {
    await confirmDeliveredByUser(orderId, user.id);
    return NextResponse.json({ ok: true });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Could not confirm delivery.";
    return NextResponse.json({ ok: false, error: message }, { status: 400 });
  }
}

