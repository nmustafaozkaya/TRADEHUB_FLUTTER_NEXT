"use server";

import { redirect } from "next/navigation";

import { clearCart, getCart } from "@/lib/cart";
import { getUser } from "@/lib/auth";
import { createOrder } from "@/lib/repos/orders";
import { getSavedCardByIdForUser, saveCardForUser } from "@/lib/repos/cards";
import { isPaymentMethod } from "@/lib/payment";

type FormState = { error: string | null };

export async function placeOrderAction(_prev: FormState, formData: FormData): Promise<FormState> {
  const user = await getUser();
  if (!user) redirect("/auth/login");

  const cart = await getCart();
  if (!cart.lines.length) return { error: "Your cart is empty." };

  const addressId = Number(formData.get("addressId"));
  if (!addressId) return { error: "Please select a delivery address." };

  const paymentMethodRaw = String(formData.get("paymentMethod") ?? "");
  if (!isPaymentMethod(paymentMethodRaw)) {
    return { error: "Please select a valid payment method." };
  }

  if (paymentMethodRaw === "card") {
    const selectedSavedCardId = Number(formData.get("selectedSavedCardId") ?? 0);
    const selectedSavedCard = selectedSavedCardId
      ? await getSavedCardByIdForUser(user.id, selectedSavedCardId)
      : null;

    const cardHolder = String(formData.get("cardHolder") ?? "").trim();
    const cardNumberRaw = String(formData.get("cardNumber") ?? "");
    const cardNumber = cardNumberRaw.replace(/\D/g, "");
    const expDateRaw = String(formData.get("expDate") ?? "").trim();
    const expiry = parseExpiry(expDateRaw);
    const cvv = String(formData.get("cvv") ?? "").replace(/\D/g, "");
    const saveCard = String(formData.get("saveCard") ?? "") === "on";

    if (!selectedSavedCard) {
      if (cardHolder.length < 3) return { error: "Please enter the card holder name." };
      if (!/^\d{12,19}$/.test(cardNumber) || !isLuhnValid(cardNumber)) {
        return { error: "Please enter a valid card number." };
      }
      if (!expiry) {
        return { error: "Please enter a valid expiry date (MM/YY)." };
      }
      if (!/^\d{3,4}$/.test(cvv)) return { error: "Please enter a valid CVV." };

      if (saveCard) {
        await saveCardForUser({
          userId: user.id,
          cardHolder,
          cardNumber,
          expMonth: expiry.month,
          expYear: expiry.year,
        });
      }
    }
  }

  const orderId = await createOrder({
    userId: user.id,
    addressId,
    paymentMethod: paymentMethodRaw,
    lines: cart.lines,
  });

  await clearCart();
  redirect(`/checkout/thanks?orderId=${orderId}`);
}

function isLuhnValid(cardNumber: string) {
  let sum = 0;
  let shouldDouble = false;
  for (let i = cardNumber.length - 1; i >= 0; i -= 1) {
    let digit = Number(cardNumber[i]);
    if (shouldDouble) {
      digit *= 2;
      if (digit > 9) digit -= 9;
    }
    sum += digit;
    shouldDouble = !shouldDouble;
  }
  return sum % 10 === 0;
}

function parseExpiry(value: string): { month: number; year: number } | null {
  const m = value.match(/^(\d{2})\s*\/\s*(\d{2})$/);
  if (!m) return null;

  const month = Number(m[1]);
  const yy = Number(m[2]);
  const year = 2000 + yy;
  if (!Number.isInteger(month) || month < 1 || month > 12) return null;

  const now = new Date();
  const currentMonth = now.getMonth() + 1;
  const currentYear = now.getFullYear();
  if (year < currentYear) return null;
  if (year === currentYear && month < currentMonth) return null;
  if (year > currentYear + 20) return null;

  return { month, year };
}

