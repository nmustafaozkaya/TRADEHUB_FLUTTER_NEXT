/**
 * MVP "TradeHub Protection" pricing rules.
 *
 * This is intentionally heuristic: real warranties depend on merchant policy, SKU, and region.
 * For grocery / tobacco-like categories we return no offers (UI should hide the add-on block).
 */

export type ExtendedWarrantyOffer = {
  years: 1 | 2 | 3;
  price: number;
};

export type ExtendedWarrantyPlan = {
  title: string;
  subtitle: string;
  offers: ExtendedWarrantyOffer[];
};

function norm(s: string | null | undefined) {
  return (s || "").trim().toLowerCase();
}

function haystackFromCategories(cats: Array<string | null | undefined>) {
  return cats.map(norm).filter(Boolean).join(" | ");
}

type WarrantyKind = "none" | "electronics" | "home_general" | "beauty" | "baby";

function classifyWarrantyKind(cats: Array<string | null | undefined>): WarrantyKind {
  const h = haystackFromCategories(cats);

  // Non-warranty / not meaningful for extended service plans in this MVP
  if (
    h.includes("fresh ") ||
    h.includes("produce") ||
    h.includes("vegetable") ||
    h.includes("fruit") ||
    h.includes("greens") ||
    h.includes("meat") ||
    h.includes("poultry") ||
    h.includes("deli") ||
    h.includes("seafood") ||
    h.includes("bakery") ||
    h.includes("grocery") ||
    h.includes("pantry") ||
    h.includes("spice") ||
    h.includes("candy") ||
    h.includes("sweet") ||
    h.includes("chocolate") ||
    h.includes("snack") ||
    h.includes("beverage") ||
    h.includes("drink") ||
    h.includes("coffee") ||
    h.includes("tea") ||
    h.includes("dairy") ||
    h.includes("egg") ||
    h.includes("frozen") ||
    h.includes("cigarette") ||
    h.includes("tobacco")
  ) {
    return "none";
  }

  if (h.includes("electronic") || h.includes("battery") || h.includes("power bank")) return "electronics";
  if (h.includes("cosmetic") || h.includes("beauty") || h.includes("oral care") || h.includes("hair")) return "beauty";
  if (h.includes("baby")) return "baby";

  // Default bucket for household / cleaning / toys / textiles / kitchen etc.
  return "home_general";
}

function roundTry(n: number) {
  // Keep prices in whole TRY for this MVP UI.
  return Math.max(0, Math.round(n));
}

function buildOffers(unitPrice: number, multipliers: [number, number, number]): ExtendedWarrantyOffer[] {
  const p = Number(unitPrice);
  if (!Number.isFinite(p) || p <= 0) return [];

  const [m1, m2, m3] = multipliers;
  const offers: ExtendedWarrantyOffer[] = [
    { years: 1, price: roundTry(p * m1) },
    { years: 2, price: roundTry(p * m2) },
    { years: 3, price: roundTry(p * m3) },
  ];

  // Ensure strictly increasing tiers (looks weird otherwise for tiny prices).
  if (offers[1].price <= offers[0].price) offers[1].price = offers[0].price + 1;
  if (offers[2].price <= offers[1].price) offers[2].price = offers[1].price + 1;

  return offers.filter((x) => x.price > 0);
}

export function buildExtendedWarrantyPlan(opts: {
  unitPrice: number;
  category1?: string | null;
  category2?: string | null;
  category3?: string | null;
  category4?: string | null;
}): ExtendedWarrantyPlan {
  const kind = classifyWarrantyKind([opts.category1, opts.category2, opts.category3, opts.category4]);

  if (kind === "none") {
    return {
      title: "TradeHub Protection",
      subtitle: "Not available for consumables in this MVP preview.",
      offers: [],
    };
  }

  if (kind === "electronics") {
    return {
      title: "TradeHub Protection",
      subtitle: "Electronics care plan (UI preview).",
      offers: buildOffers(opts.unitPrice, [0.1, 0.16, 0.22]),
    };
  }

  if (kind === "beauty") {
    return {
      title: "TradeHub Protection",
      subtitle: "Care coverage for eligible defects (UI preview).",
      offers: buildOffers(opts.unitPrice, [0.05, 0.09, 0.13]),
    };
  }

  if (kind === "baby") {
    return {
      title: "TradeHub Protection",
      subtitle: "Baby essentials support plan (UI preview).",
      offers: buildOffers(opts.unitPrice, [0.06, 0.11, 0.16]),
    };
  }

  return {
    title: "TradeHub Protection",
    subtitle: "Home essentials protection (UI preview).",
    offers: buildOffers(opts.unitPrice, [0.06, 0.1, 0.14]),
  };
}
