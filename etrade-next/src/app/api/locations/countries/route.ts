export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { listCountries } from "@/lib/repos/locations";

export async function GET() {
  const rows = await listCountries();
  return NextResponse.json(rows);
}

