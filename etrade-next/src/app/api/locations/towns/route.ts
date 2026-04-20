export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { listTowns } from "@/lib/repos/locations";

export async function GET(req: Request) {
  const url = new URL(req.url);
  const cityId = Number(url.searchParams.get("cityId") || 0);
  if (!cityId) return NextResponse.json([], { status: 200 });
  const rows = await listTowns(cityId);
  return NextResponse.json(rows);
}

