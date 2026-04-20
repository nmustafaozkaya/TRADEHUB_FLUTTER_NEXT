export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { deactivateItemForAdmin } from "@/lib/repos/items";

export async function DELETE(_req: Request, ctx: { params: Promise<{ id: string }> }) {
  const params = await ctx.params;
  const id = Number(params.id);
  if (!Number.isFinite(id) || id <= 0) {
    return NextResponse.json({ ok: false, error: "Invalid item id." }, { status: 400 });
  }

  try {
    await deactivateItemForAdmin(id);
    return NextResponse.json({ ok: true });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Could not delete item.";
    return NextResponse.json({ ok: false, error: message }, { status: 400 });
  }
}

