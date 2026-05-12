/**
 * Canonical browse filters shared with the Flutter app (same labels, same DB bucket rules).
 * DB rows still store concrete CATEGORY1 strings; we expand one shop label to many DB values in SQL.
 */

export type ShopCategoryDefinition = {
  /** Shown in UI and in `?category=` (URL-encoded). */
  label: string;
  /** Exact CATEGORY1 values that belong to this bucket (case-insensitive match in TS helpers). */
  dbCategory1Values: readonly string[];
};

/** Eight browse buckets (2×4 / 4×2 grids on mobile + web); produce merged. */
export const SHOP_CATEGORIES: readonly ShopCategoryDefinition[] = [
  {
    label: "Fresh Produce",
    dbCategory1Values: [
      "Fresh Fruits",
      "Fresh Fruit",
      "Vegetables",
      "Fresh Vegetables",
      "Leafy Greens",
      "Fresh Greens",
    ],
  },
  {
    label: "Beauty & Personal Care",
    dbCategory1Values: ["Beauty & Personal Care", "Beauty", "Personal Care"],
  },
  {
    label: "Home & Living",
    dbCategory1Values: ["Home & Living", "Home", "Living", "Kitchen & Dining"],
  },
  {
    label: "Snacks & Confectionery",
    dbCategory1Values: ["Candy & Sweets", "Snacks", "Confectionery"],
  },
  {
    label: "Pantry & Staples",
    dbCategory1Values: ["Pantry & Spices", "Pantry & Staples", "Pantry", "Spices"],
  },
  {
    label: "Meat, Poultry & Seafood",
    dbCategory1Values: [
      "Poultry & Eggs",
      "Meat & Poultry",
      "Meat",
      "Seafood",
      "Deli",
    ],
  },
  {
    label: "Dairy, Cheese & Eggs",
    dbCategory1Values: ["Breakfast & Dairy", "Dairy & Eggs", "Dairy", "Cheese & Eggs"],
  },
  { label: "Toys & Games", dbCategory1Values: ["Toys & Games", "Toys", "Games"] },
] as const;

const norm = (s: string) => s.trim().toLowerCase();

function definitionForShopLabel(label: string): ShopCategoryDefinition | undefined {
  const n = norm(label);
  return SHOP_CATEGORIES.find((d) => norm(d.label) === n);
}

/**
 * Values to use in SQL `IN (...)` across CATEGORY1..4. Unknown labels fall back to a single exact value.
 */
export function expandCategoryToDbValues(categoryParam: string | null | undefined): string[] | null {
  const t = categoryParam?.trim();
  if (!t || norm(t) === "all") return null;

  const def = definitionForShopLabel(t);
  if (def) return [...def.dbCategory1Values];

  return [t];
}

export type CategoryFilterSql = { clause: string; params: Record<string, unknown> };

/**
 * SQL fragment for `WHERE ... AND (<clause>)` when filtering by shop or legacy category.
 */
export function buildCategorySqlFilter(categoryParam: string | null | undefined): CategoryFilterSql {
  const values = expandCategoryToDbValues(categoryParam);
  if (!values) {
    return { clause: "1=1", params: {} };
  }

  const keys = values.map((_, i) => `catv${i}`);
  const inList = keys.map((k) => `@${k}`).join(", ");
  const cols = ["CATEGORY1", "CATEGORY2", "CATEGORY3", "CATEGORY4"] as const;
  const orCols = cols.map((col) => `${col} IN (${inList})`).join(" OR ");
  const params = Object.fromEntries(values.map((v, i) => [keys[i], v]));

  return { clause: `(${orCols})`, params };
}

export function mapDbCategory1ToShopLabel(dbCategory1: string): string | null {
  const n = norm(dbCategory1);
  for (const def of SHOP_CATEGORIES) {
    if (def.dbCategory1Values.some((v) => norm(v) === n)) {
      return def.label;
    }
  }
  if (
    n.includes("fruit") ||
    n.includes("vegetable") ||
    n.includes("greens") ||
    (n.includes("green") && (n.includes("leaf") || n.includes("salad")))
  ) {
    return "Fresh Produce";
  }
  if (n.includes("candy") || n.includes("sweet") || n.includes("chocolate") || n.includes("snack")) {
    return "Snacks & Confectionery";
  }
  if (n.includes("pantry") || n.includes("spice") || n.includes("staple")) {
    return "Pantry & Staples";
  }
  if (n.includes("poultry") || n.includes("meat") || n.includes("seafood") || n.includes("deli")) {
    return "Meat, Poultry & Seafood";
  }
  if (n.includes("dairy") || n.includes("cheese") || n.includes("breakfast") || (n.includes("egg") && !n.includes("poultry"))) {
    return "Dairy, Cheese & Eggs";
  }
  if (n.includes("toy") || (n.includes("game") && !n.includes("video"))) {
    return "Toys & Games";
  }
  if (n.includes("beauty") || n.includes("cosmetic") || n.includes("personal care")) {
    return "Beauty & Personal Care";
  }
  if (n.includes("home") || n.includes("living") || n.includes("kitchen")) {
    return "Home & Living";
  }
  return null;
}

/** Roll up dashboard `listTopCategories` rows into shop labels for the grid. */
export function aggregateTopCategoriesToShop(
  rows: readonly { Category: string; Cnt: number }[]
): Map<string, number> {
  const map = new Map<string, number>();
  for (const def of SHOP_CATEGORIES) {
    map.set(def.label, 0);
  }
  for (const row of rows) {
    const shop = mapDbCategory1ToShopLabel(row.Category);
    if (!shop) continue;
    map.set(shop, (map.get(shop) ?? 0) + Number(row.Cnt ?? 0));
  }
  return map;
}

/** Display string for active filter (legacy DB names → shop label when possible). */
export function displayCategoryFilter(raw: string): string {
  const def = definitionForShopLabel(raw);
  if (def) return def.label;
  const mapped = mapDbCategory1ToShopLabel(raw);
  return mapped ?? raw;
}
