import { query } from "../db";

export type OptionRow = { ID: number; Name: string };

export async function listCountries() {
  return await query<OptionRow>(
    `
    SELECT ID, COUNTRY AS Name
    FROM dbo.COUNTRIES
    ORDER BY COUNTRY ASC;
    `
  );
}

export async function listCities(countryId: number) {
  return await query<OptionRow>(
    `
    SELECT ID, CITY AS Name
    FROM dbo.CITIES
    WHERE COUNTRYID = @countryId
    ORDER BY CITY ASC;
    `,
    { countryId: Number(countryId) }
  );
}

export async function listTowns(cityId: number) {
  return await query<OptionRow>(
    `
    SELECT ID, TOWN AS Name
    FROM dbo.TOWNS
    WHERE CITYID = @cityId
    ORDER BY TOWN ASC;
    `,
    { cityId: Number(cityId) }
  );
}

export async function listDistricts(townId: number) {
  return await query<OptionRow>(
    `
    SELECT ID, DISTRICT AS Name
    FROM dbo.DISTRICTS
    WHERE TOWNID = @townId
    ORDER BY DISTRICT ASC;
    `,
    { townId: Number(townId) }
  );
}

