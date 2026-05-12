import { requireAuth } from "@/lib/requireAuth";
import { Card, CardBody } from "@/components/ui/Card";
import Link from "next/link";

export const runtime = "nodejs";

/** Same areas as the Flutter Account tab (no notification hub). */
const accountLinks = [
  {
    href: "/account/user-info",
    title: "Profile",
    subtitle: "Name, email, phone, gender & birthday",
    icon: "user",
  },
  {
    href: "/account/orders",
    title: "Orders",
    subtitle: "History and delivery status",
    icon: "orders",
  },
  {
    href: "/account/addresses",
    title: "Addresses",
    subtitle: "Delivery addresses",
    icon: "pin",
  },
  {
    href: "/account/cards",
    title: "Saved cards",
    subtitle: "Payment cards on your account",
    icon: "card",
  },
  {
    href: "/account/password",
    title: "Change password",
    subtitle: "Security and sign-in",
    icon: "lock",
  },
] as const;

function AccountIcon({ kind }: { kind: (typeof accountLinks)[number]["icon"] }) {
  const cls = "h-5 w-5 shrink-0 text-indigo-200/90";
  switch (kind) {
    case "user":
      return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" className={cls} aria-hidden>
          <path d="M20 21a8 8 0 0 0-16 0" />
          <circle cx="12" cy="8" r="4" />
        </svg>
      );
    case "orders":
      return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" className={cls} aria-hidden>
          <path d="M9 5H7a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-2" />
          <rect x="9" y="3" width="6" height="4" rx="1" />
          <path d="M9 12h6M9 16h4" />
        </svg>
      );
    case "pin":
      return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" className={cls} aria-hidden>
          <path d="M12 21s7-4.35 7-10a7 7 0 1 0-14 0c0 5.65 7 10 7 10Z" />
          <circle cx="12" cy="11" r="2.5" />
        </svg>
      );
    case "card":
      return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" className={cls} aria-hidden>
          <rect x="2" y="5" width="20" height="14" rx="2" />
          <path d="M2 10h20" />
        </svg>
      );
    case "lock":
      return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" className={cls} aria-hidden>
          <rect x="5" y="11" width="14" height="10" rx="2" />
          <path d="M8 11V7a4 4 0 0 1 8 0v4" />
        </svg>
      );
    default:
      return null;
  }
}

export default async function AccountPage() {
  const user = await requireAuth();
  const display = (user.nameSurname || user.username || "Member").trim();
  const initial = display.slice(0, 1).toUpperCase();

  return (
    <div className="space-y-5">
      <div className="relative overflow-hidden rounded-2xl border border-indigo-400/25 bg-gradient-to-br from-[#0b1020] via-slate-900/95 to-indigo-950/50 p-5 shadow-[0_20px_50px_rgba(0,0,0,0.35)]">
        <div className="pointer-events-none absolute -right-16 -top-16 h-48 w-48 rounded-full bg-indigo-500/20 blur-3xl" />
        <div className="pointer-events-none absolute -bottom-20 -left-10 h-56 w-56 rounded-full bg-sky-500/10 blur-3xl" />
        <div className="relative">
          <p className="text-[11px] font-semibold uppercase tracking-[0.2em] text-sky-200/80">TradeHub</p>
          <h1 className="mt-1 text-2xl font-extrabold tracking-tight text-white">Account</h1>
          <p className="mt-1 max-w-xl text-sm text-slate-400">
            Profile, orders, and security — same areas as the mobile app.
          </p>
        </div>
      </div>

      <Card>
        <CardBody className="p-0 sm:p-0">
          <div className="border-b border-white/10 bg-slate-950/40 px-5 py-4">
            <div className="flex items-center gap-4">
              <div className="flex h-14 w-14 items-center justify-center rounded-2xl border border-indigo-400/35 bg-gradient-to-br from-indigo-500/30 to-sky-500/20 text-xl font-extrabold text-white shadow-inner shadow-indigo-900/40">
                {initial}
              </div>
              <div className="min-w-0">
                <p className="text-[11px] font-semibold uppercase tracking-wide text-slate-500">Signed in</p>
                <p className="truncate text-lg font-bold text-slate-100">{display}</p>
                <p className="text-xs text-slate-500">ID {user.id}</p>
              </div>
            </div>
          </div>

          <div className="space-y-2 p-4 sm:p-5">
            {accountLinks.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                className="group flex items-center gap-4 rounded-2xl border border-white/10 bg-slate-900/35 px-4 py-3.5 transition hover:border-indigo-400/35 hover:bg-indigo-500/[0.07]"
              >
                <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl border border-white/10 bg-slate-950/60">
                  <AccountIcon kind={item.icon} />
                </div>
                <div className="min-w-0 flex-1">
                  <div className="text-sm font-semibold text-slate-100">{item.title}</div>
                  <div className="mt-0.5 text-xs text-slate-500">{item.subtitle}</div>
                </div>
                <span className="shrink-0 text-slate-600 transition group-hover:translate-x-0.5 group-hover:text-indigo-300">
                  →
                </span>
              </Link>
            ))}
          </div>
        </CardBody>
      </Card>
    </div>
  );
}
