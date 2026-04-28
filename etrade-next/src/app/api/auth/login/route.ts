export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { setUser } from "@/lib/auth";
import { findUserByLogin } from "@/lib/repos/users";

type LoginBody = {
  login?: string;
  username?: string;
  password?: string;
};

export async function POST(req: Request) {
  const body = (await req.json().catch(() => null)) as LoginBody | null;
  const login = String(body?.login || body?.username || "").trim();
  const password = String(body?.password || "");

  const plainOk = String(process.env.AUTH_PLAIN_OK || "true").toLowerCase() === "true";
  if (!plainOk) {
    return NextResponse.json({ ok: false, error: "AUTH_PLAIN_OK=false." }, { status: 503 });
  }

  if (!login || !password) {
    return NextResponse.json({ ok: false, error: "login and password are required." }, { status: 400 });
  }

  const user = await findUserByLogin(login);
  if (!user) {
    return NextResponse.json({ ok: false, error: "User not found." }, { status: 401 });
  }
  if ((user.PASSWORD_ || "") !== password) {
    return NextResponse.json({ ok: false, error: "Incorrect password." }, { status: 401 });
  }

  await setUser({
    id: user.ID,
    username: user.USERNAME_ || login,
    nameSurname: user.NAMESURNAME,
  });

  return NextResponse.json({
    ok: true,
    user: {
      id: user.ID,
      username: user.USERNAME_ || login,
      nameSurname: user.NAMESURNAME || null,
      email: user.EMAIL || null,
      gender: user.GENDER || null,
      birthdate: user.BIRTHDATE ? new Date(user.BIRTHDATE).toISOString().slice(0, 10) : null,
      phone: user.PHONE || null,
    },
  });
}
