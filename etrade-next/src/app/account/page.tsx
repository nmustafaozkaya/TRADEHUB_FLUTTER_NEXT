import { requireAuth } from "@/lib/requireAuth";
import { Card, CardBody } from "@/components/ui/Card";
import Link from "next/link";

export const runtime = "nodejs";

const accountLinks = [
  { href: "/account/user-info", title: "My User Information", subtitle: "Update your profile details" },
  { href: "/account/addresses", title: "My Addresses", subtitle: "Manage delivery addresses" },
  { href: "/account/cards", title: "My Saved Cards", subtitle: "View and remove your cards" },
  { href: "/account/notifications", title: "Notification Preferences", subtitle: "Campaign and alert settings" },
  { href: "/account/password", title: "Change Password", subtitle: "Security and password settings" },
] as const;

export default async function AccountPage() {
  const user = await requireAuth();

  return (
    <div className="space-y-4">
      <div className="rounded-2xl border border-sky-400/20 bg-gradient-to-r from-sky-500/15 via-indigo-500/10 to-fuchsia-500/10 p-4">
        <h1 className="text-2xl font-extrabold text-slate-100">Account & Help</h1>
        <p className="mt-1 text-sm text-slate-300">Manage your account and security settings in one place.</p>
      </div>

      <Card>
        <CardBody>
          <div className="rounded-2xl border border-white/10 bg-gradient-to-r from-slate-900/70 to-slate-800/40 p-4">
            <div className="flex items-center gap-3">
              <div className="flex h-12 w-12 items-center justify-center rounded-2xl border border-sky-400/30 bg-sky-400/15 text-lg font-extrabold text-sky-100">
                {(user.nameSurname || user.username).slice(0, 1).toUpperCase()}
              </div>
              <div>
                <div className="text-xs uppercase tracking-wide text-slate-400">User</div>
                <div className="text-lg font-bold text-slate-100">{user.nameSurname || user.username}</div>
                <div className="text-xs text-slate-400">ID: {user.id}</div>
              </div>
            </div>
          </div>

          <div className="mt-5 space-y-2">
            {accountLinks.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                className="group flex items-center justify-between rounded-2xl border border-white/10 bg-white/5 px-4 py-3 hover:border-sky-400/30 hover:bg-sky-400/10"
              >
                <div>
                  <div className="text-sm font-semibold text-slate-100">{item.title}</div>
                  <div className="mt-0.5 text-xs text-slate-400">{item.subtitle}</div>
                </div>
                <div className="text-slate-500 transition group-hover:translate-x-0.5 group-hover:text-sky-200">→</div>
              </Link>
            ))}
          </div>
        </CardBody>
      </Card>
    </div>
  );
}

