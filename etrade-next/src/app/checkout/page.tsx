import Link from "next/link";
import { redirect } from "next/navigation";

import { getCart } from "@/lib/cart";
import { getUser } from "@/lib/auth";
import { listAddressesForUser } from "@/lib/repos/addresses";
import { listSavedCardsForUser } from "@/lib/repos/cards";
import { formatTry } from "@/lib/format";
import { shippingFee } from "@/lib/shipping";
import { CheckoutForm } from "./ui/CheckoutForm";
import { Card, CardBody } from "@/components/ui/Card";
import { ButtonLink } from "@/components/ui/Button";

export const runtime = "nodejs";

export default async function CheckoutPage() {
  const user = await getUser();
  if (!user) redirect("/auth/login");

  const cart = await getCart();
  const itemsSubtotal = cart.lines.reduce((sum, l) => sum + Number(l.unitPrice) * Number(l.qty), 0);
  const protectionTotal = cart.lines.reduce(
    (sum, l) => sum + Number(l.protection?.price ?? 0) * Number(l.qty),
    0
  );
  const subtotal = itemsSubtotal + protectionTotal;
  const ship = shippingFee(subtotal);
  const total = subtotal + ship;

  if (!cart.lines.length) {
    return (
      <Card>
        <CardBody>
          <h1 className="text-2xl font-extrabold">Checkout</h1>
          <p className="mt-2 text-slate-300">
            Your cart is empty. <Link className="text-sky-200 hover:underline" href="/items">Go to items</Link>.
          </p>
        </CardBody>
      </Card>
    );
  }

  const addresses = await listAddressesForUser(user.id);
  const savedCards = await listSavedCardsForUser(user.id);
  const itemsCount = cart.lines.reduce((sum, l) => sum + Number(l.qty || 0), 0);

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-extrabold">Secure checkout</h1>
          <p className="mt-1 text-sm text-slate-400">Address & payment details</p>
        </div>
        <ButtonLink href="/cart" variant="soft">
          Go to cart
        </ButtonLink>
      </div>

      <div className="grid items-start gap-4 lg:grid-cols-3">
        <div className="relative z-10 space-y-4 lg:col-span-2">
          <Card>
            <CardBody>
              <div className="flex items-center justify-between gap-3">
                <div>
                  <h2 className="text-lg font-extrabold">1) Delivery</h2>
                  <p className="mt-1 text-sm text-slate-400">Choose a delivery address for your order.</p>
                </div>
              </div>
              <div className="mt-4">
                <CheckoutForm
                  formId="checkout-form"
                  addresses={addresses}
                  savedCards={savedCards}
                  userId={user.id}
                />
              </div>
            </CardBody>
          </Card>
        </div>

        <aside className="relative z-0 space-y-4">
          <Card>
            <CardBody>
              <div className="flex items-start justify-between gap-3">
                <div>
                  <div className="text-sm font-bold text-slate-100">Order summary</div>
                  <div className="mt-1 text-xs text-slate-400">{itemsCount} items</div>
                </div>
                <div className="text-xs text-slate-400">TradeHub</div>
              </div>

              <ul className="mt-3 space-y-2 text-sm text-slate-300">
                {cart.lines.slice(0, 4).map((l) => (
                  <li key={l.itemId} className="flex items-start justify-between gap-3">
                    <span className="min-w-0 truncate">
                      {l.name} <span className="text-slate-500">× {l.qty}</span>
                    </span>
                    <span className="shrink-0 text-slate-200">
                      {formatTry((Number(l.unitPrice) + Number(l.protection?.price ?? 0)) * Number(l.qty))}
                    </span>
                  </li>
                ))}
                {cart.lines.length > 4 ? (
                  <li className="text-xs text-slate-400">+ {cart.lines.length - 4} more items</li>
                ) : null}
              </ul>

              <div className="mt-4 space-y-2 text-sm">
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

              <button
                form="checkout-form"
                type="submit"
                className="mt-4 w-full rounded-xl border border-white/10 bg-sky-400/20 px-3 py-2 text-sm font-semibold text-sky-200 hover:bg-sky-400/25"
              >
                Place order
              </button>

              <div className="mt-3 text-xs text-slate-400">
                By placing an order, you agree that this MVP will create an order record in the database.
              </div>
            </CardBody>
          </Card>

          <Card>
            <CardBody>
              <div className="text-sm font-bold text-slate-100">Need help?</div>
              <div className="mt-1 text-sm text-slate-300">
                Manage your addresses from{" "}
                <Link href="/account/addresses" className="text-sky-200 hover:underline">
                  My Account → Addresses
                </Link>
                .
              </div>
            </CardBody>
          </Card>
        </aside>
      </div>
    </div>
  );
}

