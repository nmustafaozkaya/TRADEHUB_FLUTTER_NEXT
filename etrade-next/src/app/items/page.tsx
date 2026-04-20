import Link from "next/link";
import Image from "next/image";

import { listItems } from "@/lib/repos/items";
import { formatTry, tryNumber } from "@/lib/format";
import { AddToCartButton } from "@/components/AddToCartButton";
import { Badge } from "@/components/ui/Badge";
import { Card, CardBody } from "@/components/ui/Card";
import { ButtonLink } from "@/components/ui/Button";
import { listBestSellers, listTopCategories } from "@/lib/repos/dashboard";
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

  const [result, topCategories, bestSellers, favs] = await Promise.all([
    listItems({ q, category, page, pageSize: 20 }),
    listTopCategories(10),
    listBestSellers(10),
    getFavorites(),
  ]);
  const favSet = new Set(favs.ids);
  const lastPage = Math.max(1, Math.ceil(result.total / result.pageSize));

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
      <section className="relative overflow-hidden rounded-2xl border border-white/10 bg-slate-900/25 p-5">
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
        <div className="pointer-events-none absolute -right-24 -top-24 h-72 w-72 rounded-full bg-sky-400/20 blur-3xl" />
        <div className="pointer-events-none absolute -bottom-24 -left-24 h-72 w-72 rounded-full bg-fuchsia-400/10 blur-3xl" />
        <div className="relative">
        <form action="/items" method="get" className="flex w-full flex-col gap-2">
          <input
            name="q"
            defaultValue={q}
            placeholder="Search by product, category, or brand"
            className="w-full rounded-2xl border border-white/10 bg-slate-950/30 px-4 py-3 text-base outline-none focus:border-white/20"
          />
          <div className="flex flex-col gap-2 md:flex-row">
            <input type="hidden" name="category" value={category} />
            <button className="rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-sm hover:bg-white/10 md:w-28">
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
                <p className="text-sm text-slate-400">Top categories by number of products.</p>
              </div>
              {category ? (
                <ButtonLink href="/items" variant="soft">
                  Clear filter
                </ButtonLink>
              ) : null}
            </div>

            <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
              {topCategories.map((c) => (
                <Link
                  key={c.Category}
                  href={`/items?${new URLSearchParams({ ...(q ? { q } : {}), category: c.Category }).toString()}`}
                  className={[
                    "group rounded-2xl border border-white/10 bg-slate-900/25 p-4 transition hover:-translate-y-0.5 hover:border-white/20",
                    category === c.Category ? "border-sky-400/30 bg-sky-400/10" : "",
                  ].join(" ")}
                >
                  <div className="text-sm font-bold text-slate-100 group-hover:text-white">{c.Category}</div>
                  <div className="mt-1 text-xs text-slate-400">{c.Cnt} items</div>
                </Link>
              ))}
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
                  const imgSrc = itemPrimaryImageSrc({
                    id: it.ID,
                    name,
                    brand: it.BRAND,
                    imageUrl: it.IMAGE_URL,
                  });
                  return (
                    <div
                      key={it.ID}
                      className="w-[260px] shrink-0 rounded-2xl border border-white/10 bg-slate-900/25 p-4 transition hover:-translate-y-0.5 hover:border-white/20"
                    >
                      <Link href={`/items/${it.ID}`} className="block overflow-hidden rounded-xl border border-white/10">
                        {/* eslint-disable-next-line @next/next/no-img-element */}
                        <img alt={name} src={imgSrc} className="h-36 w-full object-cover" />
                      </Link>
                      <div className="mt-3">
                        <Link href={`/items/${it.ID}`} className="line-clamp-2 font-semibold text-slate-100 hover:underline">
                          {name}
                        </Link>
                        <div className="mt-1 flex items-center justify-between text-xs text-slate-400">
                          <span>Sold: <b className="text-slate-200">{it.SoldQty}</b></span>
                          <span className="font-semibold text-slate-200">{formatTry(unitPrice)}</span>
                        </div>
                        <div className="mt-3 flex items-center justify-between">
                          <div className="flex flex-wrap gap-2">
                            {it.BRAND ? <Badge className="border-sky-400/20 bg-sky-400/10 text-sky-100/90">{it.BRAND}</Badge> : null}
                          </div>
                          <div className="flex items-center gap-2">
                            <FavoriteButton itemId={it.ID} active={favSet.has(it.ID)} />
                            <AddToCartButton itemId={it.ID} name={name} unitPrice={unitPrice} />
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
              <b className="text-slate-200">{category}</b>
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
        {result.items.map((it) => {
          const name = it.ITEMNAME || "(Unnamed)";
          const unitPrice = tryNumber(it.UNITPRICE);
          const imgSrc = itemPrimaryImageSrc({
            id: it.ID,
            name,
            brand: it.BRAND,
            imageUrl: it.IMAGE_URL,
          });

          return (
            <div
              key={it.ID}
              className="group rounded-2xl border border-white/10 bg-slate-900/25 p-4 shadow-[0_18px_44px_rgba(0,0,0,0.18)] transition hover:-translate-y-0.5 hover:border-white/20"
            >
              <Link href={`/items/${it.ID}`} className="block overflow-hidden rounded-xl border border-white/10">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  alt={name}
                  src={imgSrc}
                  loading="lazy"
                  className="h-40 w-full object-cover transition duration-300 group-hover:scale-[1.06]"
                />
              </Link>

              <div className="mt-3 flex items-start justify-between gap-2">
                <div className="min-w-0">
                  <Link href={`/items/${it.ID}`} className="line-clamp-2 font-semibold text-slate-100 hover:underline">
                    {name}
                  </Link>
                  <div className="mt-1 text-xs text-slate-400">
                    <span>Code: {it.ITEMCODE || "-"}</span>
                    <span className="mx-2 text-white/15">•</span>
                    <span>Brand: {it.BRAND || "-"}</span>
                  </div>
                  <div className="mt-2 flex flex-wrap gap-2">
                    {it.BRAND ? <Badge className="border-sky-400/20 bg-sky-400/10 text-sky-100/90">{it.BRAND}</Badge> : null}
                    {it.CATEGORY1 ? <Badge>{it.CATEGORY1}</Badge> : null}
                  </div>
                </div>
                <FavoriteButton itemId={it.ID} active={favSet.has(it.ID)} />
              </div>

              <div className="mt-3 flex items-center justify-between">
                <div className="text-lg font-extrabold">{formatTry(unitPrice)}</div>
                <AddToCartButton itemId={it.ID} name={name} unitPrice={unitPrice} />
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

