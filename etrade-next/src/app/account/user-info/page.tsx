import Link from "next/link";

import { Card, CardBody } from "@/components/ui/Card";
import { requireAuth } from "@/lib/requireAuth";
import { getUserProfileById } from "@/lib/repos/users";
import { UserInfoForm } from "./UserInfoForm";

export const runtime = "nodejs";

export default async function UserInfoPage() {
  const user = await requireAuth();
  const profile = await getUserProfileById(user.id);
  if (!profile) {
    return (
      <div className="space-y-4">
        <div className="flex items-center justify-between gap-3">
          <h1 className="text-2xl font-extrabold tracking-tight text-slate-100">Profile</h1>
          <Link className="text-sm text-slate-400 transition hover:text-sky-300" href="/account">
            ← Account
          </Link>
        </div>
        <Card>
          <CardBody>
            <div className="rounded-xl border border-rose-400/25 bg-rose-500/10 px-4 py-3 text-sm text-rose-100">
              Could not load your profile.
            </div>
          </CardBody>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-sky-200/80">Account</p>
          <h1 className="mt-1 text-2xl font-extrabold tracking-tight text-slate-100">Profile</h1>
          <p className="mt-1 max-w-lg text-sm text-slate-400">
            Same fields as the TradeHub mobile app. Changes save to your account immediately.
          </p>
        </div>
        <Link
          className="shrink-0 rounded-xl border border-white/10 bg-slate-900/50 px-4 py-2 text-sm font-medium text-slate-200 transition hover:border-indigo-400/30 hover:bg-indigo-500/10"
          href="/account"
        >
          ← Account
        </Link>
      </div>

      <Card>
        <CardBody className="p-0 sm:p-0">
          <div className="border-b border-white/10 bg-slate-950/35 px-5 py-4">
            <p className="text-xs font-medium text-slate-500">Username</p>
            <p className="mt-0.5 font-mono text-sm text-slate-200">{profile.username}</p>
          </div>
          <div className="p-5 sm:p-6">
            <UserInfoForm
              initial={{
                username: profile.username,
                nameSurname: profile.nameSurname,
                email: profile.email,
                gender: profile.gender,
                birthdate: profile.birthdate,
                phone: profile.phone,
              }}
            />
          </div>
        </CardBody>
      </Card>
    </div>
  );
}
