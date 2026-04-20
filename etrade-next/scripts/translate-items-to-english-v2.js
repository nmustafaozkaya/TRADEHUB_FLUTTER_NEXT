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

function tsName() {
  const d = new Date();
  const pad = (n) => String(n).padStart(2, "0");
  return (
    d.getFullYear() +
    pad(d.getMonth() + 1) +
    pad(d.getDate()) +
    "_" +
    pad(d.getHours()) +
    pad(d.getMinutes()) +
    pad(d.getSeconds())
  );
}

function normalizeSpace(s) {
  return String(s || "").replace(/\s+/g, " ").trim();
}

function turkishToAsciiUpper(s) {
  return normalizeSpace(s)
    .toUpperCase()
    .replaceAll("Ç", "C")
    .replaceAll("Ğ", "G")
    .replaceAll("İ", "I")
    .replaceAll("Ö", "O")
    .replaceAll("Ş", "S")
    .replaceAll("Ü", "U");
}

function escapeRegExp(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function replaceToken(textUpperAscii, trUpperAscii, enUpperAscii) {
  // Replace whole-token occurrences using non-alnum boundaries.
  const re = new RegExp(`(^|[^A-Z0-9])${escapeRegExp(trUpperAscii)}([^A-Z0-9]|$)`, "g");
  return textUpperAscii.replace(re, `$1${enUpperAscii}$2`);
}

function titleCaseLoose(s) {
  const parts = normalizeSpace(s).split(" ").filter(Boolean);
  const keepUpper = new Set(["KG", "GR", "ML", "LT", "V", "9V", "AA", "AAA", "USB", "SSD", "HDMI", "GB", "XL", "XXL", "M", "L", "S"]);
  return parts
    .map((w) => {
      const up = w.toUpperCase();
      if (keepUpper.has(up)) return up;
      if (/^\d+([.,]\d+)?$/.test(w)) return w;
      if (/^([A-Z]{1,5}\d+|\d+[A-Z]{1,5})$/.test(up)) return up;
      return w.charAt(0).toUpperCase() + w.slice(1).toLowerCase();
    })
    .join(" ");
}

// High-signal phrase translations first.
const PHRASES = [
  ["ZEKA GELISTIRICI", "Educational"],
  ["BEBE OYUNCAK", "Baby toys"],
  ["KITAP-DERGI-KIRTASIYE", "Books & Stationery"],
  ["ELEKTRIK-ELEKTRONIK", "Electronics"],
  ["MUTFAK GERECLERI", "Kitchen supplies"],
  ["EV GERECLERI", "Home supplies"],
  ["KISISEL BAKIM", "Personal care"],
  ["CILT BAKIM", "Skincare"],
  ["AGIZ BAKIM", "Oral care"],
  ["DIS MACUNLARI", "Toothpaste"],
  ["DIS IPLERI", "Dental floss"],
  ["DIS FIRCALARI", "Toothbrushes"],
  ["ODA KOKULARI", "Room fragrance"],
  ["KLIMA KOKULAR", "Car air fresheners"],
  ["TOZ DETERJANLAR", "Powder detergents"],
  ["SIVI-JEL DETERJANLAR", "Liquid detergents"],
  ["ISLENMIS ET", "Processed meat"],
  ["TUZ-BAHARAT", "Spices"],
  ["UNLU MAMUL-TATLI", "Bakery & desserts"],
  ["SUT-YOGURT-PEYNIR", "Dairy"],
  ["KAHVALTILIK GEVREK", "Breakfast cereal"],
];

// Word-level map (expandable). Upper-ascii keys.
const WORDS = [
  // batteries / electronics
  ["PIL", "BATTERY"],
  ["PILLI", "BATTERY POWERED"],
  ["SARJLI", "RECHARGEABLE"],
  ["ALKALIN", "ALKALINE"],
  ["POWER BANK", "POWER BANK"],
  ["INCE", "AAA"],
  ["KALEM", "AA"],

  // toys
  ["OYUNCAK", "TOY"],
  ["BEBEK", "DOLL"],
  ["UCAK", "PLANE"],
  ["TANK", "TANK"],
  ["GITAR", "GUITAR"],
  ["ISIKLI", "LIGHT-UP"],
  ["SESLI", "SOUND"],
  ["ROBOT", "ROBOT"],
  ["SETI", "SET"],
  ["KARTELADA", "BLISTER"],

  // stationery / home
  ["HESAP MAKINASI", "CALCULATOR"],
  ["MAKASI", "SCISSORS"],
  ["BANT", "TAPE"],
  ["DOSYA", "FILE"],
  ["SILGI", "ERASER"],

  // produce
  ["SOGAN", "ONION"],
  ["DOMATES", "TOMATO"],
  ["PATATES", "POTATO"],
  ["TURP", "RADISH"],
  ["ELMA", "APPLE"],
  ["ARMUT", "PEAR"],
  ["UZUM", "GRAPES"],
  ["PORTAKAL", "ORANGE"],
  ["MANDALINA", "MANDARIN"],
  ["BIBER", "PEPPER"],
  ["SALATALIK", "CUCUMBER"],
  ["MARUL", "LETTUCE"],

  // colors / descriptors
  ["KIRMIZI", "RED"],
  ["BEYAZ", "WHITE"],
  ["SIYAH", "BLACK"],
  ["SARI", "YELLOW"],
  ["MAVI", "BLUE"],
  ["YESIL", "GREEN"],
  ["KIVIRCIK", "CURLY"],
  ["TURSULUK", "PICKLING"],
  ["ITHAL", "IMPORTED"],
  ["YERLI", "LOCAL"],

  // misc common words from your sample
  ["VAKKUMLU", "VACUUM"],
  ["TASIYICI", "CARRIER"],
  ["TIR", "TRUCK"],
  ["RENKLI", "COLORFUL"],
  ["SACLI", "HAIR"],
  ["KUTU", "BOX"],
  ["KUT.", "BOX"],
  ["KUTUDA", "BOXED"],
  ["METAL", "METAL"],
];

const CATEGORY_EXACT = new Map([
  ["EV", "Home"],
  ["TEMIZLIK", "Cleaning"],
  ["OYUNCAK", "Toys"],
  ["YESILLIK", "Greens"],
  ["SEBZE", "Vegetables"],
  ["MEYVE", "Fruits"],
  ["MANAV", "Produce"],
  ["KUMES", "Poultry"],
  ["PILIC", "Chicken"],
  ["ET", "Meat"],
  ["GIDA", "Food"],
  ["KOZMETIK", "Cosmetics"],
  ["KAHVALTILIK", "Breakfast"],
  ["KIRTASIYE", "Stationery"],
  ["KIRTASIYELER", "Stationery"],
  ["PIL", "Batteries"],
  ["ODA KOKULARI", "Room fragrance"],
]);

function translateCategory(raw) {
  const v = normalizeSpace(raw);
  if (!v) return null;
  const up = turkishToAsciiUpper(v);
  if (CATEGORY_EXACT.has(up)) return CATEGORY_EXACT.get(up);
  // Phrase replacements
  let out = up;
  for (const [tr, en] of PHRASES) out = out.replaceAll(turkishToAsciiUpper(tr), turkishToAsciiUpper(en));
  return titleCaseLoose(out);
}

function translateItemName(rawName) {
  const original = normalizeSpace(rawName);
  if (!original) return null;
  let up = turkishToAsciiUpper(original);

  // normalize packs like 2'LI / 4'LU / 10 LU / PK.
  up = up.replace(/\b(\d+)\s*'\s*(LI|LU)\b/g, "$1-PACK");
  up = up.replace(/\b(\d+)\s*LU\b/g, "$1-PACK");
  up = up.replace(/\bPK\.?\b/g, "PACK");

  // Normalize some separators
  up = up.replace(/[()]/g, " ");
  up = up.replace(/\s*[*xX]\s*(\d+)\b/g, " X$1"); // AA*2 -> AA X2

  // Phrase-level translations (longest first)
  const phrasesSorted = [...PHRASES].sort((a, b) => b[0].length - a[0].length);
  for (const [tr, en] of phrasesSorted) {
    up = up.replaceAll(turkishToAsciiUpper(tr), turkishToAsciiUpper(en));
  }

  // Word/token translations (longest first)
  const wordsSorted = [...WORDS].sort((a, b) => b[0].length - a[0].length);
  for (const [tr, en] of wordsSorted) {
    const trUp = turkishToAsciiUpper(tr);
    const enUp = turkishToAsciiUpper(en);
    up = replaceToken(up, trUp, enUp);
  }

  // Cleanup
  up = normalizeSpace(up.replace(/[-_]{2,}/g, " ").replace(/\s+-\s+/g, " - "));
  return titleCaseLoose(up);
}

function looksStillTurkish(s) {
  const t = turkishToAsciiUpper(s);
  // heuristic: contains common Turkish tokens after translation attempt
  return /\b(OGRENCI|GELISTIRICI|OYUNCAKLAR|KIRTASIYE|GERECLERI|MUTFAK|YESILLIKLER|SEBZELER|MEYVELER)\b/.test(t);
}

async function main() {
  loadEnvLocal();
  const cs = process.env.MSSQL_CONNECTION_STRING;
  if (!cs) throw new Error("MSSQL_CONNECTION_STRING is not set (check .env.local).");

  const args = process.argv.slice(2);
  const batchArg = args.find((x) => x.startsWith("--batch="));
  const batch = batchArg ? Number(batchArg.split("=")[1]) : 300;
  const limitArg = args.find((x) => x.startsWith("--limit="));
  const limit = limitArg ? Number(limitArg.split("=")[1]) : 0; // 0 = unlimited
  const dryRun = args.includes("--dry-run");

  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const sql = require("mssql/msnodesqlv8");
  await sql.connect({ connectionString: cs });

  const backupTable = `ITEMS_BACKUP_V2_${tsName()}`;
  if (!dryRun) {
    console.log(`Creating backup: dbo.${backupTable}`);
    await sql.query(`SELECT * INTO dbo.${backupTable} FROM dbo.ITEMS;`);
  }

  let processed = 0;
  let updated = 0;

  // We iterate through all rows once by ID to avoid re-selecting updated rows.
  let lastId = 0;
  // Get max ID to know when to stop (works even with gaps)
  const maxRow = await sql.query(`SELECT MAX(ID) AS MaxId FROM dbo.ITEMS;`);
  const maxId = Number(maxRow.recordset?.[0]?.MaxId ?? 0);

  while (lastId < maxId && (limit <= 0 || processed < limit)) {
    const take = Math.min(batch, limit > 0 ? limit - processed : batch);
    const res = await new sql.Request()
      .input("lastId", lastId)
      .query(`
        SELECT TOP (${take})
          ID, ITEMNAME, BRAND, CATEGORY1, CATEGORY2, CATEGORY3, CATEGORY4
        FROM dbo.ITEMS
        WHERE ID > @lastId
        ORDER BY ID ASC;
      `);
    const rows = res.recordset || [];
    if (!rows.length) break;
    lastId = Number(rows[rows.length - 1].ID);
    processed += rows.length;

    for (const r of rows) {
      const id = Number(r.ID);
      const itemName = normalizeSpace(r.ITEMNAME);

      const nextName = translateItemName(itemName);
      const c1 = (translateCategory(r.CATEGORY1) ?? normalizeSpace(r.CATEGORY1)) || null;
      const c2 = (translateCategory(r.CATEGORY2) ?? normalizeSpace(r.CATEGORY2)) || null;
      const c3 = (translateCategory(r.CATEGORY3) ?? normalizeSpace(r.CATEGORY3)) || null;
      const c4 = (translateCategory(r.CATEGORY4) ?? normalizeSpace(r.CATEGORY4)) || null;

      const nameChanged = nextName && nextName !== itemName;
      const c1Changed = c1 !== (normalizeSpace(r.CATEGORY1) || null);
      const c2Changed = c2 !== (normalizeSpace(r.CATEGORY2) || null);
      const c3Changed = c3 !== (normalizeSpace(r.CATEGORY3) || null);
      const c4Changed = c4 !== (normalizeSpace(r.CATEGORY4) || null);

      // Only update when we actually change something.
      if (!nameChanged && !c1Changed && !c2Changed && !c3Changed && !c4Changed) continue;

      if (dryRun) {
        if (updated < 20) {
          console.log({
            id,
            itemName,
            nextName,
            c1: normalizeSpace(r.CATEGORY1),
            c1Next: c1,
            c2: normalizeSpace(r.CATEGORY2),
            c2Next: c2,
          });
        }
        updated += 1;
        continue;
      }

      await new sql.Request()
        .input("id", id)
        .input("name", nextName)
        .input("c1", c1)
        .input("c2", c2)
        .input("c3", c3)
        .input("c4", c4)
        .query(`
          UPDATE dbo.ITEMS
          SET
            ITEMNAME = COALESCE(@name, ITEMNAME),
            CATEGORY1 = @c1,
            CATEGORY2 = @c2,
            CATEGORY3 = @c3,
            CATEGORY4 = @c4
          WHERE ID = @id;
        `);
      updated += 1;
    }
  }

  await sql.close();

  console.log(`OK: processed=${processed}, updated=${updated}, dryRun=${dryRun}`);
  if (!dryRun) console.log(`Backup table: dbo.${backupTable}`);

  // Reminder for quality: show a hint if still Turkish likely remains.
  if (!dryRun) {
    console.log("Note: This is a dictionary-based translation. If some Turkish words remain, we can expand the map.");
  }
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});

