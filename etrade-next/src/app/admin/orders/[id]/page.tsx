"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { formatTry } from "@/lib/format";
import { ORDER_STATUS, orderStatusLabel } from "@/lib/orderStatus";
import { itemPrimaryImageSrc } from "@/lib/itemImage";

type AdminOrder = {
  ID: number;
  UserId: number;
  Username: string | null;
  NameSurname: string | null;
  Date: string | null;
  TotalPrice: number;
  Status: number;
  RejectReasonCode: string | null;
  RejectReasonNote: string | null;
  CargoCompany: string | null;
  TrackingNo: string | null;
  AddressText: string | null;
  City: string | null;
  Town: string | null;
  ShippedNote?: string | null;
  ShippingInfoNote?: string | null;
};

type AdminOrderLine = {
  ItemId: number;
  ItemName: string | null;
  Brand: string | null;
  ImageUrl?: string | null;
  Qty: number;
  UnitPrice: number;
  LineTotal: number;
};

const CARGO_OPTIONS = ["Yurtiçi Kargo", "Aras Kargo", "MNG Kargo", "PTT Kargo", "Sürat Kargo"];
const REJECT_OPTIONS = [
  { code: "LOW_STOCK", label: "Stok yok" },
  { code: "PRICE_CHANGED", label: "Fiyat değişti" },
  { code: "DAMAGED", label: "Ürün hasarlı" },
  { code: "OTHER", label: "Diğer" },
];

const ORDER_TIMELINE = [
  { status: ORDER_STATUS.PLACED, label: "Order placed" },
  { status: ORDER_STATUS.PREPARING, label: "Preparing" },
  { status: ORDER_STATUS.SHIPPED, label: "Shipped" },
  { status: ORDER_STATUS.DELIVERED, label: "Delivered" },
  { status: ORDER_STATUS.COMPLETED, label: "Completed" },
];

function statusDetailText(status: number) {
  if (status === ORDER_STATUS.PLACED) return "Order placed, waiting admin approval.";
  if (status === ORDER_STATUS.PREPARING) return "Order approved and preparing.";
  if (status === ORDER_STATUS.SHIPPED) return "Order shipped to cargo.";
  if (status === ORDER_STATUS.DELIVERED) return "Delivered by cargo, waiting customer confirmation.";
  if (status === ORDER_STATUS.COMPLETED) return "Order completed.";
  if (status === ORDER_STATUS.REJECTED) return "Order rejected by admin.";
  return orderStatusLabel(status);
}

export default function AdminOrderDetailPage() {
  const router = useRouter();
  const params = useParams<{ id: string }>();
  const orderId = Number(params?.id || 0);

  const [ready, setReady] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [order, setOrder] = useState<AdminOrder | null>(null);
  const [lines, setLines] = useState<AdminOrderLine[]>([]);
  const [cargoCompany, setCargoCompany] = useState(CARGO_OPTIONS[0]);
  const [trackingNo, setTrackingNo] = useState("");
  const [showShippingPanel, setShowShippingPanel] = useState(false);
  const [showRejectPanel, setShowRejectPanel] = useState(false);
  const [rejectCode, setRejectCode] = useState(REJECT_OPTIONS[0].code);
  const [rejectNote, setRejectNote] = useState("");

  useEffect(() => {
    const isAdminLoggedIn = sessionStorage.getItem("admin-auth") === "ok";
    if (!isAdminLoggedIn) {
      router.replace("/admin");
      return;
    }
    setReady(true);
  }, [router]);

  const load = async () => {
    if (!orderId) return;
    setLoading(true);
    setError("");
    try {
      const res = await fetch(`/api/admin/orders/${orderId}`, { cache: "no-store" });
      const data = (await res.json().catch(() => null)) as
        | { ok?: boolean; order?: AdminOrder; lines?: AdminOrderLine[]; error?: string }
        | null;
      if (!res.ok || !data?.ok || !data.order) {
        setError(data?.error || "Could not load order.");
        return;
      }
      setOrder(data.order);
      setLines(Array.isArray(data.lines) ? data.lines : []);
      if (data.order.CargoCompany) setCargoCompany(data.order.CargoCompany);
      if (data.order.TrackingNo) setTrackingNo(data.order.TrackingNo);
    } catch {
      setError("Could not load order.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (ready) void load();
  }, [ready, orderId]);

  const updateStatus = async (payload: {
    status: number;
    note?: string;
    rejectReasonCode?: string;
    rejectReasonNote?: string;
    cargoCompany?: string;
    trackingNo?: string;
  }) => {
    const res = await fetch(`/api/admin/orders/${orderId}/status`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const data = (await res.json().catch(() => null)) as { ok?: boolean; error?: string } | null;
    if (!res.ok || !data?.ok) throw new Error(data?.error || "Update failed.");
    await load();
  };

  const subtotal = useMemo(
    () => lines.reduce((sum, l) => sum + Number(l.LineTotal ?? 0), 0),
    [lines]
  );
  const shipping = Math.max(0, Number(order?.TotalPrice ?? 0) - subtotal);
  const shippingInfoText =
    order?.ShippingInfoNote ||
    (order?.ShippedNote && order.ShippedNote !== "Shipped by admin." ? order.ShippedNote : "");
  const activeStepIndex = Math.max(
    0,
    ORDER_TIMELINE.findIndex((s) => s.status === order?.Status)
  );

  if (!ready || loading) {
    return <div className="p-6 text-sm text-slate-300">Loading order details...</div>;
  }

  if (!order) {
    return (
      <div className="space-y-3 p-6">
        <p className="text-sm text-rose-300">{error || "Order not found."}</p>
        <Link href="/admin/dashboard" className="text-sm text-cyan-300 hover:underline">
          Back to dashboard
        </Link>
      </div>
    );
  }

  return (
    <main className="space-y-4 p-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-white">Order Details</h1>
        <Link href="/admin/dashboard" className="text-sm text-slate-400 hover:text-slate-200">
          ← All Orders
        </Link>
      </div>

      <section className="rounded-xl border border-slate-800 bg-slate-900/70 p-4">
        <div className="grid gap-3 md:grid-cols-6">
          <div><div className="text-xs text-slate-400">Order No</div><div className="text-sm text-slate-100">#{order.ID}</div></div>
          <div><div className="text-xs text-slate-400">Order Date</div><div className="text-sm text-slate-100">{order.Date ? new Date(order.Date).toLocaleString() : "-"}</div></div>
          <div><div className="text-xs text-slate-400">Order Summary</div><div className="text-sm text-slate-100">1 package, {lines.length} items</div></div>
          <div><div className="text-xs text-slate-400">Order Status</div><div className="text-sm text-emerald-300">{statusDetailText(order.Status)}</div></div>
          <div><div className="text-xs text-slate-400">Total</div><div className="text-sm font-semibold text-slate-100">{formatTry(order.TotalPrice)}</div></div>
          <div className="text-right">
            <button type="button" className="rounded-lg border border-slate-700 px-3 py-1.5 text-xs text-slate-200 hover:bg-slate-800">
              Invoice
            </button>
          </div>
        </div>
      </section>

      <section className="rounded-xl border border-slate-800 bg-slate-900/70 p-4">
        <div className="text-sm font-semibold text-slate-100">{orderStatusLabel(order.Status)}</div>
        <p className="mt-1 text-sm text-slate-300">{statusDetailText(order.Status)}</p>

        <div className="mt-3">
          <div className="mb-2 text-[11px] uppercase tracking-wide text-slate-400">Order progress</div>
          <div className="flex w-full items-start">
            {ORDER_TIMELINE.map((step, idx) => {
              const isDone = idx <= activeStepIndex && order.Status !== ORDER_STATUS.REJECTED;
              return (
                <div key={step.status} className="flex flex-1 items-start">
                  <div className="flex w-full flex-col items-center text-center">
                    <div
                      className={`flex h-8 w-8 items-center justify-center rounded-full border text-xs font-semibold ${
                        isDone
                          ? "border-emerald-400/60 bg-emerald-500 text-slate-950"
                          : "border-white/20 bg-slate-900 text-slate-400"
                      }`}
                    >
                      {idx + 1}
                    </div>
                    <div className={`mt-2 text-[11px] ${isDone ? "text-emerald-200" : "text-slate-400"}`}>
                      {step.label}
                    </div>
                  </div>
                  {idx < ORDER_TIMELINE.length - 1 ? (
                    <div className="mt-4 h-0.5 flex-1 px-1 sm:px-2">
                      <div className={`h-0.5 w-full ${idx < activeStepIndex ? "bg-emerald-500/80" : "bg-white/15"}`} />
                    </div>
                  ) : null}
                </div>
              );
            })}
          </div>
        </div>

        {(order.TrackingNo || order.CargoCompany) ? (
          <div className="mt-3 flex flex-wrap gap-2 text-xs">
            <span className="rounded-md border border-white/10 bg-white/5 px-2 py-1 text-slate-200">
              Tracking no: {order.TrackingNo || "-"}
            </span>
            <span className="rounded-md border border-white/10 bg-white/5 px-2 py-1 text-slate-200">
              Cargo: {order.CargoCompany || "-"}
            </span>
          </div>
        ) : null}
        {shippingInfoText ? (
          <div className="mt-3 rounded-md border border-cyan-400/30 bg-cyan-500/10 px-3 py-2 text-xs text-cyan-100">
            {shippingInfoText}
          </div>
        ) : null}

        {(order.Status === ORDER_STATUS.PLACED || order.Status === ORDER_STATUS.PREPARING || showRejectPanel || showShippingPanel) ? (
          <>
            <div className="mt-4 text-sm font-semibold text-slate-100">Admin Actions</div>
            {order.Status === ORDER_STATUS.PLACED ? (
              <div className="mt-3 flex flex-wrap gap-2">
                <button
                  onClick={() => {
                    void updateStatus({ status: ORDER_STATUS.PREPARING, note: "Approved by admin." });
                    setShowShippingPanel(true);
                    setShowRejectPanel(false);
                  }}
                  className="rounded bg-emerald-500 px-3 py-1.5 text-xs font-semibold text-emerald-950"
                >
                  Approve
                </button>
                <button
                  onClick={() => {
                    setShowRejectPanel(true);
                    setShowShippingPanel(false);
                  }}
                  className="rounded bg-rose-500 px-3 py-1.5 text-xs font-semibold text-rose-950"
                >
                  Reject
                </button>
              </div>
            ) : null}
          </>
        ) : null}

        {showShippingPanel && order.Status === ORDER_STATUS.PREPARING ? (
          <div className="mt-4 grid gap-2 md:grid-cols-3">
            <select value={cargoCompany} onChange={(e) => setCargoCompany(e.target.value)} className="rounded border border-slate-700 bg-slate-950 px-3 py-2 text-sm">
              {CARGO_OPTIONS.map((c) => (
                <option key={c} value={c}>{c}</option>
              ))}
            </select>
            <input value={trackingNo} onChange={(e) => setTrackingNo(e.target.value)} placeholder="Tracking no" className="rounded border border-slate-700 bg-slate-950 px-3 py-2 text-sm" />
            <button
              onClick={async () => {
                await updateStatus({
                  status: ORDER_STATUS.SHIPPED,
                  cargoCompany,
                  trackingNo,
                  note: `Kargo: ${cargoCompany} | Tracking: ${trackingNo}`,
                });
                setShowShippingPanel(false);
              }}
              className="rounded bg-cyan-500 px-3 py-2 text-xs font-semibold text-cyan-950"
            >
              Ship with selected cargo
            </button>
          </div>
        ) : null}

        {showRejectPanel ? (
          <div className="mt-4 grid gap-2 md:grid-cols-3">
            <select
              value={rejectCode}
              onChange={(e) => setRejectCode(e.target.value)}
              className="rounded border border-slate-700 bg-slate-950 px-3 py-2 text-sm"
            >
              {REJECT_OPTIONS.map((option) => (
                <option key={option.code} value={option.code}>
                  {option.label}
                </option>
              ))}
            </select>
            <input
              value={rejectNote}
              onChange={(e) => setRejectNote(e.target.value)}
              placeholder="Açıklama (opsiyonel)"
              className="rounded border border-slate-700 bg-slate-950 px-3 py-2 text-sm"
            />
            <button
              onClick={() =>
                void updateStatus({
                  status: ORDER_STATUS.REJECTED,
                  rejectReasonCode: rejectCode,
                  rejectReasonNote: rejectNote || null,
                  note: `Rejected: ${rejectCode}${rejectNote ? ` - ${rejectNote}` : ""}`,
                })
              }
              className="rounded bg-rose-500 px-3 py-2 text-xs font-semibold text-rose-950"
            >
              Confirm Reject
            </button>
          </div>
        ) : null}
      </section>

      <section className="rounded-xl border border-slate-800 bg-slate-900/70 p-4">
        <div className="text-sm font-semibold text-slate-100">Order Lines</div>
        <div className="mt-3 grid gap-2 md:grid-cols-2">
          {lines.map((l, idx) => (
            <div key={`${l.ItemId}-${idx}`} className="rounded border border-slate-800 bg-slate-950/50 p-3 text-sm">
              <div className="flex gap-3">
                <div className="h-16 w-16 shrink-0 overflow-hidden rounded border border-slate-700">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={itemPrimaryImageSrc({
                      id: l.ItemId,
                      name: l.ItemName || `Item #${l.ItemId}`,
                      brand: l.Brand,
                      imageUrl: l.ImageUrl,
                    })}
                    alt={l.ItemName || `Item #${l.ItemId}`}
                    className="h-full w-full object-cover"
                  />
                </div>
                <div className="min-w-0">
                  <div className="font-medium text-slate-100">{l.ItemName || `Item #${l.ItemId}`}</div>
                  <div className="text-xs text-slate-400">{l.Brand || "-"}</div>
                  <div className="mt-1 text-xs text-slate-300">
                    Qty: {l.Qty} · Unit: {formatTry(l.UnitPrice)} · Amount: {formatTry(l.LineTotal)}
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </section>

      <section className="grid gap-3 md:grid-cols-3">
        <div className="rounded-xl border border-slate-800 bg-slate-900/70 p-4">
          <div className="text-sm font-semibold text-slate-100">Delivery Address</div>
          <div className="mt-2 text-sm text-slate-300">{order.NameSurname || order.Username}</div>
          <div className="mt-1 text-sm text-slate-300">{order.AddressText || "-"}</div>
          <div className="mt-1 text-sm text-slate-300">{[order.City, order.Town].filter(Boolean).join(" / ") || "-"}</div>
        </div>
        <div className="rounded-xl border border-slate-800 bg-slate-900/70 p-4">
          <div className="text-sm font-semibold text-slate-100">Invoice Address</div>
          <div className="mt-2 text-sm text-slate-300">{order.NameSurname || order.Username}</div>
          <div className="mt-1 text-sm text-slate-300">{order.AddressText || "-"}</div>
          <div className="mt-1 text-sm text-slate-300">{[order.City, order.Town].filter(Boolean).join(" / ") || "-"}</div>
        </div>
        <div className="rounded-xl border border-slate-800 bg-slate-900/70 p-4">
          <div className="text-sm font-semibold text-slate-100">Payment Info</div>
          <div className="mt-2 space-y-1 text-sm text-slate-300">
            <div className="flex justify-between"><span>Subtotal</span><span>{formatTry(subtotal)}</span></div>
            <div className="flex justify-between"><span>Shipping</span><span>{formatTry(shipping)}</span></div>
            <div className="flex justify-between border-t border-slate-700 pt-1 font-semibold text-slate-100"><span>Total</span><span>{formatTry(order.TotalPrice)}</span></div>
          </div>
        </div>
      </section>
    </main>
  );
}

