export function encodeJsonCookie(value: unknown) {
  return Buffer.from(JSON.stringify(value), "utf8").toString("base64url");
}

export function decodeJsonCookie<T>(value: string | undefined) {
  if (!value) return null;
  try {
    const json = Buffer.from(value, "base64url").toString("utf8");
    return JSON.parse(json) as T;
  } catch {
    return null;
  }
}

