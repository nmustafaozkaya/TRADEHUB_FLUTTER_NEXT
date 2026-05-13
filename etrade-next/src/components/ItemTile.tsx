import Link from "next/link";

import type { ItemRow } from "@/lib/repos/items";
import { formatTry, tryNumber } from "@/lib/format";
import { itemPrimaryImageSrc } from "@/lib/itemImage";
import { displayCategoryFilter } from "@/lib/shopCategories";
import { AddToCartButton } from "./AddToCartButton";
import { FavoriteButton } from "./FavoriteButton";

export function ItemTile(props: {
  item: ItemRow;
  favoriteActive: boolean;
  showMeta?: boolean;
  compact?: boolean;
  averageRating?: number;
  totalReviews?: number;
}) {
  const it = props.item;
  const name = it.ITEMNAME || "(Unnamed)";
  const unitPrice = tryNumber(it.UNITPRICE);
  const imgSrc = itemPrimaryImageSrc({
    id: it.ID,
    name,
    brand: it.BRAND,
    imageUrl: it.IMAGE_URL,
  });

  const compact = Boolean(props.compact);
  const avg = Number(props.averageRating ?? 0);
  const totalReviews = Number(props.totalReviews ?? 0);

  return (
    <div
      className={[
        "group rounded-3xl border border-white/10 bg-slate-900/45 shadow-[0_12px_26px_rgba(15,23,42,0.35)] transition hover:-translate-y-0.5 hover:shadow-[0_18px_34px_rgba(15,23,42,0.45)]",
        compact ? "p-3" : "p-4",
      ].join(" ")}
    >
      <Link href={`/items/${it.ID}`} className="block overflow-hidden rounded-xl border border-white/10">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          alt={name}
          src={imgSrc}
          loading="lazy"
          className={compact ? "h-28 w-full object-cover" : "h-40 w-full object-cover"}
        />
      </Link>

      <div className={compact ? "mt-2" : "mt-3"}>
        <div className="flex items-start justify-between gap-2">
          <div className="min-w-0">
            <Link href={`/items/${it.ID}`} className="line-clamp-2 font-semibold text-slate-100 hover:underline">
              {name}
            </Link>
            {props.showMeta ? (
              <div className="mt-1 text-xs text-slate-400">
                <span>Code: {it.ITEMCODE || "-"}</span>
                <span className="mx-2 text-white/15">•</span>
                <span>Brand: {it.BRAND || "-"}</span>
              </div>
            ) : null}
          </div>
          <FavoriteButton itemId={it.ID} active={props.favoriteActive} />
        </div>
        <div className="mt-1 flex items-center gap-1 text-sm text-amber-500">
          <span>★</span>
          <span className="font-semibold text-slate-200">{avg > 0 ? avg.toFixed(1) : "0.0"}</span>
          <span className="text-xs text-slate-400">({totalReviews})</span>
        </div>
        <p className="mt-1 line-clamp-1 text-xs text-slate-400">
          {displayCategoryFilter(it.CATEGORY1 || "General")} • Fresh and fast delivery
        </p>

        <div className={compact ? "mt-2 flex items-center justify-between gap-2" : "mt-3 flex items-center justify-between gap-2"}>
          <div className={compact ? "text-base font-extrabold" : "text-lg font-extrabold"}>{formatTry(unitPrice)}</div>
          <AddToCartButton
            itemId={it.ID}
            name={name}
            unitPrice={unitPrice}
            className={compact ? "rounded-xl bg-emerald-700 px-3 py-2 text-xs font-semibold text-white transition hover:bg-emerald-600 disabled:opacity-60" : "rounded-xl bg-emerald-700 px-4 py-2 text-sm font-semibold text-white transition hover:bg-emerald-600 disabled:opacity-60"}
          >
            {compact ? "Order Now" : "Order Now"}
          </AddToCartButton>
        </div>
      </div>
    </div>
  );
}

