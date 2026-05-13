import Link from "next/link";
import Image from "next/image";

import { listItems } from "@/lib/repos/items";
import { formatTry, tryNumber } from "@/lib/format";
import { AddToCartButton } from "@/components/AddToCartButton";
import { Card, CardBody } from "@/components/ui/Card";
import { ButtonLink } from "@/components/ui/Button";
import { listAllCategory1Counts, listBestSellers } from "@/lib/repos/dashboard";
import {
  SHOP_CATEGORIES,
  aggregateTopCategoriesToShop,
  displayCategoryFilter,
} from "@/lib/shopCategories";
import { listReviewSummariesByItemIds } from "@/lib/repos/reviews";
import { getFavorites } from "@/lib/favorites";
import { FavoriteButton } from "@/components/FavoriteButton";
import { itemPrimaryImageSrc } from "@/lib/itemImage";

export const runtime = "nodejs";

export default async function ItemsPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; category?: string; page?: string }>;
}) {
  const sp = await searchParams;
  const q = sp.q?.toString() || "";
  const category = sp.category?.toString() || "";
  const page = Math.max(1, Number(sp.page ?? "1"));

  const [result, rawCategoryCounts, bestSellers, favs] = await Promise.all([
    listItems({ q, category, page, pageSize: 20 }),
    listAllCategory1Counts(),
    listBestSellers(10),
    getFavorites(),
  ]);
  const shopCounts = aggregateTopCategoriesToShop(rawCategoryCounts);
  const favSet = new Set(favs.ids);
  const lastPage = Math.max(1, Math.ceil(result.total / result.pageSize));
  const reviewMap = await listReviewSummariesByItemIds([
    ...result.items.map((x) => Number(x.ID)),
    ...bestSellers.map((x) => Number(x.ID)),
  ]);

  const qs = (p: number) =>
    new URLSearchParams({
      ...(q ? { q } : {}),
      ...(category ? { category } : {}),
      page: String(p),
    }).toString();

  const showing = result.items.length;
  const hasSearchQuery = q.trim().length > 0;

  return (
    <div className="space-y-4">
      <section className="relative overflow-hidden rounded-2xl border border-indigo-400/20 bg-gradient-to-br from-slate-900/90 via-slate-900/70 to-indigo-950/40 p-5 shadow-[0_20px_50px_rgba(0,0,0,0.35)]">
        <div className="pointer-events-none absolute inset-0 opacity-[0.12]">
          <Image
            src="/TradeHub-horizontal.png"
            alt=""
            fill
            priority
            sizes="(max-width: 1200px) 100vw, 1200px"
            className="object-cover object-center blur-[1px]"
          />
        </div>
        <div className="pointer-events-none absolute -right-24 -top-24 h-72 w-72 rounded-full bg-indigo-500/25 blur-3xl" />
        <div className="pointer-events-none absolute -bottom-24 -left-24 h-72 w-72 rounded-full bg-sky-400/15 blur-3xl" />
        <div className="relative">
        <form action="/items" method="get" className="flex w-full flex-col gap-2">
          <input
            name="q"
            defaultValue={q}
            placeholder="Search by product, category, or brand"
            className="w-full rounded-2xl border border-white/10 bg-[color:var(--background)]/55 px-4 py-3 text-base text-[color:var(--foreground)] outline-none ring-0 transition focus:border-indigo-400/40 focus:ring-2 focus:ring-indigo-400/25"
          />
          <div className="flex flex-col gap-2 md:flex-row">
            <input type="hidden" name="category" value={category} />
            <button
              type="submit"
              className="rounded-xl bg-gradient-to-r from-indigo-500 to-indigo-600 px-4 py-2.5 text-sm font-semibold text-white shadow-lg shadow-indigo-900/30 transition hover:from-indigo-400 hover:to-indigo-500 md:w-32"
            >
              Search
            </button>
          </div>
        </form>
        </div>
      </section>

      {!hasSearchQuery ? (
        <>
          <section className="space-y-2">
            <div className="flex items-end justify-between gap-3">
              <div>
                <h2 className="text-lg font-extrabold">Categories</h2>
                <p className="text-sm text-slate-400">
                  Same groups as the mobile app. Counts include all active items in the database (0 is valid if nothing maps yet).
                </p>
              </div>
              {category ? (
                <ButtonLink href="/items" variant="soft">
                  Clear filter
                </ButtonLink>
              ) : null}
            </div>

            <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
              {SHOP_CATEGORIES.map((def) => {
                const cnt = shopCounts.get(def.label) ?? 0;
                const active = category === def.label;
                return (
                  <Link
                    key={def.label}
                    href={`/items?${new URLSearchParams({ ...(q ? { q } : {}), category: def.label }).toString()}`}
                    className={[
                      "group rounded-2xl border border-white/10 bg-slate-900/40 p-4 shadow-sm transition hover:-translate-y-0.5 hover:border-indigo-400/25 hover:shadow-indigo-900/20",
                      active
                        ? "border-indigo-400/40 bg-indigo-500/15 ring-2 ring-indigo-400/30"
                        : "",
                    ].join(" ")}
                  >
                    <div className="text-sm font-bold text-slate-100 group-hover:text-white">{def.label}</div>
                    <div className="mt-1 text-xs text-slate-400">
                      {cnt} {cnt === 1 ? "item" : "items"}
                    </div>
                  </Link>
                );
              })}
            </div>
          </section>

          <section className="space-y-2">
            <div>
              <h2 className="text-lg font-extrabold">Best Sellers</h2>
            </div>

            {bestSellers.length ? (
              <div className="-mx-4 flex gap-3 overflow-x-auto px-4 pb-2 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
                {bestSellers.map((it) => {
                  const name = it.ITEMNAME || "(Unnamed)";
                  const unitPrice = tryNumber(it.UNITPRICE);
                  const summary = reviewMap[Number(it.ID)] ?? { averageRating: 0, totalReviews: 0 };
                  const imgSrc = itemPrimaryImageSrc({
                    id: it.ID,
                    name,
                    brand: it.BRAND,
                    imageUrl: it.IMAGE_URL,
                  });
                  return (
                    <div
                      key={it.ID}
                      className="w-[260px] shrink-0 rounded-3xl border border-white/10 bg-slate-900/45 p-3 shadow-[0_12px_26px_rgba(15,23,42,0.35)] transition hover:-translate-y-0.5 hover:shadow-[0_18px_34px_rgba(15,23,42,0.45)]"
                    >
                      <Link href={`/items/${it.ID}`} className="relative block overflow-hidden rounded-2xl bg-slate-800/60">
                        {/* eslint-disable-next-line @next/next/no-img-element */}
                        <img alt={name} src={imgSrc} className="h-40 w-full object-cover" />
                      </Link>
                      <div className="mt-3">
                        <Link href={`/items/${it.ID}`} className="line-clamp-2 font-semibold text-slate-100 hover:underline">
                          {name}
                        </Link>
                        <div className="mt-1 flex items-center gap-1 text-sm text-amber-500">
                          <span>★</span>
                          <span className="font-semibold text-slate-200">
                            {summary.averageRating > 0 ? summary.averageRating.toFixed(1) : "0.0"}
                          </span>
                          <span className="text-xs text-slate-400">({summary.totalReviews})</span>
                        </div>
                        <p className="mt-1 line-clamp-1 text-xs text-slate-400">
                          {displayCategoryFilter(it.CATEGORY1 || "General")} • fast delivery
                        </p>
                        <div className="mt-3 flex items-center justify-between gap-2">
                          <div className="text-xl font-extrabold text-slate-100">{formatTry(unitPrice)}</div>
                          <div className="flex items-center gap-2">
                            <FavoriteButton itemId={it.ID} active={favSet.has(it.ID)} />
                            <AddToCartButton
                              itemId={it.ID}
                              name={name}
                              unitPrice={unitPrice}
                              className="rounded-xl bg-emerald-700 px-3 py-2 text-xs font-semibold text-white transition hover:bg-emerald-600 disabled:opacity-60"
                            >
                              Order
                            </AddToCartButton>
                          </div>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            ) : (
              <Card>
                <CardBody>
                  <div className="text-sm text-slate-300">No sales data yet. (`ORDERDETAILS` may be empty.)</div>
                </CardBody>
              </Card>
            )}
          </section>
        </>
      ) : (
        <section className="rounded-2xl border border-sky-400/20 bg-sky-400/5 p-4">
          <h2 className="text-lg font-extrabold text-slate-100">Search results</h2>
          <p className="mt-1 text-sm text-slate-300">
            Showing products for: <b className="text-sky-200">{q}</b>
          </p>
        </section>
      )}

      <div className="flex flex-wrap items-center justify-between gap-2 text-sm text-slate-400">
        <span>
          Products: <b className="text-slate-200">{result.total}</b>{" "}
          <span className="text-white/15">•</span> Showing: <b className="text-slate-200">{showing}</b>
          {category ? (
            <>
              {" "}
              <span className="text-white/15">•</span> Category:{" "}
              <b className="text-slate-200">{displayCategoryFilter(category)}</b>
            </>
          ) : null}
        </span>
        <span>
          Page{" "}
          <b className="text-slate-200">
            {result.page} / {lastPage}
          </b>
        </span>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {result.items.map((it, index) => {
          const name = it.ITEMNAME || "(Unnamed)";
          const unitPrice = tryNumber(it.UNITPRICE);
          const summary = reviewMap[Number(it.ID)] ?? { averageRating: 0, totalReviews: 0 };
          const imgSrc = itemPrimaryImageSrc({
            id: it.ID,
            name,
            brand: it.BRAND,
            imageUrl: it.IMAGE_URL,
          });

          return (
            <div
              key={it.ID}
              className="group rounded-3xl border border-white/10 bg-slate-900/45 p-3 shadow-[0_12px_26px_rgba(15,23,42,0.35)] transition hover:-translate-y-0.5 hover:shadow-[0_18px_34px_rgba(15,23,42,0.45)]"
            >
              <Link href={`/items/${it.ID}`} className="relative block overflow-hidden rounded-2xl bg-slate-800/60">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  alt={name}
                  src={imgSrc}
                  loading="lazy"
                  className="h-44 w-full object-cover transition duration-300 group-hover:scale-[1.04]"
                />
              </Link>

              <div className="mt-3">
                <div className="flex items-start justify-between gap-2">
                  <Link href={`/items/${it.ID}`} className="line-clamp-2 font-semibold text-slate-100 hover:underline">
                    {name}
                  </Link>
                  <FavoriteButton itemId={it.ID} active={favSet.has(it.ID)} />
                </div>
                <div className="mt-1 flex items-center gap-1 text-sm text-amber-500">
                  <span>★</span>
                  <span className="font-semibold text-slate-200">
                    {summary.averageRating > 0 ? summary.averageRating.toFixed(1) : "0.0"}
                  </span>
                  <span className="text-xs text-slate-400">({summary.totalReviews})</span>
                </div>
                <p className="mt-1 line-clamp-1 text-xs text-slate-400">
                  {displayCategoryFilter(it.CATEGORY1 || "General")} • Fresh and fast delivery
                </p>
              </div>

              <div className="mt-3 flex items-center justify-between gap-2">
                <div className="text-2xl font-extrabold text-slate-100">{formatTry(unitPrice)}</div>
                <AddToCartButton
                  itemId={it.ID}
                  name={name}
                  unitPrice={unitPrice}
                  className="rounded-xl bg-emerald-700 px-4 py-2 text-sm font-semibold text-white transition hover:bg-emerald-600 disabled:opacity-60"
                >
                  Order Now
                </AddToCartButton>
              </div>
            </div>
          );
        })}
      </div>

      {result.total === 0 ? (
        <Card>
          <CardBody className="flex items-center justify-between gap-3">
            <div>
              <div className="text-lg font-extrabold">No results</div>
              <div className="mt-1 text-sm text-slate-300">Try changing your search or clearing filters.</div>
            </div>
            <ButtonLink href="/items" variant="soft">
              Clear
            </ButtonLink>
          </CardBody>
        </Card>
      ) : null}

      <div className="flex flex-wrap items-center justify-between gap-3 pt-2 text-sm">
        <ButtonLink
          href={`/items?${qs(Math.max(1, result.page - 1))}`}
          variant="soft"
          className={result.page <= 1 ? "pointer-events-none opacity-50" : ""}
        >
          Previous
        </ButtonLink>

        <ButtonLink
          href={`/items?${qs(Math.min(lastPage, result.page + 1))}`}
          variant="soft"
          className={result.page >= lastPage ? "pointer-events-none opacity-50" : ""}
        >
          Next
        </ButtonLink>
      </div>
    </div>
  );
}

