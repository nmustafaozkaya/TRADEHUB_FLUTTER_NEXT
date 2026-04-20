export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { requireAuth } from "@/lib/requireAuth";
import { createAddressForUser, deleteAddressForUser } from "@/lib/repos/addresses";

export async function POST(req: Request) {
  const user = await requireAuth();
  const body = (await req.json().catch(() => null)) as null | {
    countryId?: number;
    cityId?: number;
    townId?: number;
    districtId?: number;
    postalCode?: string | null;
    addressText?: string;
  };

  const countryId = Number(body?.countryId);
  const cityId = Number(body?.cityId);
  const townId = Number(body?.townId);
  const districtId = Number(body?.districtId);
  const postalCode = body?.postalCode ? String(body.postalCode) : null;
  const addressText = String(body?.addressText || "").trim();

  if (!countryId || !cityId || !townId || !districtId || addressText.length < 5) {
    return new NextResponse("Missing required fields.", { status: 400 });
  }

  await createAddressForUser({
    userId: user.id,
    countryId,
    cityId,
    townId,
    districtId,
    postalCode,
    addressText,
  });

  return NextResponse.json({ ok: true });
}

export async function DELETE(req: Request) {
  const user = await requireAuth();
  const url = new URL(req.url);
  const addressId = Number(url.searchParams.get("id") || 0);
  if (!addressId) return new NextResponse("id required", { status: 400 });

  const deleted = await deleteAddressForUser(user.id, addressId);
  if (!deleted) return new NextResponse("Address not found.", { status: 404 });
  return NextResponse.json({ ok: true });
}

