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

async function main() {
  loadEnvLocal();
  const cs = process.env.MSSQL_CONNECTION_STRING;
  if (!cs) throw new Error("MSSQL_CONNECTION_STRING is not set (check .env.local).");

  const args = process.argv.slice(2);
  const dryRun = args.includes("--dry-run");

  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const sql = require("mssql/msnodesqlv8");
  await sql.connect({ connectionString: cs });

  const backupTable = `ITEMS_BACKUP_${tsName()}`;

  if (dryRun) {
    console.log(`[dry-run] would create backup table dbo.${backupTable}`);
    console.log("[dry-run] would promote *_EN columns into main columns");
    await sql.close();
    return;
  }

  console.log(`Creating backup: dbo.${backupTable}`);
  await sql.query(`
    SELECT *
    INTO dbo.${backupTable}
    FROM dbo.ITEMS;
  `);

  console.log("Promoting English columns into main columns...");
  const res = await sql.query(`
    UPDATE dbo.ITEMS
    SET
      ITEMNAME = COALESCE(ITEMNAME_EN, ITEMNAME),
      BRAND = COALESCE(BRAND_EN, BRAND),
      CATEGORY1 = COALESCE(CATEGORY1_EN, CATEGORY1),
      CATEGORY2 = COALESCE(CATEGORY2_EN, CATEGORY2),
      CATEGORY3 = COALESCE(CATEGORY3_EN, CATEGORY3),
      CATEGORY4 = COALESCE(CATEGORY4_EN, CATEGORY4);
  `);

  // mssql returns rowsAffected array
  const affected = Array.isArray(res.rowsAffected) ? res.rowsAffected.reduce((a, b) => a + b, 0) : null;
  console.log(`OK: rowsAffected=${affected ?? "unknown"}`);
  console.log(`Backup table: dbo.${backupTable}`);

  await sql.close();
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});

