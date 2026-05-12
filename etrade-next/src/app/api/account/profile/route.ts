export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { getUser } from "@/lib/auth";
import { findUserByLogin, updateUserProfileById } from "@/lib/repos/users";

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

/** Align mobile app labels with web `UserInfoForm` values stored in dbo.USERS.GENDER. */
function normalizeGenderForDb(raw: string): string {
  const t = raw.trim();
  if (!t) return "";
  const lower = t.toLowerCase();
  if (t === "M" || t === "F" || t === "O") return t;
  if (lower === "male" || lower === "erkek") return "M";
  if (lower === "female" || lower === "kadın" || lower === "kadin") return "F";
  if (lower === "other" || lower === "diğer" || lower === "diger") return "O";
  return t.slice(0, 1).toUpperCase();
}

export async function PUT(req: Request) {
  const userId = await resolveUserId(req);
  if (!userId) {
    return NextResponse.json({ ok: false, error: "Authentication required." }, { status: 401 });
  }

  const body = (await req.json().catch(() => null)) as null | {
    nameSurname?: string;
    email?: string;
    gender?: string;
    birthdate?: string;
    phone?: string;
  };

  const nameSurname = String(body?.nameSurname ?? "").trim();
  const email = String(body?.email ?? "").trim();
  const phone = String(body?.phone ?? "").trim();
  const birthdate = String(body?.birthdate ?? "").trim();
  const gender = normalizeGenderForDb(String(body?.gender ?? ""));

  if (!nameSurname) {
    return NextResponse.json({ ok: false, error: "Full name is required." }, { status: 400 });
  }
  if (email && !email.includes("@")) {
    return NextResponse.json({ ok: false, error: "Please enter a valid email." }, { status: 400 });
  }

  const updated = await updateUserProfileById(userId, {
    nameSurname,
    email,
    gender,
    birthdate,
    phone,
  });

  if (!updated) {
    return NextResponse.json({ ok: false, error: "Could not update your profile." }, { status: 500 });
  }

  return NextResponse.json({
    ok: true,
    user: {
      id: updated.id,
      username: updated.username,
      nameSurname: updated.nameSurname,
      email: updated.email,
    },
  });
}
