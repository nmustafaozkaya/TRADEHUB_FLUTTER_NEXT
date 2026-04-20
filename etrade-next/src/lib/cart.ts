import { cookies } from "next/headers";
import { decodeJsonCookie, encodeJsonCookie } from "./session";

export type CartLine = {
  itemId: number;
  name: string;
  unitPrice: number;
  qty: number;
  protection?: {
    years: 1 | 2 | 3;
    price: number;
  } | null;
};

export type Cart = {
  lines: CartLine[];
};

const CART_COOKIE = "etrade_cart";

function normalizeCart(cart: Cart): Cart {
  const lines = Array.isArray(cart.lines) ? cart.lines : [];
  const cleaned = lines
    .map((l) => ({
      itemId: Number(l.itemId),
      name: String(l.name ?? ""),
      unitPrice: Number(l.unitPrice ?? 0),
      qty: Math.max(0, Number(l.qty ?? 0)),
      protection:
        l.protection &&
        (Number(l.protection.years) === 1 ||
          Number(l.protection.years) === 2 ||
          Number(l.protection.years) === 3)
          ? {
              years: Number(l.protection.years) as 1 | 2 | 3,
              price: Math.max(0, Number(l.protection.price ?? 0)),
            }
          : null,
    }))
    .filter((l) => Number.isFinite(l.itemId) && l.itemId > 0 && l.qty > 0);

  return { lines: cleaned };
}

export async function getCart(): Promise<Cart> {
  const store = await cookies();
  const raw = store.get(CART_COOKIE)?.value;
  const decoded = decodeJsonCookie<Cart>(raw);
  return normalizeCart(decoded ?? { lines: [] });
}

export async function setCart(cart: Cart) {
  const normalized = normalizeCart(cart);
  const store = await cookies();
  store.set(CART_COOKIE, encodeJsonCookie(normalized), {
    httpOnly: true,
    sameSite: "lax",
    path: "/",
  });
}

export async function clearCart() {
  const store = await cookies();
  store.set(CART_COOKIE, "", { httpOnly: true, sameSite: "lax", path: "/", maxAge: 0 });
}

export function cartCount(cart: Cart) {
  return cart.lines.reduce((sum, l) => sum + l.qty, 0);
}

export function cartTotal(cart: Cart) {
  return cart.lines.reduce((sum, l) => {
    const protectionPrice = l.protection ? Number(l.protection.price ?? 0) : 0;
    return sum + (l.unitPrice + protectionPrice) * l.qty;
  }, 0);
}

export async function addToCart(line: Omit<CartLine, "qty"> & { qty?: number }) {
  const cart = await getCart();
  const qty = Math.max(1, Number(line.qty ?? 1));
  const itemId = Number(line.itemId);
  const existing = cart.lines.find((l) => l.itemId === itemId);
  if (existing) {
    existing.qty += qty;
  } else {
    cart.lines.push({
      itemId,
      name: String(line.name),
      unitPrice: Number(line.unitPrice ?? 0),
      qty,
      protection: null,
    });
  }
  await setCart(cart);
  return cart;
}

export async function updateCartQty(itemId: number, qty: number) {
  const cart = await getCart();
  const id = Number(itemId);
  const nextQty = Math.max(0, Number(qty));
  cart.lines = cart.lines
    .map((l) => (l.itemId === id ? { ...l, qty: nextQty } : l))
    .filter((l) => l.qty > 0);
  await setCart(cart);
  return cart;
}

export async function removeFromCart(itemId: number) {
  const cart = await getCart();
  const id = Number(itemId);
  cart.lines = cart.lines.filter((l) => l.itemId !== id);
  await setCart(cart);
  return cart;
}

export async function setCartLineProtection(
  itemId: number,
  protection: { years: 1 | 2 | 3; price: number } | null
) {
  const cart = await getCart();
  const id = Number(itemId);
  const line = cart.lines.find((l) => l.itemId === id);
  if (!line) return cart;

  line.protection = protection
    ? {
        years: protection.years,
        price: Math.max(0, Number(protection.price ?? 0)),
      }
    : null;

  await setCart(cart);
  return cart;
}

export { CART_COOKIE };

