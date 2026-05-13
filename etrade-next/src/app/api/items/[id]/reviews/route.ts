import { NextResponse } from "next/server";

import { getItemReviewSummary, listItemReviews, createReviewForPurchasedItem } from "@/lib/repos/reviews";
import { getUser } from "@/lib/auth";
import { findUserByLogin } from "@/lib/repos/users";

export const runtime = "nodejs";

async function resolveUserId(req: Request): Promise<number | null> {
  const sessionUser = await getUser();
  if (sessionUser?.id) return Number(sessionUser.id);
  const fromHeader = Number(req.headers.get("x-user-id") || 0);
  if (Number.isFinite(fromHeader) && fromHeader > 0) return fromHeader;
  const login = (req.headers.get("x-username") || "").trim();
  if (!login) return null;
  const user = await findUserByLogin(login);
  return user?.ID ? Number(user.ID) : null;
}

export async function GET(req: Request, ctx: { params: Promise<{ id: string }> }) {
  try {
    const p = await ctx.params;
    const itemId = Number(p.id);
    if (!itemId) {
      return NextResponse.json({ error: "Invalid item id." }, { status: 400 });
    }

    const url = new URL(req.url);
    const limit = Number(url.searchParams.get("limit") || 10);

    const [summary, reviews] = await Promise.all([
      getItemReviewSummary(itemId),
      listItemReviews(itemId, limit),
    ]);

    return NextResponse.json({
      itemId,
      averageRating: summary.averageRating,
      totalReviews: summary.totalReviews,
      reviews,
    });
  } catch {
    return NextResponse.json({ error: "Could not load reviews." }, { status: 500 });
  }
}

export async function POST(req: Request, ctx: { params: Promise<{ id: string }> }) {
  try {
    const userId = await resolveUserId(req);
    if (!userId) {
      return NextResponse.json({ ok: false, error: "Authentication required." }, { status: 401 });
    }

    const p = await ctx.params;
    const itemId = Number(p.id);
    if (!itemId) {
      return NextResponse.json({ ok: false, error: "Invalid item id." }, { status: 400 });
    }

    const body = (await req.json().catch(() => null)) as { rating?: number; comment?: string } | null;
    const rating = Number(body?.rating ?? 0);
    const comment = String(body?.comment ?? "").trim();

    const created = await createReviewForPurchasedItem({
      userId,
      itemId,
      rating,
      comment,
    });

    if (!created.ok) {
      if (created.reason === "not_purchased") {
        return NextResponse.json(
          { ok: false, error: "You can review this item after a successful purchase." },
          { status: 403 }
        );
      }
      return NextResponse.json({ ok: false, error: "Invalid review payload." }, { status: 400 });
    }

    return NextResponse.json({ ok: true, mode: created.mode });
  } catch {
    return NextResponse.json({ ok: false, error: "Could not create review." }, { status: 500 });
  }
}

