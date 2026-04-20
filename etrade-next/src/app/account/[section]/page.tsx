import Link from "next/link";

import { requireAuth } from "@/lib/requireAuth";
import { Card, CardBody } from "@/components/ui/Card";
import { ChangePasswordForm } from "../user-info/ChangePasswordForm";

export const runtime = "nodejs";

const LABELS: Record<string, string> = {
  reviews: "My Reviews",
  messages: "Seller Messages",
  credits: "Credits",
  raffle: "Lucky Draw",
  coupons: "Discount Coupons",
  "user-info": "User Info",
  cards: "Saved Cards",
  notifications: "Notification Preferences",
  password: "Change Password",
  plus: "TradeHub Plus",
  elite: "TradeHub Elite",
  assistant: "TradeHub Assistant",
};

export default async function AccountSectionPage({ params }: { params: Promise<{ section: string }> }) {
  await requireAuth();
  const p = await params;
  const key = p.section;
  const title = LABELS[key] || "My Account";

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-3">
        <h1 className="text-2xl font-extrabold">{title}</h1>
        <Link className="text-sm text-slate-400 hover:text-slate-200" href="/account">
          ← Back to account
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
          ) : (
            <div className="text-slate-300">This section is coming soon.</div>
          )}
        </CardBody>
      </Card>
    </div>
  );
}

