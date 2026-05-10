export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { getUser } from "@/lib/auth";
import { findUserByLogin } from "@/lib/repos/users";
import { listOrdersForUserUi } from "@/lib/repos/ordersHistory";
import { orderStatusLabel } from "@/lib/orderStatus";
import { isPaymentMethod } from "@/lib/payment";

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

export async function GET(req: Request) {
  const userId = await resolveUserId(req);
  if (!userId) {
    return NextResponse.json({ ok: false, error: "Authentication required." }, { status: 401 });
  }

  const url = new URL(req.url);
  const q = url.searchParams.get("q") || undefined;
  const status = url.searchParams.get("status") || "all";
  const orders = await listOrdersForUserUi(userId, { q, status });

  const payload = orders.map((order) => ({
    id: Number(order.ID),
    totalPrice: Number(order.TotalPrice ?? 0),
    status: Number(order.Status ?? 0),
    statusLabel: orderStatusLabel(Number(order.Status ?? 0)),
    date: order.Date ? order.Date.toISOString() : null,
    totalQty: Number(order.TotalQty ?? 0),
    distinctItems: Number(order.DistinctItems ?? 0),
    cargoCompany: order.CargoCompany || null,
    trackingNo: order.TrackingNo || null,
    addressText: order.AddressText || null,
    city: order.City || null,
    town: order.Town || null,
    rejectReasonCode: order.RejectReasonCode || null,
    rejectReasonNote: order.RejectReasonNote || null,
  }));

  return NextResponse.json({ ok: true, orders: payload });
}

export async function POST(req: Request) {
  const userId = await resolveUserId(req);
  if (!userId) {
    return NextResponse.json({ ok: false, error: "Authentication required." }, { status: 401 });
  }

  try {
    const body = await req.json() as {
      addressId: number;
      paymentMethod: string;
      lines: { itemId: number; name?: string; qty: number; unitPrice: number }[];
    };

    const { addressId, paymentMethod, lines } = body;

    if (!addressId || !lines?.length) {
      return NextResponse.json({ ok: false, error: "Missing required fields." }, { status: 400 });
    }

    // Validate and cast paymentMethod
    const pm = isPaymentMethod(paymentMethod) ? paymentMethod : "card";

    // Ensure CartLine shape — name is required
    const cartLines = lines.map((l) => ({
      itemId: Number(l.itemId),
      name: l.name ?? `Item #${l.itemId}`,
      unitPrice: Number(l.unitPrice),
      qty: Number(l.qty),
      protection: null,
    }));

    const { createOrder } = await import("@/lib/repos/orders");
    const orderId = await createOrder({
      userId,
      addressId: Number(addressId),
      paymentMethod: pm,
      lines: cartLines,
    });

    return NextResponse.json({ ok: true, orderId });
  } catch (e) {
    const message = e instanceof Error ? e.message : "Could not create order.";
    return NextResponse.json({ ok: false, error: message }, { status: 500 });
  }
}