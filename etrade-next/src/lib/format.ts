export function tryNumber(v: unknown) {
  const n = Number(v);
  return Number.isFinite(n) ? n : 0;
}

export function formatTry(amount: number) {
  try {
    return new Intl.NumberFormat("en-US", { style: "currency", currency: "TRY" }).format(amount);
  } catch {
    return `${amount.toFixed(2)} ₺`;
  }
}

