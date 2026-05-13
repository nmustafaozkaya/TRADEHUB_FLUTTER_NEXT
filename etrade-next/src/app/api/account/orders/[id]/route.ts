export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { getUser } from "@/lib/auth";
import { findUserByLogin } from "@/lib/repos/users";
import { getOrderForUser, listOrderLinesForUser } from "@/lib/repos/ordersHistory";
import { orderStatusLabel } from "@/lib/orderStatus";
import { shippingFee } from "@/lib/shipping";

async function resolveUserId(req: Request): Promise<number | null> {
  const sessionUser = await getUser();
  if (sessionUser?.id) return Number(sessionUser.id);
  const fromHeader = Number(req.headers.get("x-user-id") || 0);
  if (Number.isFinite(fromHeader) && fromHeader > 0) return fromHeader;
  const login = (req.headers.get("x-username") || "").trim();
  if (!login) return null;
  const user = await findUserByLogin(login);
  return user?.ID ? Number(user.ID) : null;
}

export async function GET(req: Request, ctx: { params: Promise<{ id: string }> }) {
  const userId = await resolveUserId(req);
  if (!userId) {
    return NextResponse.json({ ok: false, error: "Authentication required." }, { status: 401 });
  }

  const params = await ctx.params;
  const orderId = Number(params.id);
  if (!Number.isFinite(orderId) || orderId <= 0) {
    return NextResponse.json({ ok: false, error: "Invalid order id." }, { status: 400 });
  }

  const order = await getOrderForUser(userId, orderId);
  if (!order) {
    return NextResponse.json({ ok: false, error: "Order not found." }, { status: 404 });
  }

  const lines = await listOrderLinesForUser(userId, orderId);
  const subtotal = lines.reduce((sum, line) => sum + Number(line.LineTotal || 0), 0);

  return NextResponse.json({
    ok: true,
    order: {
      id: Number(order.ID),
      totalPrice: Number(order.TotalPrice ?? 0),
      status: Number(order.Status ?? 0),
      statusLabel: orderStatusLabel(Number(order.Status ?? 0)),
      date: order.Date ? order.Date.toISOString() : null,
      cargoCompany: order.CargoCompany || null,
      trackingNo: order.TrackingNo || null,
      addressText: order.AddressText || null,
      city: order.City || null,
      town: order.Town || null,
      rejectReasonCode: order.RejectReasonCode || null,
      rejectReasonNote: order.RejectReasonNote || null,
      subtotal,
      shippingFee: shippingFee(subtotal),
    },
    lines: lines.map((line) => ({
      itemId: Number(line.ItemId),
      itemName: line.ItemName || 'Item',
      brand: line.Brand || '',
      imageUrl: line.ImageUrl || null,
      qty: Number(line.Qty ?? 0),
      unitPrice: Number(line.UnitPrice ?? 0),
      lineTotal: Number(line.LineTotal ?? 0),
      hasReviewed: Number(line.HasReviewed ?? 0) > 0,
    })),
  });
}