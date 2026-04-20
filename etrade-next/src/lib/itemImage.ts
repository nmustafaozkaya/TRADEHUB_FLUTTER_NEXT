/**
 * Product image URL helper.
 *
 * The database may store an external `IMAGE_URL` (https://...). The UI should prefer that when present,
 * and fall back to the deterministic SVG placeholder route (`/img/item/[id].svg`) used across the app.
 */

export function itemPlaceholderSvgSrc(opts: { id: number; name: string; brand?: string | null }) {
  const id = Number(opts.id);
  const name = opts.name || "(Unnamed)";
  const brand = opts.brand || "";
  return `/img/item/${id}.svg?name=${encodeURIComponent(name)}&brand=${encodeURIComponent(brand)}`;
}

/**
 * Returns the best image URL for an item row.
 * - If `imageUrl` is a non-empty string, use it.
 * - Otherwise use the SVG placeholder.
 */
export function itemPrimaryImageSrc(opts: {
  id: number;
  name: string;
  brand?: string | null;
  imageUrl?: string | null;
}) {
  const url = (opts.imageUrl || "").trim();
  if (url.length > 0) return url;
  return itemPlaceholderSvgSrc({ id: opts.id, name: opts.name, brand: opts.brand });
}
