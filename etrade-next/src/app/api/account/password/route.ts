export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { getUser } from "@/lib/auth";
import { findUserByLogin } from "@/lib/repos/users";
import { changeUserPasswordById } from "@/lib/repos/users";

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

export async function POST(req: Request) {
  const userId = await resolveUserId(req);
  if (!userId) {
    return NextResponse.json({ ok: false, error: "Authentication required." }, { status: 401 });
  }

  const body = (await req.json().catch(() => null)) as
    | { oldPassword?: string; newPassword?: string; confirmPassword?: string }
    | null;

  const oldPassword = String(body?.oldPassword ?? "");
  const newPassword = String(body?.newPassword ?? "");
  const confirmPassword = String(body?.confirmPassword ?? "");

  if (!oldPassword) return NextResponse.json({ ok: false, error: "Current password is required." }, { status: 400 });
  if (!newPassword) return NextResponse.json({ ok: false, error: "New password is required." }, { status: 400 });
  if (newPassword.length > 50) {
    return NextResponse.json({ ok: false, error: "New password must be at most 50 characters." }, { status: 400 });
  }
  if (newPassword !== confirmPassword) {
    return NextResponse.json({ ok: false, error: "New passwords do not match." }, { status: 400 });
  }
  if (oldPassword === newPassword) {
    return NextResponse.json(
      { ok: false, error: "New password must be different from current password." },
      { status: 400 }
    );
  }

  const updated = await changeUserPasswordById(userId, oldPassword, newPassword);
  if (!updated) {
    return NextResponse.json({ ok: false, error: "Current password is incorrect." }, { status: 400 });
  }

  return NextResponse.json({ ok: true, message: "Your password has been updated." });
}

