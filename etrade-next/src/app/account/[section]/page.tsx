import Link from "next/link";

import { requireAuth } from "@/lib/requireAuth";
import { Card, CardBody } from "@/components/ui/Card";
import { ChangePasswordForm } from "../user-info/ChangePasswordForm";
import { listReviewsForUser } from "@/lib/repos/reviews";

export const runtime = "nodejs";

const LABELS: Record<string, string> = {
  reviews: "My Reviews",
  messages: "Seller Messages",
  credits: "Credits",
  raffle: "Lucky Draw",
  coupons: "Discount Coupons",
  "user-info": "Profile",
  cards: "Saved Cards",
  password: "Change Password",
  plus: "TradeHub Plus",
  elite: "TradeHub Elite",
  assistant: "TradeHub Assistant",
};

export default async function AccountSectionPage({ params }: { params: Promise<{ section: string }> }) {
  const user = await requireAuth();
  const p = await params;
  const key = p.section;
  const title = LABELS[key] || "My Account";
  const reviews = key === "reviews" ? await listReviewsForUser(user.id) : [];

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-3">
        <h1 className="text-2xl font-extrabold">{title}</h1>
        <Link className="text-sm text-slate-400 transition hover:text-sky-300" href="/account">
          ← Account
        </Link>
      </div>

      <Card>
        <CardBody>
          {key === "password" ? (
            <div className="space-y-4">
              <p className="text-sm text-slate-400">
                Enter your current password, then set and confirm your new password.
              </p>
              <ChangePasswordForm />
            </div>
          ) : key === "reviews" ? (
            <div className="space-y-3">
              <div className="rounded-xl border border-white/10 bg-white/[0.03] p-3">
                <div className="text-xs text-slate-400">Signed account</div>
                <div className="mt-1 text-sm font-semibold text-slate-100">
                  {(user.nameSurname || user.username || "Member").trim()}
                </div>
                <div className="text-xs text-slate-500">User ID: {user.id}</div>
              </div>

              {!reviews.length ? (
                <div className="text-slate-300">No reviews yet for this account.</div>
              ) : (
                <div className="space-y-2">
                  {reviews.map((r) => (
                    <article key={r.id} className="rounded-xl border border-white/10 bg-white/[0.03] p-3">
                      <div className="flex items-center justify-between gap-2">
                        <Link href={`/items/${r.itemId}`} className="text-sm font-semibold text-slate-100 hover:underline">
                          {r.itemName}
                        </Link>
                        <span className="text-xs text-slate-400">{r.createdAt ? new Date(r.createdAt).toLocaleDateString("en-US") : "-"}</span>
                      </div>
                      <div className="mt-1 text-xs text-slate-400">
                        Order #{r.orderId} · Item #{r.itemId}
                        {r.brand ? ` · ${r.brand}` : ""}
                      </div>
                      <div className="mt-1 text-sm text-amber-300">{"★".repeat(Math.max(0, Math.min(5, r.rating)))}<span className="ml-1 text-slate-400">({r.rating}/5)</span></div>
                      <div className="mt-1 text-sm text-slate-200">{r.comment || "No comment."}</div>
                    </article>
                  ))}
                </div>
              )}
            </div>
          ) : (
            <div className="text-slate-300">This section is coming soon.</div>
          )}
        </CardBody>
      </Card>
    </div>
  );
}

