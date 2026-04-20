import { query } from "../db";
import type { ItemRow } from "./items";

export type TopCategoryRow = { Category: string; Cnt: number };

export async function listTopCategories(limit = 8) {
  const rows = await query<TopCategoryRow>(
    `
    SELECT TOP (@limit)
      LTRIM(RTRIM(CATEGORY1)) AS Category,
      COUNT(*) AS Cnt
    FROM dbo.ITEMS
    WHERE ISACTIVE = 1
      AND CATEGORY1 IS NOT NULL
      AND LTRIM(RTRIM(CATEGORY1)) <> ''
    GROUP BY LTRIM(RTRIM(CATEGORY1))
    ORDER BY COUNT(*) DESC, LTRIM(RTRIM(CATEGORY1)) ASC;
    `,
    { limit: Number(limit) }
  );

  return rows
    .map((r) => ({ Category: String(r.Category), Cnt: Number(r.Cnt) }))
    .filter((r) => r.Category);
}

export type BestSellerRow = ItemRow & { SoldQty: number };

export async function listBestSellers(limit = 10) {
  const rows = await query<BestSellerRow>(
    `
    SELECT TOP (@limit)
      i.ID,
      i.ITEMCODE,
      i.ITEMNAME AS ITEMNAME,
      i.UNITPRICE,
      i.BRAND AS BRAND,
      i.CATEGORY1 AS CATEGORY1,
      i.CATEGORY2 AS CATEGORY2,
      i.CATEGORY3 AS CATEGORY3,
      i.CATEGORY4 AS CATEGORY4,
      i.IMAGE_URL AS IMAGE_URL,
      SUM(od.AMOUNT) AS SoldQty
    FROM dbo.ORDERDETAILS od
    INNER JOIN dbo.ITEMS i ON i.ID = od.ITEMID
    WHERE i.ISACTIVE = 1
    GROUP BY
      i.ID,
      i.ITEMCODE,
      i.ITEMNAME,
      i.UNITPRICE,
      i.BRAND,
      i.CATEGORY1,
      i.CATEGORY2,
      i.CATEGORY3,
      i.CATEGORY4,
      i.IMAGE_URL
    ORDER BY SUM(od.AMOUNT) DESC;
    `,
    { limit: Number(limit) }
  );

  return rows.map((r) => ({ ...r, SoldQty: Number(r.SoldQty ?? 0) }));
}

