import Link from "next/link";

import { getCart } from "@/lib/cart";
import { formatTry } from "@/lib/format";
import { shippingFee } from "@/lib/shipping";
import { CartLineEditor } from "@/components/CartLineEditor";
import { ClearCartButton } from "@/components/ClearCartButton";
import { Card, CardBody } from "@/components/ui/Card";
import { ButtonLink } from "@/components/ui/Button";
import { listBestSellers } from "@/lib/repos/dashboard";
import { getFavorites } from "@/lib/favorites";
import { ItemTile } from "@/components/ItemTile";
import { getItemsByIds } from "@/lib/repos/items";
import { itemPrimaryImageSrc } from "@/lib/itemImage";
import { buildExtendedWarrantyPlan } from "@/lib/extendedWarranty";
import { CartProtectionPlans } from "@/components/CartProtectionPlans";

export const runtime = "nodejs";

export default async function CartPage() {
  const cart = await getCart();
  const cartItemIds = Array.from(new Set(cart.lines.map((l) => Number(l.itemId)).filter((n) => Number.isFinite(n) && n > 0)));
  const cartItems = cartItemIds.length ? await getItemsByIds(cartItemIds) : [];
  const cartImageById = new Map(cartItems.map((it) => [Number(it.ID), it.IMAGE_URL]));
  const cartItemById = new Map(cartItems.map((it) => [Number(it.ID), it]));

  const itemsSubtotal = cart.lines.reduce((sum, l) => sum + Number(l.unitPrice) * Number(l.qty), 0);
  const protectionTotal = cart.lines.reduce(
    (sum, l) => sum + Number(l.protection?.price ?? 0) * Number(l.qty),
    0
  );
  const subtotal = itemsSubtotal + protectionTotal;
  const ship = shippingFee(subtotal);
  const total = subtotal + ship;
  const itemsCount = cart.lines.reduce((sum, l) => sum + Number(l.qty || 0), 0);

  if (!cart.lines.length) {
    return (
      <Card>
        <CardBody>
          <h1 className="text-2xl font-extrabold">Cart</h1>
          <p className="mt-2 text-slate-300">
            Your cart is empty. <Link className="text-sky-200 hover:underline" href="/items">Go to items</Link>.
          </p>
        </CardBody>
      </Card>
    );
  }

  const [bestSellers, favs] = await Promise.all([listBestSellers(14), getFavorites()]);
  const favSet = new Set(favs.ids);
  const inCart = new Set(cart.lines.map((l) => Number(l.itemId)));
  const recommendations = bestSellers.filter((x) => !inCart.has(Number(x.ID))).slice(0, 10);

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-extrabold">Cart</h1>
          <p className="mt-1 text-sm text-slate-400">{itemsCount} items</p>
        </div>
        <div className="flex items-center gap-2">
          <ButtonLink href="/items" variant="soft">
            Continue shopping
          </ButtonLink>
          <ClearCartButton />
        </div>
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <div className="space-y-3 lg:col-span-2">
          {cart.lines.map((l) => {
            const itemMeta = cartItemById.get(Number(l.itemId));
            const imgSrc = itemPrimaryImageSrc({
              id: Number(l.itemId),
              name: l.name,
              brand: "",
              imageUrl: cartImageById.get(Number(l.itemId)) ?? null,
            });
            const protectionPlan = buildExtendedWarrantyPlan({
              unitPrice: Number(l.unitPrice),
              category1: itemMeta?.CATEGORY1 ?? null,
              category2: itemMeta?.CATEGORY2 ?? null,
              category3: itemMeta?.CATEGORY3 ?? null,
              category4: itemMeta?.CATEGORY4 ?? null,
            });
            return (
              <Card key={l.itemId}>
                <CardBody>
                  <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                    <div className="flex items-start gap-3">
                      <Link href={`/items/${l.itemId}`} className="shrink-0 overflow-hidden rounded-xl border border-white/10">
                        {/* eslint-disable-next-line @next/next/no-img-element */}
                        <img alt={l.name} src={imgSrc} className="h-20 w-20 object-cover" />
                      </Link>
                      <div className="min-w-0">
                        <Link href={`/items/${l.itemId}`} className="line-clamp-2 font-semibold text-slate-100 hover:underline">
                          {l.name}
                        </Link>
                        <div className="mt-2 flex flex-wrap items-center gap-2 text-sm">
                          <span className="text-slate-300">{formatTry(l.unitPrice)}</span>
                          <span className="text-white/15">•</span>
                          <span className="text-slate-400">
                            Line:{" "}
                            <b className="text-slate-200">
                              {formatTry((Number(l.unitPrice) + Number(l.protection?.price ?? 0)) * Number(l.qty))}
                            </b>
                          </span>
                        </div>
                        {l.protection ? (
                          <div className="mt-1 text-xs text-emerald-300">
                            Protection: {l.protection.years}-year ({formatTry(l.protection.price)} per item)
                          </div>
                        ) : null}
                      </div>
                    </div>

                    <div className="flex items-center justify-between gap-3 sm:flex-col sm:items-end">
                      <CartLineEditor itemId={l.itemId} qty={l.qty} />
                    </div>
                  </div>

                  <div className="mt-4 rounded-2xl border border-white/10 bg-white/5 p-3">
                    <div className="text-sm font-bold text-slate-100">{protectionPlan.title}</div>
                    <div className="mt-1 text-xs text-slate-400">{protectionPlan.subtitle}</div>

                    {!protectionPlan.offers.length ? (
                      <div className="mt-3 text-xs text-slate-400">
                        No protection plans available for this item.
                      </div>
                    ) : (
                      <CartProtectionPlans
                        itemId={Number(l.itemId)}
                        offers={protectionPlan.offers}
                        selectedYears={l.protection?.years ?? null}
                      />
                    )}
                  </div>
                </CardBody>
              </Card>
            );
          })}
        </div>

        <aside className="space-y-4">
          <Card className="sticky top-24">
            <CardBody>
              <div className="text-sm font-bold text-slate-100">Order summary</div>
              <div className="mt-3 space-y-2 text-sm">
                <div className="flex items-center justify-between text-slate-300">
                  <span>Subtotal</span>
                  <span className="text-slate-200">{formatTry(itemsSubtotal)}</span>
                </div>
                <div className="flex items-center justify-between text-slate-300">
                  <span>Protection</span>
                  <span className="text-slate-200">{formatTry(protectionTotal)}</span>
                </div>
                <div className="flex items-center justify-between text-slate-300">
                  <span>Shipping</span>
                  <span className="text-slate-200">
                    {ship === 0 ? (
                      <>
                        {formatTry(0)} <span className="text-xs text-emerald-200/90">(free over {formatTry(300)})</span>
                      </>
                    ) : (
                      formatTry(ship)
                    )}
                  </span>
                </div>
                <div className="flex items-center justify-between text-slate-300">
                  <span>Discount</span>
                  <span className="text-slate-200">{formatTry(0)}</span>
                </div>
                <div className="pt-2 text-lg font-extrabold">
                  <div className="flex items-center justify-between">
                    <span>Total</span>
                    <span>{formatTry(total)}</span>
                  </div>
                </div>
              </div>

              <ButtonLink href="/checkout" variant="primary" className="mt-4 w-full justify-center">
                Checkout
              </ButtonLink>

              <div className="mt-3 text-xs text-slate-400">
                Checkout will create an order record in the database (MVP).
              </div>
            </CardBody>
          </Card>
        </aside>
      </div>

      {recommendations.length ? (
        <section className="space-y-2 pt-2">
          <div>
            <h2 className="text-lg font-extrabold">You may also like</h2>
            <p className="text-sm text-slate-400">Popular items across the store.</p>
          </div>

          <div className="-mx-4 flex gap-3 overflow-x-auto px-4 pb-2 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
            {recommendations.map((it) => (
              <div key={it.ID} className="w-[240px] shrink-0">
                <ItemTile item={it} favoriteActive={favSet.has(it.ID)} compact />
              </div>
            ))}
          </div>
        </section>
      ) : null}
    </div>
  );
}

