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
  if (!connectionString) throw new Error("MSSQL_CONNECTION_STRING is not set (check .env.local).");

  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const sql = require("mssql/msnodesqlv8");
  await sql.connect({ connectionString });

  const exists = await sql.query(`
    SELECT 1 AS HasCol
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
      AND TABLE_NAME = 'ITEMS'
      AND COLUMN_NAME = 'IMAGE_URL';
  `);

  if (exists.recordset?.length) {
    console.log("OK: dbo.ITEMS.IMAGE_URL already exists");
    await sql.close();
    return;
  }

  await sql.query(`
    ALTER TABLE dbo.ITEMS
    ADD IMAGE_URL NVARCHAR(600) NULL;
  `);

  console.log("OK: added dbo.ITEMS.IMAGE_URL");
  await sql.close();
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});

