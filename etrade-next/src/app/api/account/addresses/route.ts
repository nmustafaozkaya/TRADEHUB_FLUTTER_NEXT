export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { getUser } from "@/lib/auth";
import { findUserByLogin } from "@/lib/repos/users";
import {
  createAddressForUser,
  deleteAddressForUser,
  listAddressesForUser,
} from "@/lib/repos/addresses";

async function resolveUserId(req: Request): Promise<number | null> {
  const sessionUser = await getUser();
  if (sessionUser?.id) return Number(sessionUser.id);
  const fromHeader = Number(req.headers.get("x-user-id") || 0);
  if (Number.isFinite(fromHeader) && fromHeader > 0) return fromHeader;
  const login = (req.headers.get("x-username") || "").trim();
  if (!login) return null;
  const user = await findUserByLogin(login);
  return user?.ID ? Number(user.ID) : null;
}

export async function GET(req: Request) {
  const userId = await resolveUserId(req);
  if (!userId) {
    return NextResponse.json({ ok: false, error: "Authentication required." }, { status: 401 });
  }
  const rows = await listAddressesForUser(userId);
  const addresses = rows.map((r) => {
    const parts = [r.District, r.Town, r.City, r.Country].filter(Boolean);
    const locationText = parts.join(" / ");
    return {
      id: Number(r.ID),
      title: locationText || "Address",
      addressText: r.AddressText || "",
      postalCode: r.PostalCode || "",
    };
  });
  return NextResponse.json({ ok: true, addresses });
}

export async function POST(req: Request) {
  const userId = await resolveUserId(req);
  if (!userId) {
    return NextResponse.json({ ok: false, error: "Authentication required." }, { status: 401 });
  }
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
    userId,
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
  const userId = await resolveUserId(req);
  if (!userId) {
    return NextResponse.json({ ok: false, error: "Authentication required." }, { status: 401 });
  }
  const url = new URL(req.url);
  const addressId = Number(url.searchParams.get("id") || 0);
  if (!addressId) return new NextResponse("id required", { status: 400 });

  const deleted = await deleteAddressForUser(userId, addressId);
  if (!deleted) return new NextResponse("Address not found.", { status: 404 });
  return NextResponse.json({ ok: true });
}

