import Link from "next/link";

import { requireAuth } from "@/lib/requireAuth";
import { listOrdersForUserUi } from "@/lib/repos/ordersHistory";
import { getItemsByIds } from "@/lib/repos/items";
import { Card, CardBody } from "@/components/ui/Card";
import { formatTry } from "@/lib/format";
import { Badge } from "@/components/ui/Badge";
import { ButtonLink } from "@/components/ui/Button";
import { itemPrimaryImageSrc } from "@/lib/itemImage";
import { ORDER_STATUS, orderStatusLabel } from "@/lib/orderStatus";

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

function statusPill(s: number) {
  const label = statusLabel(s);
  if (s === ORDER_STATUS.COMPLETED) return <Badge className="border-emerald-400/25 bg-emerald-400/10 text-emerald-100/90">{label}</Badge>;
  if (s === ORDER_STATUS.REJECTED) return <Badge className="border-rose-400/25 bg-rose-400/10 text-rose-100/90">{label}</Badge>;
  return <Badge className="border-sky-400/25 bg-sky-400/10 text-sky-100/90">{label}</Badge>;
}

function stageText(s: number) {
  if (s === ORDER_STATUS.PLACED) return "Stage: Waiting for admin approval.";
  if (s === ORDER_STATUS.PREPARING) return "Stage: Approved, your order is being prepared.";
  if (s === ORDER_STATUS.SHIPPED) return "Stage: Handed to cargo.";
  if (s === ORDER_STATUS.DELIVERED) return "Stage: Delivered by cargo, waiting for your confirmation.";
  if (s === ORDER_STATUS.COMPLETED) return "Stage: Delivery confirmed, order completed.";
  if (s === ORDER_STATUS.REJECTED) return "Stage: Rejected by admin.";
  return "Stage: Unknown.";
}

function parseItemIds(itemIds: string | null | undefined) {
  if (!itemIds) return [];
  const ids = itemIds
    .split(",")
    .map((x) => Number(x))
    .filter((n) => Number.isFinite(n) && n > 0);
  const uniq: number[] = [];
  for (const id of ids) {
    if (!uniq.includes(id)) uniq.push(id);
    if (uniq.length >= 3) break;
  }
  return uniq;
}

export default async function OrdersPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; status?: string }>;
}) {
  const user = await requireAuth();
  const sp = await searchParams;
  const q = sp.q?.toString() || "";
  const status = sp.status?.toString() || "all";
  const orders: Awaited<ReturnType<typeof listOrdersForUserUi>> = await listOrdersForUserUi(user.id, { q, status });

  const thumbIds = Array.from(
    new Set(
      orders
        .flatMap((o) => parseItemIds(o.ItemIds))
        .filter((n) => Number.isFinite(n) && n > 0)
    )
  ).slice(0, 200);
  const thumbItems = thumbIds.length ? await getItemsByIds(thumbIds) : [];
  const thumbImageById = new Map(thumbItems.map((it) => [Number(it.ID), it.IMAGE_URL]));

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-3">
        <h1 className="text-2xl font-extrabold">My Orders</h1>
        <Link className="text-sm text-slate-400 hover:text-slate-200" href="/account">
          ← Back to account
        </Link>
      </div>

      <Card>
        <CardBody>
          <div className="grid gap-3 lg:grid-cols-3">
            <div className="lg:col-span-2">
              <div className="text-sm text-slate-300">Search by product or brand</div>
              <form className="mt-2 flex gap-2" action="/account/orders" method="get">
                <input
                  name="q"
                  defaultValue={q}
                  placeholder="e.g. KODAK, TOY..."
                  className="w-full rounded-xl border border-white/10 bg-slate-950/30 px-3 py-2 text-sm outline-none focus:border-white/20"
                />
                <input type="hidden" name="status" value={status} />
                <button className="rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-sm hover:bg-white/10">
                  Search
                </button>
              </form>
            </div>

            <div>
              <div className="text-sm text-slate-300">Filter</div>
              <div className="mt-2 flex flex-wrap gap-2">
                <ButtonLink href={`/account/orders?${new URLSearchParams({ ...(q ? { q } : {}), status: "all" }).toString()}`} variant="soft" className={status === "all" ? "border-sky-400/30 bg-sky-400/10" : ""}>
                  All
                </ButtonLink>
                <ButtonLink href={`/account/orders?${new URLSearchParams({ ...(q ? { q } : {}), status: "ongoing" }).toString()}`} variant="soft" className={status === "ongoing" ? "border-sky-400/30 bg-sky-400/10" : ""}>
                  Ongoing
                </ButtonLink>
                <ButtonLink href={`/account/orders?${new URLSearchParams({ ...(q ? { q } : {}), status: "cancelled" }).toString()}`} variant="soft" className={status === "cancelled" ? "border-sky-400/30 bg-sky-400/10" : ""}>
                  Cancelled
                </ButtonLink>
                <ButtonLink href={`/account/orders?${new URLSearchParams({ ...(q ? { q } : {}), status: "completed" }).toString()}`} variant="soft" className={status === "completed" ? "border-sky-400/30 bg-sky-400/10" : ""}>
                  Delivered
                </ButtonLink>
              </div>
            </div>
          </div>
        </CardBody>
      </Card>

      {!orders.length ? (
        <Card>
          <CardBody>
            <div className="text-slate-300">You don’t have any orders yet.</div>
            <Link className="mt-3 inline-block text-sky-200 hover:underline" href="/items">
              Start shopping
            </Link>
          </CardBody>
        </Card>
      ) : (
        <div className="space-y-3">
          {orders.map((o) => {
            const imgs = parseItemIds(o.ItemIds);
            const distinct = o.DistinctItems ?? 0;

            return (
              <Card key={o.ID}>
                <CardBody>
                  <div className="grid gap-3 rounded-xl border border-white/10 bg-white/[0.04] p-3 md:grid-cols-[1.1fr_1.1fr_1fr_0.9fr_auto] md:items-center">
                    <div>
                      <div className="text-xs font-semibold text-slate-300">Order Date</div>
                      <div className="mt-1 text-sm text-slate-100">{formatDate(o.Date)}</div>
                    </div>
                    <div>
                      <div className="text-xs font-semibold text-slate-300">Order Summary</div>
                      <div className="mt-1 text-sm text-slate-100">1 delivery, {distinct || "-"} items</div>
                    </div>
                    <div>
                      <div className="text-xs font-semibold text-slate-300">Buyer</div>
                      <div className="mt-1 text-sm text-slate-100">{user.nameSurname || user.username}</div>
                    </div>
                    <div>
                      <div className="text-xs font-semibold text-slate-300">Total</div>
                      <div className="mt-1 text-base font-bold text-orange-300">{formatTry(o.TotalPrice)}</div>
                    </div>
                    <Link
                      href={`/account/orders/${o.ID}`}
                      prefetch={false}
                      className="inline-flex items-center justify-center rounded-xl border border-orange-500/80 bg-orange-500 px-3 py-2 text-sm font-medium text-white transition hover:bg-orange-500/90"
                    >
                      Details
                    </Link>
                  </div>

                  <div className="mt-3 rounded-xl border border-white/10 bg-white/[0.02] p-4">
                    <div className="grid gap-3 md:grid-cols-[1fr_auto_1fr] md:items-center">
                      <div>
                        <div className="flex items-center gap-2">
                          {statusPill(o.Status)}
                          <span className="text-sm text-slate-200">{statusLabel(o.Status)}</span>
                        </div>
                        <p className="mt-1 text-sm text-slate-300">
                          {stageText(o.Status)}
                        </p>
                      </div>

                      <div className="flex flex-wrap items-center justify-center gap-2">
                        {imgs.map((id) => (
                          // eslint-disable-next-line @next/next/no-img-element
                          <img
                            key={id}
                            alt={`Item ${id}`}
                            src={itemPrimaryImageSrc({
                              id,
                              name: `Item ${id}`,
                              brand: "",
                              imageUrl: thumbImageById.get(id) ?? null,
                            })}
                            className="h-16 w-16 rounded-md border border-white/10 object-cover"
                          />
                        ))}
                      </div>

                      <div className="hidden md:block" />
                    </div>

                    <div className="mt-3 flex flex-wrap items-center justify-between gap-2">
                      {o.Status === ORDER_STATUS.REJECTED ? (
                        <p className="text-xs text-rose-200">
                          Rejection reason: {o.RejectReasonCode || "OTHER"} {o.RejectReasonNote ? `- ${o.RejectReasonNote}` : ""}
                        </p>
                      ) : (
                        <span className="text-xs text-slate-400">Order #{o.ID}</span>
                      )}

                      {o.Status === ORDER_STATUS.COMPLETED ? (
                        <ButtonLink href="/account/reviews" variant="primary" className="ml-auto">
                          Review
                        </ButtonLink>
                      ) : null}
                    </div>

                    {(o.Status === ORDER_STATUS.SHIPPED || o.Status === ORDER_STATUS.DELIVERED || o.Status === ORDER_STATUS.COMPLETED) && (o.CargoCompany || o.TrackingNo) ? (
                      <p className="mt-2 text-xs text-emerald-200">
                        Cargo: {o.CargoCompany || "-"} / Tracking: {o.TrackingNo || "-"}
                      </p>
                    ) : null}
                  </div>
                </CardBody>
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}

