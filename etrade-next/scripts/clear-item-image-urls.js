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

  const dryRun = process.argv.slice(2).includes("--dry-run");

  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const sql = require("mssql/msnodesqlv8");
  await sql.connect({ connectionString });

  if (dryRun) {
    const r = await sql.query(`
      SELECT COUNT(*) AS Cnt
      FROM dbo.ITEMS
      WHERE IMAGE_URL IS NOT NULL AND LTRIM(RTRIM(IMAGE_URL)) <> '';
    `);
    console.log(`Would clear IMAGE_URL for rows=${Number(r.recordset?.[0]?.Cnt ?? 0)}`);
    await sql.close();
    return;
  }

  const res = await sql.query(`
    UPDATE dbo.ITEMS
    SET IMAGE_URL = NULL;
  `);

  const affected = Array.isArray(res.rowsAffected) ? res.rowsAffected.reduce((a, b) => a + b, 0) : null;
  console.log(`OK: cleared IMAGE_URL (rowsAffected=${affected ?? "unknown"})`);

  await sql.close();
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});

