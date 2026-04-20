import Link from "next/link";
import { notFound } from "next/navigation";

import { getItemById, getItemSalesStats, listBoughtTogether, listSimilarItems } from "@/lib/repos/items";
import { getCart } from "@/lib/cart";
import { formatTry, tryNumber } from "@/lib/format";
import { itemPrimaryImageSrc } from "@/lib/itemImage";
import { buildExtendedWarrantyPlan } from "@/lib/extendedWarranty";
import { FavoriteButton } from "@/components/FavoriteButton";
import { getFavorites } from "@/lib/favorites";
import { Card, CardBody } from "@/components/ui/Card";
import { QtyPickerAddToCart } from "@/components/QtyPickerAddToCart";
import { ItemProtectionPlans } from "@/components/ItemProtectionPlans";
import { ItemTile } from "@/components/ItemTile";
import { listBestSellers } from "@/lib/repos/dashboard";

export const runtime = "nodejs";

function dedupeById<T extends { ID: number }>(items: T[]) {
  const seen = new Set<number>();
  const out: T[] = [];
  for (const it of items) {
    const id = Number(it.ID);
    if (!id || seen.has(id)) continue;
    seen.add(id);
    out.push(it);
  }
  return out;
}

export default async function ItemDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const p = await params;
  const id = Number(p.id);

  const [item, favs, cart] = await Promise.all([getItemById(id), getFavorites(), getCart()]);
  if (!item) return notFound();
  const favSet = new Set(favs.ids);

  const name = item.ITEMNAME || `Item #${id}`;
  const unitPrice = tryNumber(item.UNITPRICE);
  const imgSrc = itemPrimaryImageSrc({
    id: item.ID,
    name,
    brand: item.BRAND,
    imageUrl: item.IMAGE_URL,
  });

  const categories = [item.CATEGORY1, item.CATEGORY2, item.CATEGORY3, item.CATEGORY4].filter(Boolean).join(" / ");

  const [boughtTogetherRaw, similarRaw, bestSellersRaw, stats] = await Promise.all([
    listBoughtTogether(item.ID, 10),
    listSimilarItems({
      excludeId: item.ID,
      brand: item.BRAND,
      category1: item.CATEGORY1,
      limit: 10,
    }),
    listBestSellers(14),
    getItemSalesStats(item.ID),
  ]);

  const boughtTogether = dedupeById(boughtTogetherRaw).filter((x) => x.ID !== item.ID).slice(0, 10);
  const similar = dedupeById(similarRaw).filter((x) => x.ID !== item.ID).slice(0, 10);
  const bestSellers = dedupeById(bestSellersRaw)
    .filter((x) => x.ID !== item.ID)
    .slice(0, 10);

  const used = new Set<number>([item.ID, ...boughtTogether.map((x) => x.ID), ...similar.map((x) => x.ID)]);
  const recommended = bestSellers.filter((x) => !used.has(x.ID)).slice(0, 10);

  const protectionPlan = buildExtendedWarrantyPlan({
    unitPrice,
    category1: item.CATEGORY1,
    category2: item.CATEGORY2,
    category3: item.CATEGORY3,
    category4: item.CATEGORY4,
  });
  const selectedProtectionYears =
    cart.lines.find((l) => Number(l.itemId) === Number(item.ID))?.protection?.years ?? null;

  return (
    <div className="space-y-4">
      <Link href="/items" className="text-sm text-slate-400 hover:text-slate-200">
        ← Back to items
      </Link>

      <div className="grid gap-4 lg:grid-cols-3">
        <div className="space-y-4 lg:col-span-2">
          <Card>
            <CardBody>
              <div className="grid gap-4 lg:grid-cols-2">
                <div className="overflow-hidden rounded-2xl border border-white/10">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img alt={name} src={imgSrc} className="h-[320px] w-full object-cover" />
                </div>

                <div>
                  <div className="mb-2 flex flex-wrap items-center gap-2 text-xs">
                    {item.BRAND ? (
                      <span className="rounded-full border border-white/10 bg-white/5 px-2 py-1 text-slate-200">
                        Brand: <b className="text-slate-100">{item.BRAND}</b>
                      </span>
                    ) : null}
                    {stats.soldQty > 0 ? (
                      <span className="rounded-full border border-emerald-400/25 bg-emerald-400/10 px-2 py-1 text-emerald-100/90">
                        Sold <b>{stats.soldQty}</b>
                      </span>
                    ) : null}
                    {stats.orders > 0 ? (
                      <span className="rounded-full border border-sky-400/25 bg-sky-400/10 px-2 py-1 text-sky-100/90">
                        <b>{stats.orders}</b> orders
                      </span>
                    ) : null}
                  </div>
                  <h1 className="text-2xl font-extrabold tracking-tight">{name}</h1>

                  <div className="mt-2 space-y-1 text-sm text-slate-300">
                    <div>
                      <span className="text-slate-400">Code:</span> {item.ITEMCODE || "-"}
                    </div>
                    <div>
                      <span className="text-slate-400">Brand:</span> {item.BRAND || "-"}
                    </div>
                    <div>
                      <span className="text-slate-400">Category:</span> {categories || "-"}
                    </div>
                  </div>

                  <div className="mt-4 flex items-center justify-between gap-3">
                    <div className="text-2xl font-extrabold">{formatTry(unitPrice)}</div>
                    <FavoriteButton itemId={item.ID} active={favSet.has(item.ID)} />
                  </div>

                  <div className="mt-4">
                    <QtyPickerAddToCart itemId={item.ID} name={name} unitPrice={unitPrice} max={20} />
                  </div>
                </div>
              </div>
            </CardBody>
          </Card>

          <Card>
            <CardBody>
              <h2 className="text-lg font-extrabold">Product details</h2>
              <div className="mt-3 grid gap-3 sm:grid-cols-2">
                <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
                  <div className="text-xs text-slate-400">Specifications</div>
                  <ul className="mt-2 space-y-1 text-sm text-slate-300">
                    <li className="flex items-center justify-between gap-3">
                      <span className="text-slate-400">Code</span>
                      <span className="text-slate-200">{item.ITEMCODE || "-"}</span>
                    </li>
                    <li className="flex items-center justify-between gap-3">
                      <span className="text-slate-400">Brand</span>
                      <span className="text-slate-200">{item.BRAND || "-"}</span>
                    </li>
                    <li className="flex items-center justify-between gap-3">
                      <span className="text-slate-400">Category</span>
                      <span className="text-slate-200">{item.CATEGORY1 || "-"}</span>
                    </li>
                  </ul>
                </div>
              </div>
            </CardBody>
          </Card>

          {boughtTogether.length ? (
            <section className="space-y-2">
              <div className="flex items-end justify-between gap-3">
                <div>
                  <h2 className="text-lg font-extrabold">Frequently bought together</h2>
                  <p className="text-sm text-slate-400">Based on items that appear in the same orders.</p>
                </div>
              </div>

              <div className="-mx-4 flex gap-3 overflow-x-auto px-4 pb-2 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
                {boughtTogether.map((it) => (
                  <div key={it.ID} className="w-[240px] shrink-0">
                    <ItemTile item={it} favoriteActive={favSet.has(it.ID)} compact />
                  </div>
                ))}
              </div>
            </section>
          ) : null}

          {similar.length ? (
            <section className="space-y-2">
              <div>
                <h2 className="text-lg font-extrabold">Similar products</h2>
                <p className="text-sm text-slate-400">Same brand or category.</p>
              </div>

              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
                {similar.slice(0, 6).map((it) => (
                  <ItemTile key={it.ID} item={it} favoriteActive={favSet.has(it.ID)} showMeta />
                ))}
              </div>
            </section>
          ) : null}

          {recommended.length ? (
            <section className="space-y-2">
              <div>
                <h2 className="text-lg font-extrabold">Recommended for you</h2>
                <p className="text-sm text-slate-400">Popular items across the store.</p>
              </div>

              <div className="-mx-4 flex gap-3 overflow-x-auto px-4 pb-2 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
                {recommended.map((it) => (
                  <div key={it.ID} className="w-[240px] shrink-0">
                    <ItemTile item={it} favoriteActive={favSet.has(it.ID)} compact />
                  </div>
                ))}
              </div>
            </section>
          ) : null}
        </div>

        <aside className="space-y-4 lg:self-start">
          <div className="lg:sticky lg:top-24 lg:self-start">
            <Card>
              <CardBody>
                <div className="text-sm text-slate-400">Order summary</div>
                <div className="mt-1 text-2xl font-extrabold text-slate-100">{formatTry(unitPrice)}</div>
                <div className="mt-3 space-y-1 text-sm text-slate-300">
                  <div className="flex items-center justify-between gap-2">
                    <span className="text-slate-400">Item</span>
                    <span className="truncate text-right">{name}</span>
                  </div>
                  <div className="flex items-center justify-between gap-2">
                    <span className="text-slate-400">Brand</span>
                    <span className="truncate text-right">{item.BRAND || "-"}</span>
                  </div>
                </div>

                <div className="mt-4 flex items-center justify-between gap-2">
                  <FavoriteButton itemId={item.ID} active={favSet.has(item.ID)} />
                  <QtyPickerAddToCart itemId={item.ID} name={name} unitPrice={unitPrice} max={20} />
                </div>
              </CardBody>
            </Card>
          </div>

          <Card>
            <CardBody>
              <div className="flex items-center justify-between gap-2">
                <div>
                  <div className="text-sm font-bold text-slate-100">{protectionPlan.title}</div>
                  <div className="mt-1 text-xs text-slate-400">{protectionPlan.subtitle}</div>
                </div>
              </div>

              {!protectionPlan.offers.length ? (
                <div className="mt-3 text-sm text-slate-300">No add-on services available for this item.</div>
              ) : (
                <ItemProtectionPlans
                  itemId={item.ID}
                  itemName={name}
                  unitPrice={unitPrice}
                  offers={protectionPlan.offers}
                  selectedYears={selectedProtectionYears}
                />
              )}
            </CardBody>
          </Card>
        </aside>
      </div>
    </div>
  );
}

