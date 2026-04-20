"use server";

import { revalidatePath } from "next/cache";

import { requireAuth } from "@/lib/requireAuth";
import { deactivateSavedCardForUser } from "@/lib/repos/cards";

export async function removeSavedCardAction(formData: FormData) {
  const user = await requireAuth();
  const cardId = Number(formData.get("cardId"));
  if (!cardId) return;
  await deactivateSavedCardForUser(user.id, cardId);
  revalidatePath("/account/cards");
}
