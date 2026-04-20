export function shippingFee(subtotal: number) {
  const s = Number(subtotal) || 0;
  return s >= 300 ? 0 : 100;
}

export function orderTotal(subtotal: number) {
  const ship = shippingFee(subtotal);
  return Number(subtotal || 0) + ship;
}

