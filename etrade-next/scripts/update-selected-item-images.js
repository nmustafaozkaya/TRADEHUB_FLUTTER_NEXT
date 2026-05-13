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

  const updates = [
    {
      pattern: "%Arzum Okka Minio%",
      imageUrl:
        "https://encrypted-tbn2.gstatic.com/shopping?q=tbn:ANd9GcRLncnnLHRqX3KMu7kGaRy6Jgyo5Lh0vuGuiDsHUn9pFLbFu6mblzZ97EtA_2WqtiVP6GptIZB_H7jf8zyD4npdKjFA-1uHPVMjMIZVgOSweHzYCZTzPqE5Dg",
    },
    {
      pattern: "%Elite Life 0811 Yuksek Bel Slip%",
      imageUrl:
        "https://cdn.dsmcdn.com/ty1800/prod/QC_PREP/20251221/15/6002ba78-a8ea-3dca-b90a-30601186f148/1_org_zoom.jpg",
    },
    {
      pattern: "%Yumurta 15-pack Yellow M%",
      imageUrl: "https://cdn.akakce.com/carrefour/carrefour-15-li-x.jpg",
    },
    {
      pattern: "%Prt.premier 19 Inch Hd Led Tv%",
      imageUrl: "https://cdn.akakce.com/premier/premier-19e15-19-led-z.jpg",
    },
  ];

  for (const row of updates) {
    const req = new sql.Request();
    req.input("pattern", row.pattern);
    req.input("imageUrl", row.imageUrl);
    const res = await req.query(`
      UPDATE dbo.ITEMS
      SET IMAGE_URL = @imageUrl
      WHERE ITEMNAME LIKE @pattern;
    `);
    const affected = Array.isArray(res.rowsAffected) ? res.rowsAffected.reduce((a, b) => a + b, 0) : 0;
    console.log(`Updated (${row.pattern}) => ${affected} row(s)`);
  }

  const check = await sql.query(`
    SELECT TOP (20) ID, ITEMNAME, IMAGE_URL
    FROM dbo.ITEMS
    WHERE ITEMNAME LIKE '%Arzum Okka Minio%'
       OR ITEMNAME LIKE '%Elite Life 0811 Yuksek Bel Slip%'
       OR ITEMNAME LIKE '%Yumurta 15-pack Yellow M%'
       OR ITEMNAME LIKE '%Prt.premier 19 Inch Hd Led Tv%'
    ORDER BY ID DESC;
  `);

  console.log("Preview:");
  for (const r of check.recordset || []) {
    console.log(`- #${r.ID} ${r.ITEMNAME}`);
    console.log(`  ${r.IMAGE_URL}`);
  }

  await sql.close();
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});

