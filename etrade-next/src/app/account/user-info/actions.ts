"use server";

import { setUser } from "@/lib/auth";
import { requireAuth } from "@/lib/requireAuth";
import { changeUserPasswordById, updateUserProfileById } from "@/lib/repos/users";

export type UserInfoFormState = {
  error: string | null;
  success: string | null;
};

export type ChangePasswordFormState = {
  error: string | null;
  success: string | null;
};

export async function updateUserInfoAction(
  _prev: UserInfoFormState,
  formData: FormData
): Promise<UserInfoFormState> {
  const user = await requireAuth();

  const nameSurname = String(formData.get("nameSurname") ?? "").trim();
  const email = String(formData.get("email") ?? "").trim();
  const gender = String(formData.get("gender") ?? "").trim();
  const birthdate = String(formData.get("birthdate") ?? "").trim();
  const phoneCode = String(formData.get("phoneCode") ?? "+90").trim() || "+90";
  const phoneNumber = String(formData.get("phoneNumber") ?? "").trim().replace(/\s+/g, "");
  const fallbackPhone = String(formData.get("phone") ?? "").trim();
  const phone = (phoneNumber ? `${phoneCode}${phoneNumber}` : fallbackPhone).trim();

  if (!nameSurname) return { error: "Full name is required.", success: null };
  if (email && !email.includes("@")) return { error: "Please enter a valid email.", success: null };

  const updated = await updateUserProfileById(user.id, {
    nameSurname,
    email,
    gender,
    birthdate,
    phone,
  });
  if (!updated) return { error: "Could not update your profile.", success: null };

  await setUser({
    id: updated.id,
    username: updated.username,
    nameSurname: updated.nameSurname,
  });

  return { error: null, success: "Your profile has been updated." };
}

export async function changePasswordAction(
  _prev: ChangePasswordFormState,
  formData: FormData
): Promise<ChangePasswordFormState> {
  const user = await requireAuth();

  const oldPassword = String(formData.get("oldPassword") ?? "");
  const newPassword = String(formData.get("newPassword") ?? "");
  const confirmPassword = String(formData.get("confirmPassword") ?? "");

  if (!oldPassword) return { error: "Current password is required.", success: null };
  if (!newPassword) return { error: "New password is required.", success: null };
  if (newPassword.length > 50) return { error: "New password must be at most 50 characters.", success: null };
  if (newPassword !== confirmPassword) return { error: "New passwords do not match.", success: null };
  if (oldPassword === newPassword) return { error: "New password must be different from current password.", success: null };

  const updated = await changeUserPasswordById(user.id, oldPassword, newPassword);
  if (!updated) return { error: "Current password is incorrect.", success: null };

  return { error: null, success: "Your password has been updated." };
}
