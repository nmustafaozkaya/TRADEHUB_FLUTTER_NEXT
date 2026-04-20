import Link from "next/link";
import { notFound } from "next/navigation";

import { requireAuth } from "@/lib/requireAuth";
import { shippingFee } from "@/lib/shipping";
import { formatTry } from "@/lib/format";
import { getOrderForUser, listOrderLinesForUser } from "@/lib/repos/ordersHistory";
import { getItemsByIds } from "@/lib/repos/items";
import { Card, CardBody } from "@/components/ui/Card";
import { Badge } from "@/components/ui/Badge";
import { ButtonLink } from "@/components/ui/Button";
import { itemPrimaryImageSrc } from "@/lib/itemImage";
import { orderStatusLabel } from "@/lib/orderStatus";

export const runtime = "nodejs";

function formatDate(d: Date | null) {
  if (!d) return "-";
  try {
    return new Intl.DateTimeFormat("en-US", { dateStyle: "medium", timeStyle: "short" }).format(d);
  } catch {
    return d.toISOString();
  }
}

function statusLabel(s: number) {
  return orderStatusLabel(s);
}

export default async function ThanksPage({
  searchParams,
}: {
  searchParams: Promise<{ orderId?: string }>;
}) {
  const sp = await searchParams;
  const orderId = Number(sp.orderId || 0) || null;

  const user = await requireAuth("/checkout/thanks");
  if (!orderId) return notFound();

  const order = await getOrderForUser(user.id, orderId);
  if (!order) return notFound();

  const lines = await listOrderLinesForUser(user.id, orderId);
  const lineItemIds = Array.from(new Set(lines.map((l) => Number(l.ItemId)).filter((n) => Number.isFinite(n) && n > 0)));
  const lineItems = lineItemIds.length ? await getItemsByIds(lineItemIds) : [];
  const lineImageById = new Map(lineItems.map((it) => [Number(it.ID), it.IMAGE_URL]));

  const subtotal = lines.reduce((sum, l) => sum + Number(l.LineTotal ?? 0), 0);
  const ship = shippingFee(subtotal);
  const total = subtotal + ship;

  const statusText = statusLabel(order.Status);

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-extrabold">Order received</h1>
          <p className="mt-1 text-sm text-slate-400">
            Order number: <b className="text-slate-100">{orderId ?? "-"}</b>
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Badge className="border-sky-400/25 bg-sky-400/10 text-sky-100/90">{statusText}</Badge>
          <ButtonLink href={`/account/orders/${order.ID}`} variant="soft">
            View in My Orders
          </ButtonLink>
        </div>
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <div className="lg:col-span-2 space-y-4">
          <Card>
            <CardBody>
              <h2 className="text-lg font-extrabold">Purchased items</h2>
              <p className="mt-1 text-sm text-slate-400">
                {lines.length} item{lines.length === 1 ? "" : "s"} in your order.
              </p>

              {!lines.length ? (
                <div className="mt-4 text-sm text-slate-300">No order lines found for this order.</div>
              ) : (
                <div className="mt-4 overflow-hidden rounded-2xl border border-white/10">
                  <table className="w-full text-left text-sm">
                    <thead className="bg-white/5 text-slate-300">
                      <tr>
                        <th className="p-3">Product</th>
                        <th className="p-3">Qty</th>
                        <th className="p-3">Price</th>
                        <th className="p-3 text-right">Amount</th>
                      </tr>
                    </thead>
                    <tbody>
                      {lines.map((l) => (
                        <tr key={`${l.ItemId}-${l.Qty}`} className="border-t border-white/10">
                          <td className="p-3">
                            <div className="flex items-center gap-3">
                              <div className="shrink-0 overflow-hidden rounded-xl border border-white/10">
                                {/* eslint-disable-next-line @next/next/no-img-element */}
                                <img
                                  alt={l.ItemName ?? `Item ${l.ItemId}`}
                                  src={itemPrimaryImageSrc({
                                    id: Number(l.ItemId),
                                    name: l.ItemName ?? `Item ${l.ItemId}`,
                                    brand: l.Brand,
                                    imageUrl: lineImageById.get(Number(l.ItemId)) ?? null,
                                  })}
                                  className="h-14 w-14 object-cover"
                                  loading="lazy"
                                />
                              </div>
                              <div className="min-w-0">
                                <div className="font-semibold text-slate-100 line-clamp-1">{l.ItemName || `Item #${l.ItemId}`}</div>
                                <div className="mt-1 text-xs text-slate-400">{l.Brand || "-"}</div>
                              </div>
                            </div>
                          </td>
                          <td className="p-3 text-slate-200">{l.Qty}</td>
                          <td className="p-3 text-slate-200">{formatTry(l.UnitPrice)}</td>
                          <td className="p-3 text-right font-extrabold text-slate-100">{formatTry(l.LineTotal)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </CardBody>
          </Card>
        </div>

        <aside className="space-y-4 lg:self-start">
          <Card className="sticky top-24">
            <CardBody>
              <h2 className="text-lg font-extrabold">Order summary</h2>
              <div className="mt-3 space-y-2 text-sm text-slate-300">
                <div className="flex items-center justify-between gap-2">
                  <span>Subtotal</span>
                  <span className="text-slate-200">{formatTry(subtotal)}</span>
                </div>
                <div className="flex items-center justify-between gap-2">
                  <span>Shipping</span>
                  <span className="text-slate-200">{formatTry(ship)}</span>
                </div>
                <div className="flex items-center justify-between gap-2 pt-2 text-slate-200">
                  <span className="font-semibold">Total</span>
                  <span className="text-lg font-extrabold">{formatTry(total)}</span>
                </div>
              </div>

              <div className="mt-4 rounded-2xl border border-white/10 bg-white/5 p-4">
                <div className="text-sm font-bold text-slate-100">Payment</div>
                <div className="mt-1 text-xs text-slate-400">
                  Card payment is a UI preview in this MVP; placing an order saves it to the database.
                </div>
              </div>

              <div className="mt-4 rounded-2xl border border-white/10 bg-white/5 p-4">
                <div className="text-sm font-bold text-slate-100">Delivery</div>
                <div className="mt-1 text-xs text-slate-400">
                  {order.AddressText || "-"}
                  <br />
                  {[order.City, order.Town].filter(Boolean).join(" / ") || "-"}
                </div>
              </div>

              <div className="mt-4 text-xs text-slate-400">
                Placed on {formatDate(order.Date)}.
              </div>
            </CardBody>
          </Card>

          <Link
            className="inline-flex w-full items-center justify-center rounded-xl border border-white/10 bg-sky-400/20 px-3 py-2 text-sm font-semibold text-sky-200 hover:bg-sky-400/25"
            href="/items"
          >
            Continue shopping
          </Link>
        </aside>
      </div>
    </div>
  );
}

