import Link from "next/link";
import Image from "next/image";

import { cartCount, getCart } from "@/lib/cart";
import { getUser } from "@/lib/auth";
import { favoritesCount, getFavorites } from "@/lib/favorites";
import { ToastHost } from "./ToastHost";
import { ButtonLink } from "./ui/Button";
import { AccountMenu } from "./AccountMenu";

export async function Header() {
  const user = await getUser();
  const cart = await getCart();
  const count = cartCount(cart);
  const favs = await getFavorites();
  const favCount = favoritesCount(favs);

  const accountNameSurname = user ? user.nameSurname || user.username : "Guest";

  return (
    <>
      <header className="sticky top-0 z-40 h-14 overflow-visible border-b border-white/10 bg-slate-950/70 backdrop-blur sm:h-16">
        <div className="mx-auto flex h-full w-full max-w-6xl items-center gap-3 px-4">
          <Link href="/items" className="relative block h-full w-[220px] shrink-0 sm:w-[260px]">
            <Image
              src="/TradeHub-logo-transparent.png"
              alt="TradeHub"
              width={720}
              height={168}
              priority
              className="absolute left-0 top-1/2 h-28 w-auto -translate-y-1/2 object-contain sm:h-32 md:h-36 lg:h-40"
            />
          </Link>

          <nav className="ml-auto flex items-center justify-end gap-3 text-sm">
            {user ? (
              <>
                <AccountMenu label="My Account" nameSurname={accountNameSurname} />
              </>
            ) : (
              <>
                <ButtonLink href="/auth/login" variant="soft">
                  My Account
                </ButtonLink>
              </>
            )}

            <Link
              className="text-slate-200/90 hover:text-white"
              href={user ? "/favorites" : "/auth/login?next=%2Ffavorites"}
            >
              Favorites{" "}
              <span className="rounded-full border border-white/10 bg-white/5 px-2 py-0.5 text-xs text-slate-200/90">
                {favCount}
              </span>
            </Link>

            <Link className="text-slate-200/90 hover:text-white" href="/cart">
              Cart{" "}
              <span className="rounded-full border border-white/10 bg-white/5 px-2 py-0.5 text-xs text-slate-200/90">
                {count}
              </span>
            </Link>
          </nav>
        </div>
      </header>

      <ToastHost />
    </>
  );
}

