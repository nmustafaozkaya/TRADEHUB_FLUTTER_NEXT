import Link from "next/link";

import { getFavorites } from "@/lib/favorites";
import { getItemsByIds } from "@/lib/repos/items";
import { Card, CardBody } from "@/components/ui/Card";
import { formatTry, tryNumber } from "@/lib/format";
import { itemPrimaryImageSrc } from "@/lib/itemImage";
import { AddToCartButton } from "@/components/AddToCartButton";
import { FavoriteButton } from "@/components/FavoriteButton";
import { requireAuth } from "@/lib/requireAuth";

export const runtime = "nodejs";

export default async function FavoritesPage() {
  await requireAuth("/favorites");
  const favs = await getFavorites();
  const items = await getItemsByIds(favs.ids);
  const activeIds = new Set(favs.ids);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-3">
        <h1 className="text-2xl font-extrabold">Favorites</h1>
        <Link className="text-sm text-slate-400 hover:text-slate-200" href="/items">
          ← Back to shopping
        </Link>
      </div>

      {!items.length ? (
        <Card>
          <CardBody>
            <div className="text-slate-300">No favorites yet.</div>
            <Link className="mt-3 inline-block text-sky-200 hover:underline" href="/items">
              Browse products
            </Link>
          </CardBody>
        </Card>
      ) : (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {items.map((it) => {
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
                className="group rounded-2xl border border-white/10 bg-white/5 p-4 shadow-[0_18px_44px_rgba(0,0,0,0.18)] transition hover:-translate-y-0.5 hover:border-white/20"
              >
                <Link href={`/items/${it.ID}`} className="block overflow-hidden rounded-xl border border-white/10">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img alt={name} src={imgSrc} className="h-40 w-full object-cover" />
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
                  </div>
                  <FavoriteButton itemId={it.ID} active={activeIds.has(it.ID)} />
                </div>

                <div className="mt-3 flex items-center justify-between">
                  <div className="text-lg font-extrabold">{formatTry(unitPrice)}</div>
                  <AddToCartButton itemId={it.ID} name={name} unitPrice={unitPrice} />
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

