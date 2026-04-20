"use client";

import Link from "next/link";
import { useEffect, useRef, useState } from "react";

import { showToast } from "@/components/ToastHost";
import { cn } from "@/lib/ui";

export function AccountMenu(props: {
  label: string;
  nameSurname: string;
}) {
  const [open, setOpen] = useState(false);
  const [isSigningOut, setIsSigningOut] = useState(false);
  const rootRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    const onDown = (e: PointerEvent) => {
      const el = rootRef.current;
      if (!el) return;
      if (el.contains(e.target as Node)) return;
      setOpen(false);
    };
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setOpen(false);
    };
    window.addEventListener("pointerdown", onDown);
    window.addEventListener("keydown", onKey);
    return () => {
      window.removeEventListener("pointerdown", onDown);
      window.removeEventListener("keydown", onKey);
    };
  }, []);

  const handleSignOut = async () => {
    if (isSigningOut) return;
    setIsSigningOut(true);
    setOpen(false);
    showToast({ type: "success", message: "Signing out..." });
    try {
      await fetch("/auth/logout", {
        method: "POST",
        cache: "no-store",
      });
    } finally {
      // Force full reload so server components read the cleared cookie.
      window.location.assign("/");
    }
  };

  return (
    <div
      ref={rootRef}
      className="relative"
      onMouseEnter={() => setOpen(true)}
    >
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className="inline-flex items-center gap-2 rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-sm font-medium text-slate-200 hover:bg-white/10"
      >
        <span className="hidden sm:inline">{props.label}</span>
        <span className="sm:hidden">Account</span>
        <span className={cn("transition", open ? "rotate-180" : "")}>▾</span>
      </button>

      {open ? (
        <div
          className="absolute right-0 mt-2 w-[320px] overflow-hidden rounded-2xl border border-white/10 bg-slate-950/95 shadow-[0_18px_44px_rgba(0,0,0,0.45)] backdrop-blur"
          onWheel={(e) => e.stopPropagation()}
        >
          <div className="border-b border-white/10 px-4 py-3">
            <div className="text-xs text-slate-400">My Account</div>
            <div className="mt-1 text-sm font-bold text-slate-100">{props.nameSurname}</div>
            <div className="mt-2">
              <MenuLink href="/account/orders" onClick={() => setOpen(false)} strong>
                All Orders
              </MenuLink>
            </div>
          </div>

          <div className="max-h-[70vh] overflow-y-auto overscroll-contain px-2 py-2">
            <MenuLink href="/account" onClick={() => setOpen(false)}>
              Account
            </MenuLink>
            <MenuLink href="/account/reviews" onClick={() => setOpen(false)}>
              My Reviews
            </MenuLink>
            <MenuLink href="/account/coupons" onClick={() => setOpen(false)} badge="New">
              Discount Coupons
            </MenuLink>
            <MenuLink href="/account/cards" onClick={() => setOpen(false)}>
              Saved Cards
            </MenuLink>
            <MenuLink href="/account/plus" onClick={() => setOpen(false)}>
              TradeHub Plus
            </MenuLink>
            <MenuLink href="/account/assistant" onClick={() => setOpen(false)}>
              TradeHub Assistant
            </MenuLink>
            <div className="mt-2 border-t border-white/10 pt-2">
              <MenuLink href="/account/addresses" onClick={() => setOpen(false)}>
                Addresses
              </MenuLink>
              <div className="mt-1 border-t border-white/10 pt-2">
                <button
                  type="button"
                  disabled={isSigningOut}
                  onClick={handleSignOut}
                  className="flex w-full items-center justify-between gap-2 rounded-xl px-3 py-2 text-left text-sm font-semibold text-slate-200 hover:bg-white/10 disabled:opacity-60"
                >
                  <span>{isSigningOut ? "Signing out..." : "Sign out"}</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}

function MenuLink(props: {
  href: string;
  children: React.ReactNode;
  onClick?: () => void;
  badge?: string;
  strong?: boolean;
}) {
  return (
    <Link
      href={props.href}
      onClick={(e) => {
        e.preventDefault();
        props.onClick?.();
        window.location.assign(props.href);
      }}
      className={cn(
        "flex items-center justify-between gap-2 rounded-xl px-3 py-2 text-sm text-slate-200 hover:bg-white/10",
        props.strong ? "font-semibold" : ""
      )}
    >
      <span>{props.children}</span>
      {props.badge ? (
        <span className="rounded-full border border-sky-400/25 bg-sky-400/10 px-2 py-0.5 text-[10px] font-bold text-sky-100/90">
          {props.badge}
        </span>
      ) : null}
    </Link>
  );
}

