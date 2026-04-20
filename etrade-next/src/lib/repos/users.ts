import { query } from "../db";

export type UserRow = {
  ID: number;
  USERNAME_: string | null;
  PASSWORD_: string | null;
  NAMESURNAME: string | null;
  EMAIL: string | null;
  GENDER?: string | null;
  BIRTHDATE?: Date | string | null;
  PHONE?: string | null;
};

export async function findUserByUsername(username: string) {
  const rows = await query<UserRow>(
    `
    SELECT TOP (1) ID, USERNAME_, PASSWORD_, NAMESURNAME, EMAIL
    FROM dbo.USERS
    WHERE USERNAME_ = @username
    `,
    { username }
  );
  return rows[0] ?? null;
}

// Allows logging in with either USERNAME_ or EMAIL.
export async function findUserByLogin(login: string) {
  const rows = await query<UserRow>(
    `
    SELECT TOP (1) ID, USERNAME_, PASSWORD_, NAMESURNAME, EMAIL
    FROM dbo.USERS
    WHERE USERNAME_ = @login OR EMAIL = @login
    `,
    { login }
  );
  return rows[0] ?? null;
}

export async function createUser(opts: {
  username: string;
  password: string;
  nameSurname?: string | null;
  email?: string | null;
  gender?: string | null;
  birthdate?: string | null; // expects YYYY-MM-DD from <input type="date" />
  phone?: string | null;
}) {
  const lengths = await getUsersColumnMaxLengths();
  const normalizeGender = (value: string | null | undefined) => {
    const raw = (value || "").trim().toLowerCase();
    if (!raw) return null;
    if (raw.startsWith("m")) return "M";
    if (raw.startsWith("f")) return "F";
    return "O";
  };
  const clip = (value: string | null | undefined, maxLen: number | undefined) => {
    if (value == null) return null;
    const normalized = String(value).trim();
    if (!normalized) return null;
    if (!maxLen || maxLen <= 0) return normalized;
    return normalized.slice(0, maxLen);
  };

  const safeUsername = clip(opts.username, lengths.USERNAME_);
  const safePassword = clip(opts.password, lengths.PASSWORD_);
  const safeNameSurname = clip(opts.nameSurname ?? null, lengths.NAMESURNAME);
  const safeEmail = clip(opts.email ?? null, lengths.EMAIL);
  const safeGender = clip(normalizeGender(opts.gender), lengths.GENDER);
  const safePhone = clip(opts.phone ?? null, lengths.PHONE);

  const rows = await query<{ ID: number }>(
    `
    INSERT INTO dbo.USERS
      (USERNAME_, PASSWORD_, NAMESURNAME, EMAIL, GENDER, BIRTHDATE, PHONE, CREATEDDATE)
    OUTPUT INSERTED.ID AS ID
    VALUES
      (@username, @password, @nameSurname, @email, @gender, @birthdate, @phone, GETDATE());
    `,
    {
      username: safeUsername,
      password: safePassword,
      nameSurname: safeNameSurname,
      email: safeEmail,
      gender: safeGender,
      birthdate: opts.birthdate ?? null,
      phone: safePhone,
    }
  );
  return Number(rows[0]?.ID);
}

export async function getUserProfileById(userId: number) {
  const rows = await query<UserRow>(
    `
    SELECT TOP (1)
      ID,
      USERNAME_,
      NAMESURNAME,
      EMAIL,
      GENDER,
      BIRTHDATE,
      PHONE
    FROM dbo.USERS
    WHERE ID = @userId
    `,
    { userId: Number(userId) }
  );
  const r = rows[0];
  if (!r) return null;
  return {
    id: Number(r.ID),
    username: r.USERNAME_ || "",
    nameSurname: r.NAMESURNAME || "",
    email: r.EMAIL || "",
    gender: r.GENDER || "",
    birthdate: r.BIRTHDATE ? new Date(r.BIRTHDATE).toISOString().slice(0, 10) : "",
    phone: r.PHONE || "",
  };
}

export async function updateUserProfileById(
  userId: number,
  opts: { nameSurname?: string; email?: string; gender?: string; birthdate?: string; phone?: string }
) {
  const rows = await query<UserRow>(
    `
    UPDATE dbo.USERS
    SET
      NAMESURNAME = @nameSurname,
      EMAIL = @email,
      GENDER = @gender,
      BIRTHDATE = CASE WHEN @birthdate = '' THEN NULL ELSE @birthdate END,
      PHONE = @phone
    OUTPUT INSERTED.ID, INSERTED.USERNAME_, INSERTED.NAMESURNAME, INSERTED.EMAIL
    WHERE ID = @userId;
    `,
    {
      userId: Number(userId),
      nameSurname: (opts.nameSurname || "").trim() || null,
      email: (opts.email || "").trim() || null,
      gender: (opts.gender || "").trim() || null,
      birthdate: (opts.birthdate || "").trim(),
      phone: (opts.phone || "").trim() || null,
    }
  );
  const r = rows[0];
  if (!r) return null;
  return {
    id: Number(r.ID),
    username: r.USERNAME_ || "",
    nameSurname: r.NAMESURNAME || "",
    email: r.EMAIL || "",
  };
}

export async function listUsersForAdmin() {
  const rows = await query<UserRow>(
    `
    SELECT
      ID,
      USERNAME_,
      NAMESURNAME,
      EMAIL
    FROM dbo.USERS
    ORDER BY ID DESC;
    `
  );

  return rows.map((r) => ({
    id: Number(r.ID),
    username: r.USERNAME_ || "",
    nameSurname: r.NAMESURNAME || "",
    email: r.EMAIL || "",
  }));
}

export async function changeUserPasswordById(userId: number, oldPassword: string, newPassword: string) {
  const rows = await query<{ ID: number }>(
    `
    UPDATE dbo.USERS
    SET PASSWORD_ = @newPassword
    OUTPUT INSERTED.ID
    WHERE ID = @userId
      AND PASSWORD_ = @oldPassword;
    `,
    {
      userId: Number(userId),
      oldPassword,
      newPassword,
    }
  );
  return Number(rows[0]?.ID || 0) > 0;
}

type UserColumnLengthRow = {
  ColumnName: string;
  MaxLen: number | null;
};

async function getUsersColumnMaxLengths() {
  const rows = await query<UserColumnLengthRow>(
    `
    SELECT
      c.name AS ColumnName,
      CASE WHEN c.max_length < 0 THEN 4000 ELSE c.max_length END AS MaxLen
    FROM sys.columns c
    INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
    WHERE c.object_id = OBJECT_ID('dbo.USERS')
      AND t.name IN ('varchar', 'nvarchar', 'char', 'nchar')
      AND c.name IN ('USERNAME_', 'PASSWORD_', 'NAMESURNAME', 'EMAIL', 'GENDER', 'PHONE');
    `
  );

  const byName = new Map(rows.map((r) => [r.ColumnName, Number(r.MaxLen ?? 0)]));
  return {
    USERNAME_: byName.get("USERNAME_"),
    PASSWORD_: byName.get("PASSWORD_"),
    NAMESURNAME: byName.get("NAMESURNAME"),
    EMAIL: byName.get("EMAIL"),
    GENDER: byName.get("GENDER"),
    PHONE: byName.get("PHONE"),
  };
}

