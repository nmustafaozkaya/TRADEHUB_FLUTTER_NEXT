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

function picsumUrlForId(id, size) {
  const safe = `tradehub-${id}`;
  const s = Number(size) || 800;
  return `https://picsum.photos/seed/${encodeURIComponent(safe)}/${s}/${s}`;
}

async function main() {
  loadEnvLocal();
  const connectionString = process.env.MSSQL_CONNECTION_STRING;
  if (!connectionString) throw new Error("MSSQL_CONNECTION_STRING is not set (check .env.local).");

  const args = process.argv.slice(2);
  const sizeArg = args.find((x) => x.startsWith("--size="));
  const size = sizeArg ? Number(sizeArg.split("=")[1]) : 800;
  const limitArg = args.find((x) => x.startsWith("--limit="));
  const limit = limitArg ? Number(limitArg.split("=")[1]) : 0; // 0 = unlimited
  const batchArg = args.find((x) => x.startsWith("--batch="));
  const batch = batchArg ? Number(batchArg.split("=")[1]) : 500;
  const dryRun = args.includes("--dry-run");

  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const sql = require("mssql/msnodesqlv8");
  await sql.connect({ connectionString });

  let updated = 0;
  let scanned = 0;

  while (limit <= 0 || scanned < limit) {
    const take = Math.min(batch, limit > 0 ? limit - scanned : batch);
    const res = await sql.query(`
      SELECT TOP (${take}) ID
      FROM dbo.ITEMS
      WHERE IMAGE_URL IS NULL OR LTRIM(RTRIM(IMAGE_URL)) = ''
      ORDER BY ID ASC;
    `);
    const rows = res.recordset || [];
    if (!rows.length) break;
    scanned += rows.length;

    for (const r of rows) {
      const id = Number(r.ID);
      const url = picsumUrlForId(id, size);
      if (dryRun) {
        if (updated < 10) console.log({ id, url });
        updated += 1;
        continue;
      }
      const req = new sql.Request();
      req.input("id", id);
      req.input("url", url);
      await req.query(`
        UPDATE dbo.ITEMS
        SET IMAGE_URL = @url
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

