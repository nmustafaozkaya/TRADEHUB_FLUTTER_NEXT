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
  const cs = process.env.MSSQL_CONNECTION_STRING;
  if (!cs) throw new Error("MSSQL_CONNECTION_STRING is not set.");
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const sql = require("mssql/msnodesqlv8");
  await sql.connect({ connectionString: cs });
  const r = await sql.query(`
    SELECT TOP (20)
      ID,
      ITEMNAME,
      BRAND,
      CATEGORY1,
      CATEGORY2,
      CATEGORY3,
      CATEGORY4
    FROM dbo.ITEMS
    ORDER BY ID ASC;
  `);
  console.table(r.recordset);
  await sql.close();
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});

