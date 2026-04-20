import { query } from "../db";

export type ItemRow = {
  ID: number;
  ITEMCODE: string | null;
  ITEMNAME: string | null;
  UNITPRICE: number | null;
  BRAND: string | null;
  CATEGORY1: string | null;
  CATEGORY2: string | null;
  CATEGORY3: string | null;
  CATEGORY4: string | null;
  IMAGE_URL: string | null;
};

export async function listItems(
  opts: {
    q?: string;
    brand?: string;
    category?: string;
    sort?: "newest" | "price_asc" | "price_desc" | "name_asc";
    page?: number;
    pageSize?: number;
  } = {}
) {
  const q = opts.q?.trim() || null;
  const brand = opts.brand?.trim() || null;
  const category = opts.category?.trim() || null;
  const sort = opts.sort || "newest";
  const page = Math.max(1, Number(opts.page ?? 1));
  const pageSize = Math.min(500, Math.max(1, Number(opts.pageSize ?? 20)));
  const offset = (page - 1) * pageSize;

  const orderBy =
    sort === "price_asc"
      ? "UNITPRICE ASC, ID DESC"
      : sort === "price_desc"
        ? "UNITPRICE DESC, ID DESC"
        : sort === "name_asc"
          ? "ITEMNAME ASC, ID DESC"
          : "ID DESC";

  const countRows = await query<{ Total: number }>(
    `
    SELECT COUNT(*) AS Total
    FROM dbo.ITEMS
    WHERE ISACTIVE = 1
      AND (
        @q IS NULL
        OR ITEMNAME LIKE '%' + @q + '%'
        OR ITEMCODE LIKE '%' + @q + '%'
      )
      AND (@brand IS NULL OR BRAND = @brand)
      AND (
        @category IS NULL OR
        CATEGORY1 = @category OR CATEGORY2 = @category OR CATEGORY3 = @category OR CATEGORY4 = @category
      )
    `,
    { q, brand, category }
  );
  const total = Number(countRows[0]?.Total ?? 0);

  const items = await query<ItemRow>(
    `
    SELECT
      ID,
      ITEMCODE,
      ITEMNAME,
      UNITPRICE,
      BRAND,
      CATEGORY1,
      CATEGORY2,
      CATEGORY3,
      CATEGORY4,
      IMAGE_URL
    FROM dbo.ITEMS
    WHERE ISACTIVE = 1
      AND (
        @q IS NULL
        OR ITEMNAME LIKE '%' + @q + '%'
        OR ITEMCODE LIKE '%' + @q + '%'
      )
      AND (@brand IS NULL OR BRAND = @brand)
      AND (
        @category IS NULL OR
        CATEGORY1 = @category OR CATEGORY2 = @category OR CATEGORY3 = @category OR CATEGORY4 = @category
      )
    ORDER BY ${orderBy}
    OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY;
    `,
    { q, brand, category, offset, limit: pageSize }
  );

  return { items, total, page, pageSize };
}

export async function getItemsByIds(ids: number[]) {
  const uniq = Array.from(new Set(ids.map((x) => Number(x)).filter((n) => Number.isFinite(n) && n > 0))).slice(0, 200);
  if (!uniq.length) return [];
  const params: Record<string, unknown> = {};
  const placeholders = uniq.map((id, idx) => {
    const key = `id${idx}`;
    params[key] = id;
    return `@${key}`;
  });

  const rows = await query<ItemRow>(
    `
    SELECT
      ID,
      ITEMCODE,
      ITEMNAME,
      UNITPRICE,
      BRAND,
      CATEGORY1,
      CATEGORY2,
      CATEGORY3,
      CATEGORY4,
      IMAGE_URL
    FROM dbo.ITEMS
    WHERE ISACTIVE = 1
      AND ID IN (${placeholders.join(",")})
    ORDER BY ID DESC;
    `,
    params
  );
  return rows;
}

export async function getItemById(id: number) {
  const rows = await query<ItemRow>(
    `
    SELECT TOP (1)
      ID,
      ITEMCODE,
      ITEMNAME,
      UNITPRICE,
      BRAND,
      CATEGORY1,
      CATEGORY2,
      CATEGORY3,
      CATEGORY4,
      IMAGE_URL
    FROM dbo.ITEMS
    WHERE ID = @id
      AND ISACTIVE = 1
    `,
    { id: Number(id) }
  );
  return rows[0] ?? null;
}

export async function listSimilarItems(opts: {
  excludeId: number;
  brand?: string | null;
  category1?: string | null;
  limit?: number;
}): Promise<ItemRow[]> {
  const excludeId = Number(opts.excludeId);
  const brand = (opts.brand || "").trim() || null;
  const category1 = (opts.category1 || "").trim() || null;
  const limit = Math.min(24, Math.max(1, Number(opts.limit ?? 8)));

  if (!excludeId) return [];

  const rows = await query<ItemRow>(
    `
    SELECT TOP (@limit)
      ID,
      ITEMCODE,
      ITEMNAME,
      UNITPRICE,
      BRAND,
      CATEGORY1,
      CATEGORY2,
      CATEGORY3,
      CATEGORY4,
      IMAGE_URL
    FROM dbo.ITEMS
    WHERE ID <> @excludeId
      AND ISACTIVE = 1
      AND (
        (@brand IS NOT NULL AND (BRAND = @brand))
        OR
        (@brand IS NULL AND @category1 IS NOT NULL AND (CATEGORY1 = @category1))
        OR
        (@brand IS NOT NULL AND @category1 IS NOT NULL AND (CATEGORY1 = @category1))
      )
    ORDER BY ID DESC;
    `,
    { excludeId, brand, category1, limit }
  );

  return rows;
}

export async function listBoughtTogether(itemId: number, limit = 8): Promise<ItemRow[]> {
  const id = Number(itemId);
  const lim = Math.min(24, Math.max(1, Number(limit)));
  if (!id) return [];

  const rows = await query<ItemRow>(
    `
    SELECT TOP (@limit)
      i.ID, i.ITEMCODE, i.ITEMNAME, i.UNITPRICE, i.BRAND, i.CATEGORY1, i.CATEGORY2, i.CATEGORY3, i.CATEGORY4, i.IMAGE_URL
    FROM dbo.ORDERDETAILS od
    INNER JOIN dbo.ORDERDETAILS od2 ON od2.ORDERID = od.ORDERID AND od2.ITEMID <> @itemId
    INNER JOIN dbo.ITEMS i ON i.ID = od2.ITEMID
    WHERE od.ITEMID = @itemId
      AND i.ISACTIVE = 1
    GROUP BY i.ID, i.ITEMCODE, i.ITEMNAME, i.UNITPRICE, i.BRAND, i.CATEGORY1, i.CATEGORY2, i.CATEGORY3, i.CATEGORY4, i.IMAGE_URL
    ORDER BY COUNT(*) DESC, SUM(od2.AMOUNT) DESC, i.ID DESC;
    `,
    { itemId: id, limit: lim }
  );

  return rows;
}

export async function getItemSalesStats(itemId: number): Promise<{ soldQty: number; orders: number }> {
  const id = Number(itemId);
  if (!id) return { soldQty: 0, orders: 0 };

  const rows = await query<{ SoldQty: number | null; Orders: number | null }>(
    `
    SELECT
      SUM(od.AMOUNT) AS SoldQty,
      COUNT(DISTINCT od.ORDERID) AS Orders
    FROM dbo.ORDERDETAILS od
    WHERE od.ITEMID = @itemId;
    `,
    { itemId: id }
  );

  return {
    soldQty: Number(rows[0]?.SoldQty ?? 0),
    orders: Number(rows[0]?.Orders ?? 0),
  };
}

export async function createItemForAdmin(input: {
  itemCode: string;
  itemName: string;
  unitPrice: number;
  brand?: string | null;
  category1?: string | null;
  imageUrl?: string | null;
}) {
  const rows = await query<{ ID: number }>(
    `
    INSERT INTO dbo.ITEMS
      (ITEMCODE, ITEMNAME, UNITPRICE, BRAND, CATEGORY1, CATEGORY2, CATEGORY3, CATEGORY4, IMAGE_URL, ISACTIVE)
    OUTPUT INSERTED.ID AS ID
    VALUES
      (@itemCode, @itemName, @unitPrice, @brand, @category1, NULL, NULL, NULL, @imageUrl, 1);
    `,
    {
      itemCode: input.itemCode.trim(),
      itemName: input.itemName.trim(),
      unitPrice: Number(input.unitPrice),
      brand: (input.brand || "").trim() || null,
      category1: (input.category1 || "").trim() || null,
      imageUrl: (input.imageUrl || "").trim() || null,
    }
  );
  return Number(rows[0]?.ID ?? 0);
}

export async function deactivateItemForAdmin(itemId: number) {
  await query(
    `
    UPDATE dbo.ITEMS
    SET ISACTIVE = 0
    WHERE ID = @itemId;
    `,
    { itemId: Number(itemId) }
  );
}

export async function getItemCatalogStats() {
  const rows = await query<{ TotalItems: number | null; ActiveItems: number | null }>(
    `
    SELECT
      COUNT(*) AS TotalItems,
      SUM(CASE WHEN ISACTIVE = 1 THEN 1 ELSE 0 END) AS ActiveItems
    FROM dbo.ITEMS;
    `
  );

  return {
    totalItems: Number(rows[0]?.TotalItems ?? 0),
    activeItems: Number(rows[0]?.ActiveItems ?? 0),
  };
}

