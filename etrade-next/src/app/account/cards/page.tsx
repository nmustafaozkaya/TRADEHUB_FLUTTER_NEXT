import Link from "next/link";

import { Card, CardBody } from "@/components/ui/Card";
import { requireAuth } from "@/lib/requireAuth";
import { listSavedCardsForUser } from "@/lib/repos/cards";
import { removeSavedCardAction } from "./actions";

export const runtime = "nodejs";

export default async function CardsPage() {
  const user = await requireAuth();
  const cards = await listSavedCardsForUser(user.id);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-3">
        <h1 className="text-2xl font-extrabold">My Cards</h1>
        <Link className="text-sm text-slate-400 hover:text-slate-200" href="/account">
          ← Back to account
        </Link>
      </div>

      {!cards.length ? (
        <Card>
          <CardBody>
            <div className="text-slate-300">No saved cards yet. Save a card during checkout.</div>
          </CardBody>
        </Card>
      ) : (
        <div className="grid gap-3 md:grid-cols-2">
          {cards.map((c) => (
            <Card key={c.id}>
              <CardBody>
                <div className="text-xs uppercase tracking-wide text-slate-400">{c.brand}</div>
                <div className="mt-1 text-lg font-bold text-slate-100">**** **** **** {c.last4}</div>
                <div className="mt-1 text-sm text-slate-300">{c.cardHolder || "Card holder"}</div>
                <div className="mt-1 text-xs text-slate-400">
                  Exp: {String(c.expMonth).padStart(2, "0")}/{String(c.expYear).slice(-2)}
                </div>
                <form action={removeSavedCardAction} className="mt-4">
                  <input type="hidden" name="cardId" value={c.id} />
                  <button className="rounded-xl border border-rose-400/25 bg-rose-400/10 px-3 py-2 text-sm font-semibold text-rose-100 hover:bg-rose-400/15">
                    Remove card
                  </button>
                </form>
              </CardBody>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
