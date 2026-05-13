/* eslint-disable @typescript-eslint/no-var-requires */
/* eslint-disable no-console */
const fs = require("node:fs");
const path = require("node:path");

function loadEnvLocal() {
  const p = path.join(process.cwd(), ".env.local");
  if (!fs.existsSync(p)) return;
  const txt = fs.readFileSync(p, "utf8");
  for (const line of txt.split(/\r?\n/)) {
    const t = line.trim();
    if (!t || t.startsWith("#")) continue;
    const idx = t.indexOf("=");
    if (idx <= 0) continue;
    const k = t.slice(0, idx).trim();
    const v = t.slice(idx + 1).trim();
    if (!(k in process.env)) process.env[k] = v;
  }
}

async function main() {
  loadEnvLocal();
  const connectionString = process.env.MSSQL_CONNECTION_STRING;
  if (!connectionString) throw new Error("MSSQL_CONNECTION_STRING is not set.");

  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const sql = require("mssql/msnodesqlv8");
  await sql.connect({ connectionString });

  const imageUrl =
    "https://iis-akakce.akamaized.net/p.z?https%3A%2F%2Fcdn-img.pttavm.com%2Fpimages%2F592%2F124%2F231%2F5b036fec-92f8-4ece-ae90-e3aea821e4d4.webp%3Fv%3D202402141157";

  const req = new sql.Request();
  req.input("imageUrl", imageUrl);
  const upd = await req.query(`
    UPDATE dbo.ITEMS
    SET IMAGE_URL = @imageUrl
    WHERE ITEMNAME LIKE '%Nergis Butter Tuzlu 10 KG%';
  `);

  const affected = Array.isArray(upd.rowsAffected) ? upd.rowsAffected.reduce((a, b) => a + b, 0) : 0;
  console.log(`Updated rows: ${affected}`);

  const rows = await sql.query(`
    SELECT TOP (5) ID, ITEMNAME, IMAGE_URL
    FROM dbo.ITEMS
    WHERE ITEMNAME LIKE '%Nergis Butter Tuzlu 10 KG%'
    ORDER BY ID DESC;
  `);
  for (const r of rows.recordset || []) {
    console.log(`#${r.ID} ${r.ITEMNAME}`);
    console.log(r.IMAGE_URL);
  }

  await sql.close();
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});

