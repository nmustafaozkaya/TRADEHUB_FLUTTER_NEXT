"use server";

import { redirect } from "next/navigation";

import { clearUser, setUser } from "@/lib/auth";
import { createUser, findUserByLogin, findUserByUsername } from "@/lib/repos/users";

type FormState = { error: string | null };
type RegisterValues = {
  username: string;
  password: string;
  nameSurname: string;
  email: string;
  gender: string;
  birthYear: string;
  birthMonth: string;
  birthDay: string;
  phoneCode: string;
  phoneNumber: string;
};
type RegisterFormState = {
  error: string | null;
  values: RegisterValues;
};

function readRegisterValues(formData: FormData): RegisterValues {
  return {
    username: String(formData.get("username") || "").trim(),
    password: String(formData.get("password") || ""),
    nameSurname: String(formData.get("nameSurname") || "").trim(),
    email: String(formData.get("email") || "").trim(),
    gender: String(formData.get("gender") || "").trim(),
    birthYear: String(formData.get("birthYear") || "").trim(),
    birthMonth: String(formData.get("birthMonth") || "").trim(),
    birthDay: String(formData.get("birthDay") || "").trim(),
    phoneCode: String(formData.get("phoneCode") || "").trim(),
    phoneNumber: String(formData.get("phoneNumber") || "").trim(),
  };
}

function safeNextPath(raw: unknown): string | null {
  const nextPath = typeof raw === "string" ? raw.trim() : "";
  if (!nextPath) return null;
  if (!nextPath.startsWith("/")) return null;
  if (nextPath.startsWith("//")) return null;
  return nextPath;
}

export async function loginAction(_prevState: FormState, formData: FormData): Promise<FormState> {
  let nextPath: string | null = null;
  try {
    const login = String(formData.get("username") || "").trim(); // field name remains "username" in the UI
    const password = String(formData.get("password") || "");
    nextPath = safeNextPath(formData.get("next"));

    const plainOk = String(process.env.AUTH_PLAIN_OK || "true").toLowerCase() === "true";
    if (!plainOk) return { error: "AUTH_PLAIN_OK=false. This app uses plain-text passwords." };

    if (!login || !password) return { error: "Username/email and password are required." };

    const user = await findUserByLogin(login);
    if (!user) return { error: "User not found." };
    if ((user.PASSWORD_ || "") !== password) return { error: "Incorrect password." };

    await setUser({
      id: user.ID,
      username: user.USERNAME_ || login,
      nameSurname: user.NAMESURNAME,
    });
  } catch {
    return { error: "Sign in failed." };
  }

  redirect(nextPath || "/items");
}

export async function registerAction(_prevState: RegisterFormState, formData: FormData): Promise<RegisterFormState> {
  const values = readRegisterValues(formData);
  try {
    const username = values.username;
    const password = values.password;
    const nameSurname = values.nameSurname || null;
    const email = values.email || null;
    const gender = values.gender || null;
    const birthYear = values.birthYear;
    const birthMonth = values.birthMonth;
    const birthDay = values.birthDay;
    const birthdateCombined = [birthYear, birthMonth, birthDay].every((x) => x)
      ? `${birthYear}-${birthMonth}-${birthDay}`
      : "";
    const birthdate = String(formData.get("birthdate") || birthdateCombined).trim() || null;
    const phoneCode = values.phoneCode;
    const phoneNumber = values.phoneNumber;
    const phoneCombined = `${phoneCode}${phoneNumber}`.trim();
    const phone = String(formData.get("phone") || phoneCombined).trim() || null;

    if (!username || !password) return { error: "Username and password are required.", values };
    if (password.length > 50) return { error: "Password must be at most 50 characters (DB limit).", values };
    if (username.length > 50) return { error: "Username is too long (max 50).", values };
    if ((nameSurname || "").length > 100) return { error: "Full name is too long (max 100).", values };
    if ((email || "").length > 100) return { error: "Email is too long (max 100).", values };
    if ((gender || "").length > 20) return { error: "Gender value is too long.", values };
    if ((phone || "").length > 30) return { error: "Phone number is too long.", values };
    // If the DB columns are defined as NOT NULL, this validation prevents registration failures.
    if (!gender || !birthdate || !phone) {
      return { error: "Gender, birthdate and phone number are required.", values };
    }

    const existing = await findUserByUsername(username);
    if (existing) return { error: "This username is already taken.", values };

    const id = await createUser({
      username,
      password,
      nameSurname,
      email,
      gender,
      birthdate,
      phone,
    });
    await setUser({ id, username, nameSurname });
  } catch (error) {
    const rawMessage =
      error instanceof Error ? error.message : "Registration failed.";
    const lower = rawMessage.toLowerCase();
    if (lower.includes("truncated") || lower.includes("string or binary data")) {
      return {
        error: "One or more fields exceed database limits. Please shorten username/email/phone.",
        values,
      };
    }
    if (lower.includes("conversion") || lower.includes("date")) {
      return {
        error: "Birth date format is invalid. Please select Year / Month / Day again.",
        values,
      };
    }
    return { error: rawMessage || "Registration failed.", values };
  }

  redirect("/items");
}

export async function logoutAction() {
  await clearUser();
  redirect("/items");
}

