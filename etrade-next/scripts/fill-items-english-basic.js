/* eslint-disable no-console */
const fs = require("fs");
const path = require("path");

function loadEnvLocal() {
  const p = path.join(process.cwd(), ".env.local");
  if (!fs.existsSync(p)) return;
  const text = fs.readFileSync(p, "utf8");
  for (const rawLine of text.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) continue;
    const idx = line.indexOf("=");
    if (idx <= 0) continue;
    const key = line.slice(0, idx).trim();
    let val = line.slice(idx + 1).trim();
    if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
      val = val.slice(1, -1);
    }
    if (!process.env[key]) process.env[key] = val;
  }
}

function normalizeText(s) {
  return String(s || "").replace(/\s+/g, " ").trim();
}

const CATEGORY_MAP = new Map([
  ["EV", "Home"],
  ["OYUNCAK", "Toys"],
  ["TEMIZLIK", "Cleaning"],
  ["YESILLIK", "Greens"],
  ["SEBZE", "Vegetables"],
  ["MEYVE", "Fruits"],
  ["KUMES", "Poultry"],
  ["PILIC", "Chicken"],
  ["ET", "Meat"],
  ["GIDA", "Food"],
  ["KOZMETIK", "Cosmetics"],
  ["KAHVALTILIK", "Breakfast"],
  ["SICAK ICECEKLER", "Hot drinks"],
  ["SOGUK ICECEKLER", "Cold drinks"],
  ["DETERJAN", "Detergents"],
  ["SEKERLEME", "Confectionery"],
  ["BEBEK", "Baby"],
  ["MANAV", "Produce"],
  ["KITAP", "Books"],
  ["KIRTASIYE", "Stationery"],
]);

const PHRASE_MAP = [
  ["ELEKTRIK-ELEKTRONIK", "Electronics"],
  ["KITAP-DERGI-KIRTASIYE", "Books & Stationery"],
  ["MUTFAK GERECLERI", "Kitchen supplies"],
  ["EV GERECLERI", "Home supplies"],
  ["KISISEL BAKIM", "Personal care"],
  ["CILT BAKIM", "Skincare"],
  ["AGIZ BAKIM", "Oral care"],
  ["OTO BAKIM-AKSESUARLARI", "Auto care & accessories"],
  ["ODA KOKULARI", "Room fragrance"],
  ["KLIMA KOKULAR", "Car air fresheners"],
  ["BEBE OYUNCAK", "Baby toys"],
  ["KALEM PILLER", "AA batteries"],
  ["INCE PILLER", "AAA batteries"],
  ["POWER BANK", "Power bank"],
];

// Word-level replacements for ITEMNAME (best-effort).
// Keep small: user can expand later.
const WORD_MAP = [
  ["PIL", "Battery"],
  ["PILLI", "Battery powered"],
  ["OYUNCAK", "Toy"],
  ["SESLI", "Sound"],
  ["ISIKLI", "Light-up"],
  ["UCAK", "Plane"],
  ["TANK", "Tank"],
  ["GITAR", "Guitar"],
  ["KUTUDA", "Boxed"],
  ["KUT.", "Box"],
  ["KUTU", "Box"],
  ["MAKASI", "Scissors"],
  ["HESAP MAKINASI", "Calculator"],
  ["SAKLAMA KABI", "Storage container"],
  ["TUVALET KAGITLIGI", "Toilet paper holder"],
  ["SOGAN", "Onion"],
  ["DOMATES", "Tomato"],
  ["PATATES", "Potato"],
  ["TURP", "Radish"],
  ["ELMA", "Apple"],
  ["ARMUT", "Pear"],
  ["UZUM", "Grapes"],
  ["PORTAKAL", "Orange"],
  ["MANDALINA", "Mandarin"],
  ["BIBER", "Pepper"],
  ["SALATALIK", "Cucumber"],
  ["MARUL", "Lettuce"],
  ["KIVIRCIK", "Curly"],
  ["KIRMIZI", "Red"],
  ["BEYAZ", "White"],
  ["SIYAH", "Black"],
  ["SARI", "Yellow"],
  ["MAVI", "Blue"],
  ["YESIL", "Green"],
];

const KEEP_UPPER = new Set([
  "KG",
  "GR",
  "ML",
  "LT",
  "AA",
  "AAA",
  "V",
  "9V",
  "4K",
  "HDMI",
  "SSD",
  "GB",
  "XL",
  "XXL",
  "S",
  "M",
  "L",
]);

function titleCaseWords(s) {
  const parts = s.split(" ").filter(Boolean);
  return parts
    .map((w) => {
      const up = w.toUpperCase();
      if (KEEP_UPPER.has(up)) return up;
      if (/^\d+[.,]?\d*$/.test(w)) return w;
      return w.charAt(0).toUpperCase() + w.slice(1).toLowerCase();
    })
    .join(" ");
}

function applyWordMap(original) {
  const base = " " + normalizeText(original).toUpperCase() + " ";
  let s = base;
  // Replace longer phrases first.
  const entries = [...WORD_MAP].sort((a, b) => b[0].length - a[0].length);
  for (const [tr, en] of entries) {
    const needle = " " + tr.toUpperCase() + " ";
    const repl = " " + en.toUpperCase() + " ";
    s = s.split(needle).join(repl);
  }
  s = normalizeText(s);
  return titleCaseWords(s);
}

function translateCategoryExact(cat) {
  const k = normalizeText(cat).toUpperCase();
  if (!k) return null;
  return CATEGORY_MAP.get(k) || null;
}

function translateCategoryPhrase(cat) {
  const raw = normalizeText(cat);
  if (!raw) return null;
  let up = raw.toUpperCase();
  for (const [tr, en] of PHRASE_MAP) {
    up = up.split(tr).join(en.toUpperCase());
  }
  return titleCaseWords(up);
}

function bestCategoryEn(cat) {
  return translateCategoryExact(cat) || translateCategoryPhrase(cat) || null;
}

async function main() {
  loadEnvLocal();
  const connectionString = process.env.MSSQL_CONNECTION_STRING;
  if (!connectionString) throw new Error("MSSQL_CONNECTION_STRING is not set (check .env.local).");

  const args = process.argv.slice(2);
  const limitArg = args.find((x) => x.startsWith("--limit="));
  // limit=0 (default) means "no limit" (process all rows needing EN fill).
  const limit = limitArg ? Number(limitArg.split("=")[1]) : 0;
  const unlimited = !Number.isFinite(limit) || limit <= 0;
  const dryRun = args.includes("--dry-run");
  const batchSizeArg = args.find((x) => x.startsWith("--batch="));
  const batchSize = batchSizeArg ? Number(batchSizeArg.split("=")[1]) : 200;

  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const sql = require("mssql/msnodesqlv8");
  await sql.connect({ connectionString });

  let updated = 0;
  let scanned = 0;
  while (unlimited || scanned < limit) {
    const take = unlimited ? batchSize : Math.min(batchSize, limit - scanned);
    const res = await sql.query(`
      SELECT TOP (${take})
        ID, ITEMNAME, BRAND, CATEGORY1, CATEGORY2, CATEGORY3, CATEGORY4,
        ITEMNAME_EN, BRAND_EN, CATEGORY1_EN, CATEGORY2_EN, CATEGORY3_EN, CATEGORY4_EN
      FROM dbo.ITEMS
      WHERE ITEMNAME_EN IS NULL
         OR BRAND_EN IS NULL
         OR CATEGORY1_EN IS NULL
         OR CATEGORY2_EN IS NULL
         OR CATEGORY3_EN IS NULL
         OR CATEGORY4_EN IS NULL
      ORDER BY ID ASC;
    `);

    const rows = res.recordset || [];
    if (!rows.length) break;
    scanned += rows.length;

    for (const r of rows) {
      const id = Number(r.ID);
      const itemName = normalizeText(r.ITEMNAME);
      const brand = normalizeText(r.BRAND);

      const itemNameEn = itemName ? applyWordMap(itemName) : null;
      const brandEn = brand || null; // brands are usually not translated

      const c1 = bestCategoryEn(r.CATEGORY1);
      const c2 = bestCategoryEn(r.CATEGORY2);
      const c3 = bestCategoryEn(r.CATEGORY3);
      const c4 = bestCategoryEn(r.CATEGORY4);

      if (dryRun) {
        if (updated < 10) {
          console.log({ id, itemName, itemNameEn, brand, brandEn, c1, c2, c3, c4 });
        }
        continue;
      }

      const req = new sql.Request();
      req.input("id", id);
      req.input("itemNameEn", itemNameEn);
      req.input("brandEn", brandEn);
      req.input("c1", c1);
      req.input("c2", c2);
      req.input("c3", c3);
      req.input("c4", c4);

      await req.query(`
        UPDATE dbo.ITEMS
        SET
          ITEMNAME_EN = COALESCE(ITEMNAME_EN, @itemNameEn),
          BRAND_EN = COALESCE(BRAND_EN, @brandEn),
          CATEGORY1_EN = COALESCE(CATEGORY1_EN, @c1),
          CATEGORY2_EN = COALESCE(CATEGORY2_EN, @c2),
          CATEGORY3_EN = COALESCE(CATEGORY3_EN, @c3),
          CATEGORY4_EN = COALESCE(CATEGORY4_EN, @c4)
        WHERE ID = @id;
      `);
      updated += 1;
    }
  }

  await sql.close();
  console.log(`OK: scanned=${scanned}, updated=${updated}, dryRun=${dryRun}`);
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});

