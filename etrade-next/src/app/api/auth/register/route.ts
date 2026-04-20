export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { createUser, findUserByUsername } from "@/lib/repos/users";
import { setUser } from "@/lib/auth";

type RegisterBody = {
  username?: string;
  password?: string;
  nameSurname?: string;
  email?: string;
  gender?: string;
  birthdate?: string;
  phone?: string;
  telnr1?: string;
};

export async function POST(req: Request) {
  const body = (await req.json().catch(() => null)) as RegisterBody | null;
  const username = String(body?.username || "").trim();
  const password = String(body?.password || "");
  const nameSurname = String(body?.nameSurname || "").trim() || null;
  const email = String(body?.email || "").trim() || null;
  const gender = String(body?.gender || "").trim() || null;
  const birthdate = String(body?.birthdate || "").trim() || null;
  const phone = String(body?.phone || body?.telnr1 || "").trim() || null;

  if (!username || !password) {
    return NextResponse.json(
      { ok: false, error: "username and password are required." },
      { status: 400 }
    );
  }
  if (password.length > 50) {
    return NextResponse.json(
      { ok: false, error: "Password must be at most 50 characters." },
      { status: 400 }
    );
  }
  if (!gender || !birthdate || !phone) {
    return NextResponse.json(
      { ok: false, error: "gender, birthdate and phone are required." },
      { status: 400 }
    );
  }

  const existing = await findUserByUsername(username);
  if (existing) {
    return NextResponse.json(
      { ok: false, error: "This username is already taken." },
      { status: 409 }
    );
  }

  const id = await createUser({
    username,
    password,
    nameSurname,
    email,
    gender,
    birthdate,
    phone,
  });

  await setUser({
    id,
    username,
    nameSurname,
  });

  return NextResponse.json({
    ok: true,
    user: {
      id,
      username,
      nameSurname,
      email,
    },
  });
}
