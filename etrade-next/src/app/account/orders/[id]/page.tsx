import Link from "next/link";
import { notFound } from "next/navigation";

import { requireAuth } from "@/lib/requireAuth";
import { getOrderForUser, listOrderLinesForUser } from "@/lib/repos/ordersHistory";
import { getItemsByIds } from "@/lib/repos/items";
import { itemPrimaryImageSrc } from "@/lib/itemImage";
import { Card, CardBody } from "@/components/ui/Card";
import { formatTry } from "@/lib/format";
import { Badge } from "@/components/ui/Badge";
import { ButtonLink } from "@/components/ui/Button";
import { ORDER_STATUS, orderStatusLabel } from "@/lib/orderStatus";
import { ConfirmDeliveryButton } from "@/components/ConfirmDeliveryButton";
import { shippingFee } from "@/lib/shipping";

export const runtime = "nodejs";

function formatDate(d: Date | null) {
  if (!d) return "-";
  try {
    return new Intl.DateTimeFormat("en-US", { dateStyle: "medium", timeStyle: "short" }).format(d);
  } catch {
    return d.toISOString();
  }
}

type TimelineStep = {
  key: "placed" | "preparing" | "shipped" | "delivered" | "completed";
  label: string;
};

const ORDER_TIMELINE_STEPS: TimelineStep[] = [
  { key: "placed", label: "Order placed" },
  { key: "preparing", label: "Preparing" },
  { key: "shipped", label: "Shipped" },
  { key: "delivered", label: "Delivered" },
  { key: "completed", label: "Completed" },
];

function getActiveTimelineStep(status: number) {
  if (status === ORDER_STATUS.PLACED) return 0;
  if (status === ORDER_STATUS.PREPARING) return 1;
  if (status === ORDER_STATUS.SHIPPED) return 2;
  if (status === ORDER_STATUS.DELIVERED) return 3;
  if (status === ORDER_STATUS.COMPLETED) return 4;
  return 0;
}

function statusDetailText(status: number) {
  if (status === ORDER_STATUS.COMPLETED) return "Your order has been completed.";
  if (status === ORDER_STATUS.DELIVERED) return "Delivered by cargo, waiting your confirmation.";
  if (status === ORDER_STATUS.SHIPPED) return "Your package is on the way.";
  if (status === ORDER_STATUS.PREPARING) return "Your order is being prepared.";
  if (status === ORDER_STATUS.PLACED) return "Order placed, waiting admin approval.";
  if (status === ORDER_STATUS.REJECTED) return "Order rejected by admin.";
  return "Order is in process.";
}

function StepIcon({ stepKey }: { stepKey: TimelineStep["key"] }) {
  const cls = "h-3.5 w-3.5";

  if (stepKey === "placed") {
    return (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={cls} aria-hidden>
        <path d="M3 8.5L12 4l9 4.5-9 4.5L3 8.5Z" />
        <path d="M3 8.5V16l9 4 9-4V8.5" />
      </svg>
    );
  }

  if (stepKey === "preparing") {
    return (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={cls} aria-hidden>
        <path d="M4 12h16" />
        <path d="M12 4v16" />
      </svg>
    );
  }

  if (stepKey === "shipped") {
    return (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={cls} aria-hidden>
        <path d="M2 7h12v8H2z" />
        <path d="M14 10h4l3 3v2h-7z" />
        <circle cx="7" cy="17" r="1.6" />
        <circle cx="18" cy="17" r="1.6" />
      </svg>
    );
  }

  if (stepKey === "delivered") {
    return (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={cls} aria-hidden>
        <path d="m5 12 4 4 10-10" />
      </svg>
    );
  }

  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={cls} aria-hidden>
      <path d="m5 12 4 4 10-10" />
      <path d="M4 4h16v16H4z" />
    </svg>
  );
}

export default async function OrderDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const user = await requireAuth();
  const p = await params;
  const id = Number(p.id);

  const order = await getOrderForUser(user.id, id);
  if (!order) return notFound();

  const lines = await listOrderLinesForUser(user.id, id);
  const itemIds = Array.from(new Set(lines.map((l) => Number(l.ItemId)).filter((x) => Number.isFinite(x) && x > 0)));
  const items = itemIds.length ? await getItemsByIds(itemIds) : [];
  const imageById = new Map(items.map((it) => [Number(it.ID), it.IMAGE_URL]));

  const activeStepIndex = getActiveTimelineStep(order.Status);
  const subtotal = lines.reduce((sum, l) => sum + Number(l.LineTotal || 0), 0);
  const ship = shippingFee(subtotal);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-3">
        <h1 className="text-2xl font-extrabold">Order Details</h1>
        <Link className="text-sm text-slate-400 hover:text-slate-200" href="/account/orders">
          ← All Orders
        </Link>
      </div>

      <Card>
        <CardBody>
          <div className="grid gap-3 rounded-xl border border-white/10 bg-white/[0.04] p-3 md:grid-cols-5 md:items-center">
            <div>
              <div className="text-xs text-slate-400">Order No</div>
              <div className="mt-1 text-sm font-semibold text-slate-100">#{order.ID}</div>
            </div>
            <div>
              <div className="text-xs text-slate-400">Order Date</div>
              <div className="mt-1 text-sm font-semibold text-slate-100">{formatDate(order.Date)}</div>
            </div>
            <div>
              <div className="text-xs text-slate-400">Order Summary</div>
              <div className="mt-1 text-sm font-semibold text-slate-100">1 package, {lines.length} items</div>
            </div>
            <div>
              <div className="text-xs text-slate-400">Order Status</div>
              <div className="mt-1 text-sm font-semibold text-emerald-300">{statusDetailText(order.Status)}</div>
            </div>
            <div className="text-right">
              <button
                type="button"
                className="inline-flex items-center justify-center rounded-xl border border-orange-400/50 bg-transparent px-3 py-2 text-sm font-medium text-orange-300 transition hover:bg-orange-500/10"
              >
                Invoice
              </button>
            </div>
          </div>
        </CardBody>
      </Card>

      <Card>
        <CardBody>
          <div className="rounded-xl border border-white/10 bg-white/[0.03] p-4">
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div className="w-full">
                <Badge className="border-sky-400/25 bg-sky-400/10 text-sky-100/90">
                  {orderStatusLabel(order.Status)}
                </Badge>
                <p className="mt-2 text-sm text-slate-200">{statusDetailText(order.Status)}</p>
                <div className="mt-3">
                  <div className="mb-2 text-[11px] uppercase tracking-wide text-slate-400">Order progress</div>
                  <div className="flex w-full items-start justify-between">
                    {ORDER_TIMELINE_STEPS.map((step, idx) => {
                      const isDone = idx <= activeStepIndex && order.Status !== ORDER_STATUS.REJECTED;
                      const isCurrent = idx === activeStepIndex && order.Status !== ORDER_STATUS.REJECTED;
                      return (
                        <div key={step.key} className="flex flex-1 items-start">
                          <div className="flex w-full flex-col items-center text-center">
                            <div
                              className={`flex h-8 w-8 items-center justify-center rounded-full border text-xs font-semibold ${
                                isDone
                                  ? "border-emerald-400/60 bg-emerald-500 text-slate-950"
                                  : "border-white/20 bg-slate-900 text-slate-400"
                              } ${isCurrent ? "ring-2 ring-emerald-300/40" : ""}`}
                            >
                              {isDone ? (
                                <svg
                                  viewBox="0 0 24 24"
                                  fill="none"
                                  stroke="currentColor"
                                  strokeWidth="2.4"
                                  className="h-4 w-4"
                                  aria-hidden
                                >
                                  <path d="m5 12 4 4 10-10" />
                                </svg>
                              ) : (
                                idx + 1
                              )}
                            </div>
                            <div className={`mt-2 flex items-center gap-1 text-[11px] ${isDone ? "text-emerald-200" : "text-slate-400"}`}>
                              <StepIcon stepKey={step.key} />
                              <span>{step.label}</span>
                            </div>
                          </div>
                          {idx < ORDER_TIMELINE_STEPS.length - 1 ? (
                            <div className="mt-4 h-0.5 flex-1 px-1 sm:px-2">
                              <div className={`h-0.5 w-full ${idx < activeStepIndex ? "bg-emerald-500/80" : "bg-white/15"}`} />
                            </div>
                          ) : null}
                        </div>
                      );
                    })}
                  </div>
                </div>
                {(order.CargoCompany || order.TrackingNo) ? (
                  <div className="mt-3 flex flex-wrap gap-2 text-xs">
                    <span className="rounded-md border border-white/10 bg-white/5 px-2 py-1 text-slate-200">
                      Tracking no: {order.TrackingNo || "-"}
                    </span>
                    <span className="rounded-md border border-white/10 bg-white/5 px-2 py-1 text-slate-200">
                      Cargo: {order.CargoCompany || "-"}
                    </span>
                  </div>
                ) : null}
              </div>
              {(order.Status === ORDER_STATUS.DELIVERED || order.Status === ORDER_STATUS.SHIPPED) ? (
                <div className="w-full sm:w-auto">
                  <ConfirmDeliveryButton orderId={order.ID} />
                </div>
              ) : null}
            </div>

            {order.Status === ORDER_STATUS.REJECTED ? (
              <div className="mt-3 rounded-lg border border-rose-500/30 bg-rose-500/10 px-3 py-2 text-xs text-rose-200">
                Rejection reason: {order.RejectReasonCode || "OTHER"} {order.RejectReasonNote ? `- ${order.RejectReasonNote}` : ""}
              </div>
            ) : null}
          </div>

          <div className="mt-4 grid grid-cols-1 gap-3">
            {lines.map((l, idx) => (
              <article key={`${l.ItemId}-${idx}`} className="rounded-xl border border-white/10 bg-white/[0.03] p-3">
                <div className="flex gap-3">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    alt={l.ItemName || `Item ${l.ItemId}`}
                    src={itemPrimaryImageSrc({
                      id: Number(l.ItemId),
                      name: l.ItemName || `Item ${l.ItemId}`,
                      brand: l.Brand || "",
                      imageUrl: imageById.get(Number(l.ItemId)) ?? null,
                    })}
                    className="h-20 w-20 rounded-md border border-white/10 object-cover"
                  />
                  <div className="min-w-0 flex-1">
                    <div className="text-sm font-semibold text-slate-100 line-clamp-2">{l.ItemName || `Item #${l.ItemId}`}</div>
                    <div className="mt-1 text-xs text-slate-400">{l.Brand || "-"}</div>
                    <div className="mt-2 text-sm text-orange-300">{formatTry(l.LineTotal)}</div>
                    <div className="mt-1 text-xs text-slate-400">Qty: {l.Qty}</div>
                  </div>
                </div>
                <div className="mt-3 grid grid-cols-2 gap-2">
                  <ButtonLink href="/account/reviews" variant="primary" className="justify-center bg-orange-500 hover:bg-orange-500/90">
                    Review item
                  </ButtonLink>
                  <ButtonLink href="/items" variant="soft" className="justify-center border-orange-400/50 text-orange-300">
                    Buy again
                  </ButtonLink>
                </div>
              </article>
            ))}
          </div>
        </CardBody>
      </Card>

      <div className="grid gap-3 lg:grid-cols-3">
        <Card>
          <CardBody>
            <div className="text-sm font-semibold text-slate-100">Delivery Address</div>
            <div className="mt-3 text-sm text-slate-200">{user.nameSurname || user.username}</div>
            <div className="mt-2 text-sm text-slate-300">{order.AddressText || "-"}</div>
            <div className="mt-2 text-sm text-slate-300">{[order.City, order.Town].filter(Boolean).join(" / ") || "-"}</div>
          </CardBody>
        </Card>

        <Card>
          <CardBody>
            <div className="text-sm font-semibold text-slate-100">Invoice Address</div>
            <div className="mt-3 text-sm text-slate-200">{user.nameSurname || user.username}</div>
            <div className="mt-2 text-sm text-slate-300">{order.AddressText || "-"}</div>
            <div className="mt-2 text-sm text-slate-300">{[order.City, order.Town].filter(Boolean).join(" / ") || "-"}</div>
          </CardBody>
        </Card>

        <Card>
          <CardBody>
            <div className="text-sm font-semibold text-slate-100">Payment Info</div>
            <div className="mt-3 space-y-2 text-sm text-slate-300">
              <div className="flex items-center justify-between">
                <span>Subtotal</span>
                <span>{formatTry(subtotal)}</span>
              </div>
              <div className="flex items-center justify-between">
                <span>Shipping</span>
                <span>{formatTry(ship)}</span>
              </div>
              <div className="flex items-center justify-between border-t border-white/10 pt-2 text-slate-100">
                <span className="font-semibold">Total</span>
                <span className="font-bold">{formatTry(order.TotalPrice)}</span>
              </div>
            </div>
          </CardBody>
        </Card>
      </div>
    </div>
  );
}
