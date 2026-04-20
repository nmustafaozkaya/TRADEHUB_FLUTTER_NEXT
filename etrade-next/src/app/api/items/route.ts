export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { listItems } from "@/lib/repos/items";

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
  const pageSize = Number(url.searchParams.get("pageSize") || 20);

  const result = await listItems({
    q,
    brand,
    category,
    sort,
    page,
    pageSize,
  });

  return NextResponse.json({
    ok: true,
    ...result,
  });
}
