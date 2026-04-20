export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { updateOrderStatusByAdmin } from "@/lib/repos/adminOrders";

type StatusBody = {
  status?: number;
  note?: string;
  rejectReasonCode?: string;
  rejectReasonNote?: string;
  cargoCompany?: string;
  trackingNo?: string;
};

export async function POST(req: Request, ctx: { params: Promise<{ id: string }> }) {
  const params = await ctx.params;
  const orderId = Number(params.id);
  if (!Number.isFinite(orderId) || orderId <= 0) {
    return NextResponse.json({ ok: false, error: "Invalid order id." }, { status: 400 });
  }

  const body = (await req.json().catch(() => null)) as StatusBody | null;
  const status = Number(body?.status);
  if (!Number.isFinite(status)) {
    return NextResponse.json({ ok: false, error: "status is required." }, { status: 400 });
  }

  try {
    await updateOrderStatusByAdmin({
      orderId,
      newStatus: status,
      note: body?.note ?? null,
      rejectReasonCode: body?.rejectReasonCode ?? null,
      rejectReasonNote: body?.rejectReasonNote ?? null,
      cargoCompany: body?.cargoCompany ?? null,
      trackingNo: body?.trackingNo ?? null,
    });
    return NextResponse.json({ ok: true });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Failed to update order.";
    return NextResponse.json({ ok: false, error: message }, { status: 400 });
  }
}

