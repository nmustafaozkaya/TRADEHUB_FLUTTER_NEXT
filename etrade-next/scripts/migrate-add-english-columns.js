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

async function main() {
  loadEnvLocal();
  const connectionString = process.env.MSSQL_CONNECTION_STRING;
  if (!connectionString) {
    throw new Error("MSSQL_CONNECTION_STRING is not set (check .env.local).");
  }

  // Use the same driver as the app (Windows Integrated / LocalDB friendly).
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const sql = require("mssql/msnodesqlv8");

  await sql.connect({ connectionString });

  // Add nullable English columns (do not overwrite existing TR fields).
  // NVARCHAR lengths are intentionally generous to avoid truncation.
  const q = `
    IF COL_LENGTH('dbo.ITEMS', 'ITEMNAME_EN') IS NULL
      ALTER TABLE dbo.ITEMS ADD ITEMNAME_EN NVARCHAR(512) NULL;
    IF COL_LENGTH('dbo.ITEMS', 'BRAND_EN') IS NULL
      ALTER TABLE dbo.ITEMS ADD BRAND_EN NVARCHAR(128) NULL;
    IF COL_LENGTH('dbo.ITEMS', 'CATEGORY1_EN') IS NULL
      ALTER TABLE dbo.ITEMS ADD CATEGORY1_EN NVARCHAR(128) NULL;
    IF COL_LENGTH('dbo.ITEMS', 'CATEGORY2_EN') IS NULL
      ALTER TABLE dbo.ITEMS ADD CATEGORY2_EN NVARCHAR(128) NULL;
    IF COL_LENGTH('dbo.ITEMS', 'CATEGORY3_EN') IS NULL
      ALTER TABLE dbo.ITEMS ADD CATEGORY3_EN NVARCHAR(128) NULL;
    IF COL_LENGTH('dbo.ITEMS', 'CATEGORY4_EN') IS NULL
      ALTER TABLE dbo.ITEMS ADD CATEGORY4_EN NVARCHAR(128) NULL;
  `;

  await sql.query(q);
  await sql.close();

  console.log("OK: English columns ensured on dbo.ITEMS.");
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});

