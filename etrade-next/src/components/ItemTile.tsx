import Link from "next/link";

import type { ItemRow } from "@/lib/repos/items";
import { formatTry, tryNumber } from "@/lib/format";
import { itemPrimaryImageSrc } from "@/lib/itemImage";
import { AddToCartButton } from "./AddToCartButton";
import { FavoriteButton } from "./FavoriteButton";

export function ItemTile(props: {
  item: ItemRow;
  favoriteActive: boolean;
  showMeta?: boolean;
  compact?: boolean;
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

  return (
    <div
      className={[
        "group rounded-2xl border border-white/10 bg-white/5 shadow-[0_18px_44px_rgba(0,0,0,0.18)] transition hover:-translate-y-0.5 hover:border-white/20",
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

        <div className={compact ? "mt-2 flex items-center justify-between gap-2" : "mt-3 flex items-center justify-between gap-2"}>
          <div className={compact ? "text-base font-extrabold" : "text-lg font-extrabold"}>{formatTry(unitPrice)}</div>
          <AddToCartButton itemId={it.ID} name={name} unitPrice={unitPrice} className={compact ? "rounded-xl border border-white/10 bg-sky-400/20 px-2 py-2 text-xs font-medium text-sky-200 transition hover:bg-sky-400/25 disabled:opacity-60" : undefined}>
            {compact ? "Add" : undefined}
          </AddToCartButton>
        </div>
      </div>
    </div>
  );
}

