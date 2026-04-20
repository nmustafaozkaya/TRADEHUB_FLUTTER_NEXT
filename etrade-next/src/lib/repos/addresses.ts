import { query } from "../db";

export type AddressRow = {
  ID: number;
  AddressText: string | null;
  PostalCode: string | null;
  Country: string | null;
  City: string | null;
  Town: string | null;
  District: string | null;
};

export async function listAddressesForUser(userId: number) {
  const rows = await query<AddressRow>(
    `
    SELECT
      a.ID,
      a.ADDRESSTEXT AS AddressText,
      a.POSTALCODE AS PostalCode,
      co.COUNTRY AS Country,
      ci.CITY AS City,
      t.TOWN AS Town,
      d.DISTRICT AS District
    FROM dbo.ADDRESS a
    LEFT JOIN dbo.COUNTRIES co ON co.ID = a.COUNTRYID
    LEFT JOIN dbo.CITIES ci ON ci.ID = a.CITYID
    LEFT JOIN dbo.TOWNS t ON t.ID = a.TOWNID
    LEFT JOIN dbo.DISTRICTS d ON d.ID = a.DISTRICTID
    WHERE a.USERID = @userId
    ORDER BY a.ID DESC;
    `,
    { userId: Number(userId) }
  );
  return rows;
}

export async function createAddressForUser(opts: {
  userId: number;
  countryId: number;
  cityId: number;
  townId: number;
  districtId: number;
  postalCode?: string | null;
  addressText: string;
}) {
  const rows = await query<{ ID: number }>(
    `
    INSERT INTO dbo.ADDRESS (USERID, COUNTRYID, CITYID, TOWNID, DISTRICTID, POSTALCODE, ADDRESSTEXT)
    OUTPUT INSERTED.ID AS ID
    VALUES (@userId, @countryId, @cityId, @townId, @districtId, @postalCode, @addressText);
    `,
    {
      userId: Number(opts.userId),
      countryId: Number(opts.countryId),
      cityId: Number(opts.cityId),
      townId: Number(opts.townId),
      districtId: Number(opts.districtId),
      postalCode: opts.postalCode ?? null,
      addressText: String(opts.addressText),
    }
  );
  return Number(rows[0]?.ID);
}

export async function deleteAddressForUser(userId: number, addressId: number) {
  const rows = await query<{ Affected: number }>(
    `
    DELETE FROM dbo.ADDRESS
    OUTPUT 1 AS Affected
    WHERE USERID = @userId AND ID = @addressId;
    `,
    { userId: Number(userId), addressId: Number(addressId) }
  );
  return rows.length ? 1 : 0;
}

