import sql from "mssql/msnodesqlv8";

let poolPromise: Promise<sql.ConnectionPool> | null = null;

export async function getPool() {
  if (poolPromise) return await poolPromise;

  const connectionString = process.env.MSSQL_CONNECTION_STRING;
  if (!connectionString) {
    throw new Error("MSSQL_CONNECTION_STRING is not set (use .env.local).");
  }

  poolPromise = sql.connect({ connectionString });
  return await poolPromise;
}

export async function query<TRecord extends Record<string, unknown>>(
  text: string,
  params: Record<string, unknown> = {}
): Promise<TRecord[]> {
  const pool = await getPool();
  const request = pool.request();
  for (const [name, value] of Object.entries(params)) {
    request.input(name, value);
  }
  const result = await request.query<TRecord>(text);
  return result.recordset ?? [];
}

export { sql };

