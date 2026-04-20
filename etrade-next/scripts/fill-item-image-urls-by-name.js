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

function normalizeSpace(s) {
  return String(s || "").replace(/\s+/g, " ").trim();
}

const STOPWORDS = new Set(
  [
    "AND",
    "OR",
    "THE",
    "WITH",
    "FOR",
    "OF",
    "IN",
    "ON",
    "PACK",
    "PCS",
    "PC",
    "X",
    "KG",
    "GR",
    "ML",
    "LT",
    "CM",
    "MM",
    "NO",
    "SET",
  ].map((x) => x.toUpperCase())
);

function pickKeywords({ name, brand, category1, category2 }) {
  const raw = normalizeSpace(
    [name, brand, category1, category2]
      .filter(Boolean)
      .map((x) => String(x))
      .join(" ")
  );
  if (!raw) return ["product"];
  const parts = raw
    .replace(/[^\p{L}\p{N}\s-]+/gu, " ")
    .replace(/[-]/g, " ")
    .split(/\s+/)
    .map((w) => w.trim())
    .filter(Boolean);

  const out = [];
  for (const w of parts) {
    const up = w.toUpperCase();
    if (STOPWORDS.has(up)) continue;
    if (/^\d+([.,]\d+)?$/.test(w)) continue;
    if (w.length <= 2) continue;
    if (!out.includes(w)) out.push(w);
    if (out.length >= 5) break;
  }
  return out.length ? out : ["product"];
}

/**
 * Stable, keyword-based product image URL.
 * LoremFlickr supports `?lock=` to keep same image for same lock.
 * Example: https://loremflickr.com/800/800/battery,kodak?lock=1
 */
function loremFlickrUrl({ id, keywords, size }) {
  const s = Number(size) || 800;
  const tags = encodeURIComponent(keywords.join(","));
  return `https://loremflickr.com/${s}/${s}/${tags}?lock=${encodeURIComponent(String(id))}`;
}

async function main() {
  loadEnvLocal();
  const connectionString = process.env.MSSQL_CONNECTION_STRING;
  if (!connectionString) throw new Error("MSSQL_CONNECTION_STRING is not set (check .env.local).");

  const args = process.argv.slice(2);
  const sizeArg = args.find((x) => x.startsWith("--size="));
  const size = sizeArg ? Number(sizeArg.split("=")[1]) : 800;
  const batchArg = args.find((x) => x.startsWith("--batch="));
  const batch = batchArg ? Number(batchArg.split("=")[1]) : 400;
  const limitArg = args.find((x) => x.startsWith("--limit="));
  const limit = limitArg ? Number(limitArg.split("=")[1]) : 0; // 0 = unlimited
  const dryRun = args.includes("--dry-run");
  const overwrite = args.includes("--overwrite");

  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const sql = require("mssql/msnodesqlv8");
  await sql.connect({ connectionString });

  let scanned = 0;
  let updated = 0;

  while (limit <= 0 || scanned < limit) {
    const take = Math.min(batch, limit > 0 ? limit - scanned : batch);
    const where = overwrite
      ? "1=1"
      : "(IMAGE_URL IS NULL OR LTRIM(RTRIM(IMAGE_URL)) = '' OR IMAGE_URL LIKE 'https://picsum.photos/%')";

    const res = await sql.query(`
      SELECT TOP (${take})
        ID, ITEMNAME, BRAND, CATEGORY1, CATEGORY2, IMAGE_URL
      FROM dbo.ITEMS
      WHERE ${where}
      ORDER BY ID ASC;
    `);
    const rows = res.recordset || [];
    if (!rows.length) break;
    scanned += rows.length;

    for (const r of rows) {
      const id = Number(r.ID);
      const keywords = pickKeywords({
        name: r.ITEMNAME,
        brand: r.BRAND,
        category1: r.CATEGORY1,
        category2: r.CATEGORY2,
      });
      const url = loremFlickrUrl({ id, keywords, size });

      if (dryRun) {
        if (updated < 15) console.log({ id, keywords: keywords.join(","), url, prev: r.IMAGE_URL });
        updated += 1;
        continue;
      }

      const req = new sql.Request();
      req.input("id", id);
      req.input("url", url);
      await req.query(`UPDATE dbo.ITEMS SET IMAGE_URL = @url WHERE ID = @id;`);
      updated += 1;
    }
  }

  await sql.close();
  console.log(`OK: scanned=${scanned}, updated=${updated}, dryRun=${dryRun}, overwrite=${overwrite}`);
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});

