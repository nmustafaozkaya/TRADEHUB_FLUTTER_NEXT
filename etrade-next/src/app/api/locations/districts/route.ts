export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { listDistricts } from "@/lib/repos/locations";

export async function GET(req: Request) {
  const url = new URL(req.url);
  const townId = Number(url.searchParams.get("townId") || 0);
  if (!townId) return NextResponse.json([], { status: 200 });
  const rows = await listDistricts(townId);
  return NextResponse.json(rows);
}

