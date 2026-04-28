import { cookies } from "next/headers";
import { decodeJsonCookie, encodeJsonCookie } from "./session";
import { getUser } from "./auth";
import { listFavoriteItemIdsForUser, toggleFavoriteForUser } from "./repos/favorites";

export type Favorites = { ids: number[] };

const FAV_COOKIE = "tradehub_favs";

function normalizeFavs(f: Favorites): Favorites {
  const ids = Array.isArray(f.ids) ? f.ids : [];
  const cleaned = ids
    .map((x) => Number(x))
    .filter((n) => Number.isFinite(n) && n > 0);
  const uniq: number[] = [];
  for (const id of cleaned) {
    if (!uniq.includes(id)) uniq.push(id);
  }
  return { ids: uniq };
}

export async function getFavorites(): Promise<Favorites> {
  const user = await getUser();
  if (user?.id) {
    const ids = await listFavoriteItemIdsForUser(user.id);
    return normalizeFavs({ ids });
  }
  const store = await cookies();
  const raw = store.get(FAV_COOKIE)?.value;
  const decoded = decodeJsonCookie<Favorites>(raw);
  return normalizeFavs(decoded ?? { ids: [] });
}

export async function setFavorites(favs: Favorites) {
  const store = await cookies();
  store.set(FAV_COOKIE, encodeJsonCookie(normalizeFavs(favs)), {
    httpOnly: true,
    sameSite: "lax",
    path: "/",
  });
}

export async function toggleFavorite(itemId: number) {
  const user = await getUser();
  if (user?.id) {
    const ids = await toggleFavoriteForUser(user.id, Number(itemId));
    return normalizeFavs({ ids });
  }
  const favs = await getFavorites();
  const id = Number(itemId);
  if (favs.ids.includes(id)) favs.ids = favs.ids.filter((x) => x !== id);
  else favs.ids.unshift(id);
  await setFavorites(favs);
  return favs;
}

export async function clearFavorites() {
  const store = await cookies();
  store.set(FAV_COOKIE, "", { httpOnly: true, sameSite: "lax", path: "/", maxAge: 0 });
}

export function favoritesCount(f: Favorites) {
  return (f.ids || []).length;
}

export { FAV_COOKIE };

