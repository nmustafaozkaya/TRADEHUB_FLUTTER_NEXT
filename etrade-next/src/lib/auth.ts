import { cookies } from "next/headers";
import { decodeJsonCookie, encodeJsonCookie } from "./session";

export type SessionUser = {
  id: number;
  username: string;
  nameSurname?: string | null;
};

const USER_COOKIE = "etrade_user";

export async function getUser(): Promise<SessionUser | null> {
  const store = await cookies();
  const raw = store.get(USER_COOKIE)?.value;
  const decoded = decodeJsonCookie<unknown>(raw);
  if (!decoded || typeof decoded !== "object") return null;

  const obj = decoded as Record<string, unknown>;
  const id = Number(obj.id);
  const username = typeof obj.username === "string" ? obj.username : "";
  const nameSurname = typeof obj.nameSurname === "string" ? obj.nameSurname : null;
  if (!Number.isFinite(id) || id <= 0 || !username) return null;
  return {
    id,
    username,
    nameSurname,
  };
}

export async function setUser(user: SessionUser) {
  const store = await cookies();
  store.set(USER_COOKIE, encodeJsonCookie(user), {
    httpOnly: true,
    sameSite: "lax",
    path: "/",
  });
}

export async function clearUser() {
  const store = await cookies();
  store.set(USER_COOKIE, "", { httpOnly: true, sameSite: "lax", path: "/", maxAge: 0 });
}

export { USER_COOKIE };

