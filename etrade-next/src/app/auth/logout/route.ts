export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { cookies } from "next/headers";

import { USER_COOKIE } from "@/lib/auth";

async function clearAuthCookie() {
  const store = await cookies();
  store.set(USER_COOKIE, "", {
    httpOnly: true,
    sameSite: "lax",
    path: "/",
    maxAge: 0,
    expires: new Date(0),
  });
}

export async function GET(req: Request) {
  await clearAuthCookie();
  return NextResponse.redirect(new URL("/items", req.url));
}

export async function POST() {
  await clearAuthCookie();
  return NextResponse.json({ ok: true });
}

