import { query } from "../db";

type FavoriteRow = {
  ITEMID: number;
  ISACTIVE: boolean | number | null;
};

async function ensureFavoritesTable() {
  await query(
    `
    IF OBJECT_ID('dbo.FAVORITES', 'U') IS NULL
    BEGIN
      CREATE TABLE dbo.FAVORITES (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        USERID INT NOT NULL,
        ITEMID INT NOT NULL,
        ISACTIVE BIT NOT NULL DEFAULT 1,
        CREATEDAT DATETIME NOT NULL DEFAULT GETDATE(),
        UPDATEDAT DATETIME NULL
      );
      CREATE UNIQUE INDEX UX_FAVORITES_USER_ITEM ON dbo.FAVORITES(USERID, ITEMID);
      CREATE INDEX IX_FAVORITES_USER ON dbo.FAVORITES(USERID);
    END;
    `
  );
}

export async function listFavoriteItemIdsForUser(userId: number): Promise<number[]> {
  await ensureFavoritesTable();
  const rows = await query<FavoriteRow>(
    `
    SELECT ITEMID, ISACTIVE
    FROM dbo.FAVORITES
    WHERE USERID = @userId AND ISACTIVE = 1
    ORDER BY ID DESC;
    `,
    { userId: Number(userId) }
  );
  return rows.map((r) => Number(r.ITEMID)).filter((n) => Number.isFinite(n) && n > 0);
}

export async function toggleFavoriteForUser(userId: number, itemId: number): Promise<number[]> {
  await ensureFavoritesTable();
  await query(
    `
    IF EXISTS (SELECT 1 FROM dbo.FAVORITES WHERE USERID = @userId AND ITEMID = @itemId)
    BEGIN
      UPDATE dbo.FAVORITES
      SET
        ISACTIVE = CASE WHEN ISACTIVE = 1 THEN 0 ELSE 1 END,
        UPDATEDAT = GETDATE()
      WHERE USERID = @userId AND ITEMID = @itemId;
    END
    ELSE
    BEGIN
      INSERT INTO dbo.FAVORITES (USERID, ITEMID, ISACTIVE)
      VALUES (@userId, @itemId, 1);
    END
    `,
    { userId: Number(userId), itemId: Number(itemId) }
  );
  return await listFavoriteItemIdsForUser(userId);
}
