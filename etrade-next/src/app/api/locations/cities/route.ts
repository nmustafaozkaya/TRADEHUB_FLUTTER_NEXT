export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { listCities } from "@/lib/repos/locations";

export async function GET(req: Request) {
  const url = new URL(req.url);
  const countryId = Number(url.searchParams.get("countryId") || 0);
  if (!countryId) return NextResponse.json([], { status: 200 });
  const rows = await listCities(countryId);
  return NextResponse.json(rows);
}

