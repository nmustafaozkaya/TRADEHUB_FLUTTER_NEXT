export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { listBestSellers } from "@/lib/repos/dashboard";
import { listItems } from "@/lib/repos/items";
import { listReviewSummariesByItemIds } from "@/lib/repos/reviews";

function readSort(value: string | null): "newest" | "price_asc" | "price_desc" | "name_asc" {
  if (value === "price_asc" || value === "price_desc" || value === "name_asc") return value;
  return "newest";
}

export async function GET(req: Request) {
  const url = new URL(req.url);

  const q = url.searchParams.get("q") || undefined;
  const brand = url.searchParams.get("brand") || undefined;
  const category = url.searchParams.get("category") || undefined;
  const sort = readSort(url.searchParams.get("sort"));
  const page = Number(url.searchParams.get("page") || 1);
  const pageSize = Math.min(10000, Math.max(1, Number(url.searchParams.get("pageSize") || 20)));

  const isBestsellerBrowse =
    !!category && category.trim().toLowerCase() === "bestseller";

  if (isBestsellerBrowse) {
    const limit = Math.min(100, pageSize);
    const rows = await listBestSellers(limit);
    const reviewMap = await listReviewSummariesByItemIds(rows.map((x) => Number(x.ID)));
    const items = rows.map((it) => {
      const review = reviewMap[Number(it.ID)] ?? { averageRating: 0, totalReviews: 0 };
      return {
        ...it,
        AVG_RATING: review.averageRating,
        TOTAL_REVIEWS: review.totalReviews,
      };
    });
    return NextResponse.json({
      ok: true,
      items,
      total: items.length,
      page: 1,
      pageSize: items.length,
    });
  }

  const result = await listItems({
    q,
    brand,
    category,
    sort,
    page,
    pageSize,
  });

  const reviewMap = await listReviewSummariesByItemIds(result.items.map((x) => Number(x.ID)));
  const items = result.items.map((it) => {
    const review = reviewMap[Number(it.ID)] ?? { averageRating: 0, totalReviews: 0 };
    return {
      ...it,
      AVG_RATING: review.averageRating,
      TOTAL_REVIEWS: review.totalReviews,
    };
  });

  return NextResponse.json({
    ok: true,
    ...result,
    items,
  });
}
