import { createHash } from "crypto";

import { query } from "../db";

export type SavedCard = {
  ID: number;
  USERID: number;
  CARDHOLDER: string | null;
  BRAND: string | null;
  LAST4: string | null;
  EXPMONTH: number | null;
  EXPYEAR: number | null;
  ISACTIVE: boolean | number | null;
};

export async function saveCardForUser(input: {
  userId: number;
  cardHolder: string;
  cardNumber: string;
  expMonth: number;
  expYear: number;
}) {
  const digits = input.cardNumber.replace(/\D/g, "");
  const last4 = digits.slice(-4);
  const cardHash = createHash("sha256").update(digits).digest("hex");
  const brand = detectCardBrand(digits);

  await query(
    `
    IF OBJECT_ID('dbo.USERCARDS', 'U') IS NULL
    BEGIN
      CREATE TABLE dbo.USERCARDS (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        USERID INT NOT NULL,
        CARDHOLDER NVARCHAR(120) NOT NULL,
        BRAND NVARCHAR(30) NULL,
        LAST4 VARCHAR(4) NOT NULL,
        EXPMONTH TINYINT NOT NULL,
        EXPYEAR SMALLINT NOT NULL,
        CARDHASH VARCHAR(64) NOT NULL,
        ISACTIVE BIT NOT NULL DEFAULT 1,
        CREATEDAT DATETIME NOT NULL DEFAULT GETDATE(),
        UPDATEDAT DATETIME NULL
      );
      CREATE INDEX IX_USERCARDS_USERID ON dbo.USERCARDS(USERID);
      CREATE UNIQUE INDEX UX_USERCARDS_USER_CARDHASH ON dbo.USERCARDS(USERID, CARDHASH);
    END;
    `
  );

  await query(
    `
    IF EXISTS (SELECT 1 FROM dbo.USERCARDS WHERE USERID = @userId AND CARDHASH = @cardHash)
    BEGIN
      UPDATE dbo.USERCARDS
      SET
        CARDHOLDER = @cardHolder,
        BRAND = @brand,
        LAST4 = @last4,
        EXPMONTH = @expMonth,
        EXPYEAR = @expYear,
        ISACTIVE = 1,
        UPDATEDAT = GETDATE()
      WHERE USERID = @userId AND CARDHASH = @cardHash;
    END
    ELSE
    BEGIN
      INSERT INTO dbo.USERCARDS (USERID, CARDHOLDER, BRAND, LAST4, EXPMONTH, EXPYEAR, CARDHASH, ISACTIVE)
      VALUES (@userId, @cardHolder, @brand, @last4, @expMonth, @expYear, @cardHash, 1);
    END
    `,
    {
      userId: Number(input.userId),
      cardHolder: input.cardHolder.trim().slice(0, 120),
      brand,
      last4,
      expMonth: Number(input.expMonth),
      expYear: Number(input.expYear),
      cardHash,
    }
  );
}

function detectCardBrand(digits: string): string {
  if (/^4\d{12,18}$/.test(digits)) return "VISA";
  if (/^5[1-5]\d{14}$/.test(digits) || /^2(2[2-9]|[3-6]\d|7[01])\d{12}$/.test(digits)) {
    return "MASTERCARD";
  }
  if (/^3[47]\d{13}$/.test(digits)) return "AMEX";
  if (/^62\d{14,17}$/.test(digits)) return "UNIONPAY";
  if (/^6(?:011|5\d{2})\d{12}$/.test(digits)) return "DISCOVER";
  return "CARD";
}

export async function listSavedCardsForUser(userId: number) {
  const rows = await query<SavedCard>(
    `
    SELECT
      ID, USERID, CARDHOLDER, BRAND, LAST4, EXPMONTH, EXPYEAR, ISACTIVE
    FROM dbo.USERCARDS
    WHERE USERID = @userId AND ISACTIVE = 1
    ORDER BY ID DESC;
    `,
    { userId: Number(userId) }
  );
  return rows.map((r) => ({
    id: Number(r.ID),
    userId: Number(r.USERID),
    cardHolder: r.CARDHOLDER || "",
    brand: (r.BRAND || "CARD").toUpperCase(),
    last4: r.LAST4 || "",
    expMonth: Number(r.EXPMONTH || 0),
    expYear: Number(r.EXPYEAR || 0),
  }));
}

export async function deactivateSavedCardForUser(userId: number, cardId: number) {
  await query(
    `
    UPDATE dbo.USERCARDS
    SET ISACTIVE = 0, UPDATEDAT = GETDATE()
    WHERE ID = @cardId AND USERID = @userId;
    `,
    { cardId: Number(cardId), userId: Number(userId) }
  );
}

export async function getSavedCardByIdForUser(userId: number, cardId: number) {
  const rows = await query<SavedCard>(
    `
    SELECT TOP (1)
      ID, USERID, CARDHOLDER, BRAND, LAST4, EXPMONTH, EXPYEAR, ISACTIVE
    FROM dbo.USERCARDS
    WHERE ID = @cardId AND USERID = @userId AND ISACTIVE = 1;
    `,
    { cardId: Number(cardId), userId: Number(userId) }
  );
  const r = rows[0];
  if (!r) return null;
  return {
    id: Number(r.ID),
    userId: Number(r.USERID),
    cardHolder: r.CARDHOLDER || "",
    brand: (r.BRAND || "CARD").toUpperCase(),
    last4: r.LAST4 || "",
    expMonth: Number(r.EXPMONTH || 0),
    expYear: Number(r.EXPYEAR || 0),
  };
}
