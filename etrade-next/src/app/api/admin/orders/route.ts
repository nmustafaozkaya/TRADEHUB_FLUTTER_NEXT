export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { listOrdersForAdmin } from "@/lib/repos/adminOrders";

export async function GET(req: Request) {
  const url = new URL(req.url);
  const page = Number(url.searchParams.get("page") || 1);
  const pageSize = Number(url.searchParams.get("pageSize") || 20);
  const result = await listOrdersForAdmin({ page, pageSize });
  return NextResponse.json({ ok: true, ...result });
}

