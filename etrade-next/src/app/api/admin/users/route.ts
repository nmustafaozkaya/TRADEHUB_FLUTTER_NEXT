export const runtime = "nodejs";

import { NextResponse } from "next/server";
import { listUsersForAdmin } from "@/lib/repos/users";

export async function GET() {
  const users = await listUsersForAdmin();
  return NextResponse.json({ ok: true, users });
}

