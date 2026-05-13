import { query } from "../db";

export type ItemReviewSummary = {
  averageRating: number;
  totalReviews: number;
};

export type ItemReviewRow = {
  id: number;
  rating: number;
  comment: string;
  createdAt: string;
  reviewer: string;
};

export type UserReviewRow = {
  id: number;
  orderId: number;
  itemId: number;
  itemName: string;
  brand: string;
  rating: number;
  comment: string;
  createdAt: string;
};

function maskReviewerName(input: string): string {
  const raw = String(input || "").trim().replace(/\s+/g, " ");
  if (!raw) return "an*** us***";
  const parts = raw.split(" ").filter(Boolean);

  const maskPart = (part: string) => {
    const p = part.trim();
    if (!p) return "";
    if (p.length === 1) return `${p.toLowerCase()}***`;
    if (p.length === 2) return `${p[0].toLowerCase()}${p[1].toLowerCase()}***`;
    return `${p.slice(0, 2).toLowerCase()}***`;
  };

  if (parts.length === 1) return maskPart(parts[0]);
  return `${maskPart(parts[0])} ${maskPart(parts[parts.length - 1])}`;
}

export async function getItemReviewSummary(itemId: number): Promise<ItemReviewSummary> {
  const id = Number(itemId);
  if (!id) return { averageRating: 0, totalReviews: 0 };

  const rows = await query<{ AvgRating: number | null; TotalReviews: number | null }>(
    `
    SELECT
      AVG(CAST(r.RATING AS FLOAT)) AS AvgRating,
      COUNT(*) AS TotalReviews
    FROM dbo.REVIEWS r
    WHERE r.ITEMID = @itemId
      AND r.ISACTIVE = 1;
    `,
    { itemId: id }
  );

  return {
    averageRating: Number(rows[0]?.AvgRating ?? 0),
    totalReviews: Number(rows[0]?.TotalReviews ?? 0),
  };
}

export async function listReviewSummariesByItemIds(
  itemIds: number[]
): Promise<Record<number, ItemReviewSummary>> {
  const uniq = Array.from(
    new Set(itemIds.map((x) => Number(x)).filter((n) => Number.isFinite(n) && n > 0))
  ).slice(0, 500);
  if (!uniq.length) return {};

  const params: Record<string, unknown> = {};
  const placeholders = uniq.map((id, idx) => {
    const key = `itemId${idx}`;
    params[key] = id;
    return `@${key}`;
  });

  const rows = await query<{ ItemId: number; AvgRating: number | null; TotalReviews: number | null }>(
    `
    SELECT
      r.ITEMID AS ItemId,
      AVG(CAST(r.RATING AS FLOAT)) AS AvgRating,
      COUNT(*) AS TotalReviews
    FROM dbo.REVIEWS r
    WHERE r.ISACTIVE = 1
      AND r.ITEMID IN (${placeholders.join(",")})
    GROUP BY r.ITEMID;
    `,
    params
  );

  const out: Record<number, ItemReviewSummary> = {};
  for (const id of uniq) {
    out[id] = { averageRating: 0, totalReviews: 0 };
  }
  for (const row of rows) {
    const id = Number(row.ItemId);
    if (!id) continue;
    out[id] = {
      averageRating: Number(row.AvgRating ?? 0),
      totalReviews: Number(row.TotalReviews ?? 0),
    };
  }
  return out;
}

export async function listItemReviews(itemId: number, limit = 10): Promise<ItemReviewRow[]> {
  const id = Number(itemId);
  if (!id) return [];
  const safeLimit = Math.min(30, Math.max(1, Number(limit) || 10));

  const rows = await query<{
    ID: number;
    Rating: number;
    Comment: string | null;
    CreatedAt: Date | null;
    ReviewerName: string | null;
  }>(
    `
    SELECT TOP (@limit)
      r.ID,
      CAST(r.RATING AS INT) AS Rating,
      r.COMMENT AS Comment,
      r.CREATEDAT AS CreatedAt,
      COALESCE(NULLIF(u.NAMESURNAME, ''), NULLIF(u.USERNAME_, ''), 'anonymous') AS ReviewerName
    FROM dbo.REVIEWS r
    LEFT JOIN dbo.USERS u ON u.ID = r.USERID
    WHERE r.ITEMID = @itemId
      AND r.ISACTIVE = 1
    ORDER BY r.CREATEDAT DESC, r.ID DESC;
    `,
    { itemId: id, limit: safeLimit }
  );

  return rows.map((r) => ({
    id: Number(r.ID ?? 0),
    rating: Number(r.Rating ?? 0),
    comment: String(r.Comment ?? "").trim(),
    createdAt: r.CreatedAt ? new Date(r.CreatedAt).toISOString() : "",
    reviewer: maskReviewerName(String(r.ReviewerName ?? "")),
  }));
}

export async function createReviewForPurchasedItem(input: {
  userId: number;
  itemId: number;
  rating: number;
  comment: string;
}): Promise<
  | { ok: true; mode: "created" | "updated" }
  | { ok: false; reason: "not_purchased" | "invalid" }
> {
  const userId = Number(input.userId);
  const itemId = Number(input.itemId);
  const rating = Math.max(1, Math.min(5, Math.round(Number(input.rating))));
  const comment = String(input.comment || "").trim();

  if (!userId || !itemId || !comment || comment.length < 3) {
    return { ok: false, reason: "invalid" };
  }

  // Prefer an eligible order line that does not have an active review yet.
  // This enables reviewing the same item again when it was bought in a different order.
  const unreviewedOrder = await query<{ OrderId: number }>(
    `
    SELECT TOP (1) o.ID AS OrderId
    FROM dbo.ORDERS o
    INNER JOIN dbo.ORDERDETAILS od ON od.ORDERID = o.ID
    WHERE o.USERID = @userId
      AND od.ITEMID = @itemId
      AND o.STATUS_ IN (3, 5)
      AND NOT EXISTS (
        SELECT 1
        FROM dbo.REVIEWS r
        WHERE r.USERID = @userId
          AND r.ORDERID = o.ID
          AND r.ITEMID = @itemId
          AND r.ISACTIVE = 1
      )
    ORDER BY o.DATE_ DESC, o.ID DESC;
    `,
    { userId, itemId }
  );
  const unreviewedOrderId = Number(unreviewedOrder[0]?.OrderId ?? 0);

  if (unreviewedOrderId > 0) {
    await query(
      `
      INSERT INTO dbo.REVIEWS
        (USERID, ORDERID, ITEMID, RATING, COMMENT, ISACTIVE, CREATEDAT)
      VALUES
        (@userId, @orderId, @itemId, @rating, @comment, 1, GETDATE());
      `,
      { userId, orderId: unreviewedOrderId, itemId, rating, comment }
    );
    return { ok: true, mode: "created" };
  }

  const eligible = await query<{ OrderId: number }>(
    `
    SELECT TOP (1) o.ID AS OrderId
    FROM dbo.ORDERS o
    INNER JOIN dbo.ORDERDETAILS od ON od.ORDERID = o.ID
    WHERE o.USERID = @userId
      AND od.ITEMID = @itemId
      AND o.STATUS_ IN (3, 5) -- delivered or completed
    ORDER BY o.DATE_ DESC, o.ID DESC;
    `,
    { userId, itemId }
  );

  const orderId = Number(eligible[0]?.OrderId ?? 0);
  if (!orderId) return { ok: false, reason: "not_purchased" };

  // All eligible orders already reviewed: update the most recent active review.
  const existing = await query<{ ID: number }>(
    `
    SELECT TOP (1) r.ID
    FROM dbo.REVIEWS r
    INNER JOIN dbo.ORDERS o ON o.ID = r.ORDERID
    WHERE r.USERID = @userId
      AND r.ITEMID = @itemId
      AND r.ISACTIVE = 1
      AND o.USERID = @userId
      AND o.STATUS_ IN (3, 5)
    ORDER BY o.DATE_ DESC, o.ID DESC, r.CREATEDAT DESC, r.ID DESC;
    `,
    { userId, itemId }
  );

  const existingId = Number(existing[0]?.ID ?? 0);
  if (existingId > 0) {
    await query(
      `
      UPDATE dbo.REVIEWS
      SET
        RATING = @rating,
        COMMENT = @comment,
        UPDATEDAT = GETDATE()
      WHERE ID = @id;
      `,
      { id: existingId, rating, comment }
    );
    return { ok: true, mode: "updated" };
  }

  // Fallback insert for edge cases.
  await query(
    `
    INSERT INTO dbo.REVIEWS
      (USERID, ORDERID, ITEMID, RATING, COMMENT, ISACTIVE, CREATEDAT)
    VALUES
      (@userId, @orderId, @itemId, @rating, @comment, 1, GETDATE());
    `,
    { userId, orderId, itemId, rating, comment }
  );

  return { ok: true, mode: "created" };
}

export async function listReviewsForUser(userId: number): Promise<UserReviewRow[]> {
  const id = Number(userId);
  if (!id) return [];

  const rows = await query<{
    ID: number;
    ORDERID: number;
    ITEMID: number;
    ITEMNAME: string | null;
    BRAND: string | null;
    RATING: number;
    COMMENT: string | null;
    CREATEDAT: Date | null;
  }>(
    `
    SELECT TOP (200)
      r.ID,
      r.ORDERID,
      r.ITEMID,
      i.ITEMNAME,
      i.BRAND,
      r.RATING,
      r.COMMENT,
      r.CREATEDAT
    FROM dbo.REVIEWS r
    LEFT JOIN dbo.ITEMS i ON i.ID = r.ITEMID
    WHERE r.USERID = @userId
      AND r.ISACTIVE = 1
    ORDER BY r.CREATEDAT DESC, r.ID DESC;
    `,
    { userId: id }
  );

  return rows.map((r) => ({
    id: Number(r.ID ?? 0),
    orderId: Number(r.ORDERID ?? 0),
    itemId: Number(r.ITEMID ?? 0),
    itemName: String(r.ITEMNAME ?? `Item #${Number(r.ITEMID ?? 0)}`),
    brand: String(r.BRAND ?? ""),
    rating: Number(r.RATING ?? 0),
    comment: String(r.COMMENT ?? "").trim(),
    createdAt: r.CREATEDAT ? new Date(r.CREATEDAT).toISOString() : "",
  }));
}

