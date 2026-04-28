export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { getUser } from "@/lib/auth";
import { findUserByLogin } from "@/lib/repos/users";
import {
  deactivateSavedCardForUser,
  listSavedCardsForUser,
  saveCardForUser,
} from "@/lib/repos/cards";

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
  const cards = await listSavedCardsForUser(userId);
  return NextResponse.json({ ok: true, cards });
}

export async function POST(req: Request) {
  const userId = await resolveUserId(req);
  if (!userId) {
    return NextResponse.json({ ok: false, error: "Authentication required." }, { status: 401 });
  }
  const body = (await req.json().catch(() => null)) as null | {
    cardNumber?: string;
    cardHolder?: string;
    expMonth?: number | string;
    expYear?: number | string;
  };

  const cardNumber = String(body?.cardNumber || "").replace(/\D/g, "");
  const cardHolder = String(body?.cardHolder || "").trim();
  const expMonth = Number(body?.expMonth || 0);
  const expYear = Number(body?.expYear || 0);
  if (cardNumber.length < 12) {
    return new NextResponse("Invalid card number.", { status: 400 });
  }
  if (!cardHolder) {
    return new NextResponse("Card holder is required.", { status: 400 });
  }
  if (!Number.isFinite(expMonth) || expMonth < 1 || expMonth > 12) {
    return new NextResponse("Invalid expMonth.", { status: 400 });
  }
  if (!Number.isFinite(expYear) || expYear < 2000) {
    return new NextResponse("Invalid expYear.", { status: 400 });
  }

  await saveCardForUser({
    userId,
    cardHolder,
    cardNumber,
    expMonth,
    expYear,
  });
  return NextResponse.json({ ok: true });
}

export async function DELETE(req: Request) {
  const userId = await resolveUserId(req);
  if (!userId) {
    return NextResponse.json({ ok: false, error: "Authentication required." }, { status: 401 });
  }
  const url = new URL(req.url);
  const cardId = Number(url.searchParams.get("id") || 0);
  if (!cardId) return new NextResponse("id required", { status: 400 });

  await deactivateSavedCardForUser(userId, cardId);
  return NextResponse.json({ ok: true });
}
