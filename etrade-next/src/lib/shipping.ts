export const SHIPPING_FREE_THRESHOLD = 300;
export const SHIPPING_STANDARD_FEE = 100;

export function shippingFee(subtotal: number) {
  const s = Number(subtotal) || 0;
  return s >= SHIPPING_FREE_THRESHOLD ? 0 : SHIPPING_STANDARD_FEE;
}

export function orderTotal(subtotal: number) {
  const ship = shippingFee(subtotal);
  return Number(subtotal || 0) + ship;
}

