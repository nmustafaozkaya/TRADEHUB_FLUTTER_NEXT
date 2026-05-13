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
  if (!connectionString) {
    throw new Error("MSSQL_CONNECTION_STRING is not set (check .env.local).");
  }

  // Optional arg: global cap for inserted rows.
  const seedArg = process.argv.find((a) => a.startsWith("--seedCount="));
  const seedCount = Math.max(1, Number(seedArg?.split("=")[1] ?? 400) || 400);
  const reseed = process.argv.includes("--reseed");

  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const sql = require("mssql/msnodesqlv8");
  await sql.connect({ connectionString });

  // 1) Ensure REVIEWS table.
  await sql.query(`
    IF OBJECT_ID('dbo.REVIEWS', 'U') IS NULL
    BEGIN
      CREATE TABLE dbo.REVIEWS (
        ID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        USERID INT NOT NULL,
        ORDERID INT NOT NULL,
        ITEMID INT NOT NULL,
        RATING TINYINT NOT NULL,
        COMMENT NVARCHAR(800) NULL,
        ISACTIVE BIT NOT NULL CONSTRAINT DF_REVIEWS_ISACTIVE DEFAULT (1),
        CREATEDAT DATETIME NOT NULL CONSTRAINT DF_REVIEWS_CREATEDAT DEFAULT (GETDATE()),
        UPDATEDAT DATETIME NULL,
        CONSTRAINT CK_REVIEWS_RATING CHECK (RATING BETWEEN 1 AND 5)
      );
    END;

    IF NOT EXISTS (
      SELECT 1
      FROM sys.indexes
      WHERE object_id = OBJECT_ID('dbo.REVIEWS')
        AND name = 'UX_REVIEWS_USER_ORDER_ITEM_ACTIVE'
    )
    BEGIN
      CREATE UNIQUE INDEX UX_REVIEWS_USER_ORDER_ITEM_ACTIVE
      ON dbo.REVIEWS (USERID, ORDERID, ITEMID)
      WHERE ISACTIVE = 1;
    END;

    IF NOT EXISTS (
      SELECT 1
      FROM sys.indexes
      WHERE object_id = OBJECT_ID('dbo.REVIEWS')
        AND name = 'IX_REVIEWS_ITEM_ACTIVE'
    )
    BEGIN
      CREATE INDEX IX_REVIEWS_ITEM_ACTIVE
      ON dbo.REVIEWS (ITEMID, ISACTIVE, CREATEDAT DESC);
    END;

    IF NOT EXISTS (
      SELECT 1
      FROM sys.indexes
      WHERE object_id = OBJECT_ID('dbo.REVIEWS')
        AND name = 'IX_REVIEWS_USER_ACTIVE'
    )
    BEGIN
      CREATE INDEX IX_REVIEWS_USER_ACTIVE
      ON dbo.REVIEWS (USERID, ISACTIVE, CREATEDAT DESC);
    END;
  `);

  if (reseed) {
    await sql.query(`
      UPDATE dbo.REVIEWS
      SET ISACTIVE = 0,
          UPDATEDAT = GETDATE()
      WHERE ISACTIVE = 1;
    `);
    console.log("Info: Existing active reviews were deactivated (--reseed).");
  }

  // 2) Seed random reviews from real purchased rows.
  // We keep ISACTIVE=1 so it matches your active flag flow.
  // Strategy:
  // - Active items only
  // - Buyers only (orders + orderdetails)
  // - Per item random target between 5..30 where possible
  // - Skip duplicates by active unique key
  const insertRes = await sql.query(`
    DECLARE @seedCount INT = ${seedCount};

    ;WITH ActiveItems AS (
      SELECT i.ID AS ITEMID
      FROM dbo.ITEMS i
      WHERE i.ISACTIVE = 1
    ),
    PurchasedPairs AS (
      SELECT DISTINCT
        o.USERID,
        o.ID AS ORDERID,
        od.ITEMID
      FROM dbo.ORDERS o
      INNER JOIN dbo.ORDERDETAILS od ON od.ORDERID = o.ID
      INNER JOIN ActiveItems ai ON ai.ITEMID = od.ITEMID
      WHERE o.USERID IS NOT NULL
        AND o.USERID > 0
        AND o.STATUS_ IN (0, 1, 2, 3, 5)
    ),
    CurrentActive AS (
      SELECT
        r.ITEMID,
        COUNT(*) AS ActiveCnt
      FROM dbo.REVIEWS r
      WHERE r.ISACTIVE = 1
      GROUP BY r.ITEMID
    ),
    TargetPerItem AS (
      SELECT
        ai.ITEMID,
        (5 + ABS(CHECKSUM(NEWID())) % 46) AS TargetCount
      FROM ActiveItems ai
    ),
    NeedPerItem AS (
      SELECT
        t.ITEMID,
        CASE
          WHEN t.TargetCount - ISNULL(c.ActiveCnt, 0) > 0 THEN t.TargetCount - ISNULL(c.ActiveCnt, 0)
          ELSE 0
        END AS NeedCount
      FROM TargetPerItem t
      LEFT JOIN CurrentActive c ON c.ITEMID = t.ITEMID
    ),
    Candidates AS (
      SELECT
        p.USERID,
        p.ORDERID,
        p.ITEMID,
        ROW_NUMBER() OVER (PARTITION BY p.ITEMID ORDER BY NEWID()) AS rn
      FROM PurchasedPairs p
      WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.REVIEWS r
        WHERE r.USERID = p.USERID
          AND r.ORDERID = p.ORDERID
          AND r.ITEMID = p.ITEMID
          AND r.ISACTIVE = 1
      )
    ),
    Picked AS (
      SELECT TOP (@seedCount)
        c.USERID,
        c.ORDERID,
        c.ITEMID
      FROM Candidates c
      INNER JOIN NeedPerItem n ON n.ITEMID = c.ITEMID
      WHERE c.rn <= n.NeedCount
      ORDER BY NEWID()
    )
    INSERT INTO dbo.REVIEWS (
      USERID,
      ORDERID,
      ITEMID,
      RATING,
      COMMENT,
      ISACTIVE,
      CREATEDAT
    )
    SELECT
      p.USERID,
      p.ORDERID,
      p.ITEMID,
      CASE (h.seed % 100)
        WHEN 0 THEN 1 WHEN 1 THEN 1 WHEN 2 THEN 2 WHEN 3 THEN 2
        WHEN 4 THEN 3 WHEN 5 THEN 3 WHEN 6 THEN 3 WHEN 7 THEN 4 WHEN 8 THEN 4
        ELSE 5
      END AS RATING,
      CASE (h.seed % 18)
        WHEN 0 THEN N'Great quality and fast delivery.'
        WHEN 1 THEN N'Exactly as expected, would buy again.'
        WHEN 2 THEN N'Price/performance is very good.'
        WHEN 3 THEN N'Packaging was clean and product was fresh.'
        WHEN 4 THEN N'Good product, smooth checkout experience.'
        WHEN 5 THEN N'Works well for daily use.'
        WHEN 6 THEN N'Satisfied with this purchase.'
        WHEN 7 THEN N'Nice quality, delivery was on time.'
        WHEN 8 THEN N'Not bad, but expected slightly better quality.'
        WHEN 9 THEN N'Average product, acceptable for this price.'
        WHEN 10 THEN N'Could be improved, but still usable.'
        WHEN 11 THEN N'Exceeded my expectations.'
        WHEN 12 THEN N'Would recommend to friends.'
        WHEN 13 THEN N'The product is decent overall.'
        WHEN 14 THEN N'Arrived quickly and in good condition.'
        WHEN 15 THEN N'Quality is okay, packaging could be better.'
        WHEN 16 THEN N'I am happy with this purchase.'
        ELSE N'Good value for the money.'
      END AS COMMENT,
      1,
      DATEADD(DAY, -(h.seed % 45), GETDATE())
    FROM Picked p
    CROSS APPLY (
      SELECT ABS(CHECKSUM(NEWID(), p.USERID, p.ORDERID, p.ITEMID)) AS seed
    ) h;
  `);

  const inserted = Array.isArray(insertRes.rowsAffected)
    ? insertRes.rowsAffected.reduce((a, b) => a + b, 0)
    : 0;

  const stats = await sql.query(`
    SELECT
      COUNT(*) AS ActiveReviews,
      COUNT(DISTINCT ITEMID) AS ActiveItemsWithReviews
    FROM dbo.REVIEWS
    WHERE ISACTIVE = 1;
  `);

  console.log("OK: dbo.REVIEWS table ensured.");
  console.log(`OK: Random active reviews inserted: ${inserted}`);
  console.log(`Info: seedCount requested = ${seedCount}`);
  console.log(
    `Info: active reviews now = ${Number(stats.recordset?.[0]?.ActiveReviews ?? 0)}, items with reviews = ${Number(stats.recordset?.[0]?.ActiveItemsWithReviews ?? 0)}`
  );

  await sql.close();
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});

