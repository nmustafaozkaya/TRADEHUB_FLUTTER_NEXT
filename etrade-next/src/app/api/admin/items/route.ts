export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { listItems, createItemForAdmin, getItemCatalogStats } from "@/lib/repos/items";

type CreateItemBody = {
  itemCode?: string;
  itemName?: string;
  unitPrice?: number;
  brand?: string;
  category1?: string;
  imageUrl?: string;
};

export async function GET() {
  const result = await listItems({ page: 1, pageSize: 50, sort: "newest" });
  const stats = await getItemCatalogStats();
  return NextResponse.json({
    ok: true,
    items: result.items,
    activeTotal: result.total,
    totalItems: stats.totalItems,
    activeItems: stats.activeItems,
  });
}

export async function POST(req: Request) {
  const body = (await req.json().catch(() => null)) as CreateItemBody | null;
  const itemCode = String(body?.itemCode || "").trim();
  const itemName = String(body?.itemName || "").trim();
  const unitPrice = Number(body?.unitPrice ?? 0);

  if (!itemCode || !itemName || !Number.isFinite(unitPrice) || unitPrice <= 0) {
    return NextResponse.json(
      { ok: false, error: "itemCode, itemName and unitPrice are required." },
      { status: 400 }
    );
  }

  try {
    const id = await createItemForAdmin({
      itemCode,
      itemName,
      unitPrice,
      brand: body?.brand ?? null,
      category1: body?.category1 ?? null,
      imageUrl: body?.imageUrl ?? null,
    });
    return NextResponse.json({ ok: true, id });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Could not create item.";
    return NextResponse.json({ ok: false, error: message }, { status: 400 });
  }
}

