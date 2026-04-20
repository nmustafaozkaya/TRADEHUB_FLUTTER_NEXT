"use client";

import { useActionState, useState } from "react";
import { placeOrderAction } from "../actions";
import { CheckoutAddressPicker } from "@/components/CheckoutAddressPicker";
import { PAYMENT_METHODS, type PaymentMethod } from "@/lib/payment";
import { cn } from "@/lib/ui";

export function CheckoutForm(props: {
  formId?: string;
  addresses: { ID: number; AddressText: string | null; Country: string | null; City: string | null; Town: string | null; District: string | null }[];
  savedCards: { id: number; cardHolder: string; brand: string; last4: string; expMonth: number; expYear: number }[];
  userId: number;
  children?: React.ReactNode;
}) {
  const [state, formAction, pending] = useActionState(placeOrderAction, { error: null });
  const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>("card");
  const [cardNumber, setCardNumber] = useState("");
  const [expDate, setExpDate] = useState("");
  const [selectedSavedCardId, setSelectedSavedCardId] = useState<number>(0);

  const bankAccounts = [
    {
      bank: "Ziraat Bankasi",
      iban: "TR49 0001 0001 5800 0012 3456 78",
      accountName: "TradeHub E-Commerce A.S.",
      branch: "Istanbul Levent Branch",
    },
    {
      bank: "Is Bankasi",
      iban: "TR61 0006 4000 0091 2345 6789 01",
      accountName: "TradeHub Marketplace Ltd.",
      branch: "Ankara Cankaya Branch",
    },
    {
      bank: "Yapi Kredi",
      iban: "TR72 0067 8000 0001 2345 6789 90",
      accountName: "TradeHub Digital Commerce",
      branch: "Izmir Konak Branch",
    },
    {
      bank: "Garanti BBVA",
      iban: "TR33 0062 1000 1234 5678 9012 34",
      accountName: "TradeHub Online Stores",
      branch: "Bursa Nilufer Branch",
    },
  ] as const;
  const [selectedBankAccount] = useState(
    () => bankAccounts[Math.floor(Math.random() * bankAccounts.length)]
  );
  const maskedIban = `${selectedBankAccount.iban.slice(0, -5)}XXXXX`;

  const cardBrand = detectCardBrand(cardNumber.replace(/\D/g, ""));
  const paymentOptions = [
    {
      id: "card",
      title: "Pay by card",
      description: "Use your debit/credit card. This is a demo flow and no real charge will be made.",
    },
    {
      id: "transfer",
      title: "Bank transfer / EFT",
      description: "Place the order now, then complete payment by bank transfer.",
    },
    {
      id: "cod",
      title: "Cash on delivery",
      description: "Pay with cash/card when the courier delivers the order.",
    },
  ] as const satisfies ReadonlyArray<{
    id: (typeof PAYMENT_METHODS)[number];
    title: string;
    description: string;
  }>;

  return (
    <form id={props.formId} action={formAction} className="space-y-4">
      {state.error ? (
        <div className="rounded-xl border border-rose-400/30 bg-rose-400/10 px-3 py-2 text-sm text-rose-100">
          {state.error}
        </div>
      ) : null}

      <CheckoutAddressPicker addresses={props.addresses} name="addressId" inputName="addressId" />

      <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
        <div className="text-sm font-bold text-slate-100">Payment method</div>
        <div className="mt-1 text-xs text-slate-400">Payment is a UI preview in this MVP.</div>

        <div className="mt-3 grid gap-2">
          {paymentOptions.map((option) => {
            const isSelected = paymentMethod === option.id;
            return (
              <div
                key={option.id}
                className={cn(
                  "rounded-2xl border border-white/10 bg-slate-950/30 p-3 hover:bg-white/5",
                  isSelected ? "border-sky-400/30 bg-sky-400/10" : "",
                  pending ? "opacity-70" : ""
                )}
              >
                <label className="flex cursor-pointer items-start justify-between gap-3">
                  <div className="flex items-start gap-3">
                    <input
                      type="radio"
                      name="paymentMethod"
                      value={option.id}
                      checked={isSelected}
                      onChange={() => setPaymentMethod(option.id)}
                      className="mt-1 h-4 w-4 accent-sky-400"
                    />
                    <div>
                      <div className="flex items-center gap-2">
                        <div className="text-sm font-semibold text-slate-100">{option.title}</div>
                        {option.id === "card" ? (
                          <div className="flex items-center gap-2">
                            {cardBrand === "unknown" ? (
                              <>
                                <img src="/payment/visa.svg" alt="Visa" className="h-12 w-20 rounded-sm object-contain" />
                                <img src="/payment/mastercard.svg" alt="Mastercard" className="h-12 w-20 rounded-sm object-contain" />
                                <img src="/payment/amex.svg" alt="American Express" className="h-12 w-20 rounded-sm object-contain" />
                                <img src="/payment/unionpay.svg" alt="China UnionPay" className="h-12 w-20 rounded-sm object-contain" />
                              </>
                            ) : cardBrand === "visa" ? (
                              <img src="/payment/visa.svg" alt="Visa" className="h-12 w-20 rounded-sm object-contain" />
                            ) : cardBrand === "mastercard" ? (
                              <img src="/payment/mastercard.svg" alt="Mastercard" className="h-12 w-20 rounded-sm object-contain" />
                            ) : cardBrand === "unionpay" ? (
                              <img src="/payment/unionpay.svg" alt="China UnionPay" className="h-12 w-20 rounded-sm object-contain" />
                            ) : (
                              <img src="/payment/amex.svg" alt="American Express" className="h-12 w-20 rounded-sm object-contain" />
                            )}
                          </div>
                        ) : null}
                      </div>
                      <div className="mt-1 text-xs text-slate-400">{option.description}</div>
                    </div>
                  </div>
                  <div className={cn("text-xs font-semibold", isSelected ? "text-sky-200" : "text-slate-400")}>
                    {isSelected ? "Selected" : "Select"}
                  </div>
                </label>

                {option.id === "card" && isSelected ? (
                  <div className="mt-3 border-t border-white/10 pt-3">
                    {props.savedCards.length ? (
                      <div className="mb-3 rounded-xl border border-white/10 bg-white/5 p-3">
                        <div className="text-xs font-semibold text-slate-200">Saved cards</div>
                        <div className="mt-2 grid gap-2">
                          {props.savedCards.map((c) => {
                            const checked = selectedSavedCardId === c.id;
                            const exp = `${String(c.expMonth).padStart(2, "0")}/${String(c.expYear).slice(-2)}`;
                            return (
                              <label
                                key={c.id}
                                className={cn(
                                  "flex cursor-pointer items-center justify-between rounded-xl border px-3 py-2 text-xs",
                                  checked
                                    ? "border-sky-400/40 bg-sky-400/10 text-sky-100"
                                    : "border-white/10 bg-slate-950/30 text-slate-300"
                                )}
                              >
                                <div className="flex items-center gap-2">
                                  <input
                                    type="radio"
                                    name="savedCardChoice"
                                    checked={checked}
                                    onChange={() => setSelectedSavedCardId(c.id)}
                                    className="h-4 w-4 accent-sky-400"
                                  />
                                  <span>{c.brand} **** {c.last4}</span>
                                </div>
                                <span>{c.cardHolder} · {exp}</span>
                              </label>
                            );
                          })}
                        </div>
                        <button
                          type="button"
                          onClick={() => setSelectedSavedCardId(0)}
                          className="mt-2 text-xs text-slate-400 underline-offset-2 hover:underline"
                        >
                          Use a new card instead
                        </button>
                      </div>
                    ) : null}

                    <input type="hidden" name="selectedSavedCardId" value={selectedSavedCardId || ""} />

                    {selectedSavedCardId ? (
                      <div className="rounded-xl border border-emerald-400/25 bg-emerald-400/10 px-3 py-2 text-xs text-emerald-100">
                        Saved card selected. You can place the order directly.
                      </div>
                    ) : null}

                    {!selectedSavedCardId ? (
                    <div className="grid gap-2 md:grid-cols-2">
                      <div className="md:col-span-2">
                        <label className="text-xs text-slate-300">Card holder</label>
                        <input
                          name="cardHolder"
                          placeholder="Name Surname"
                          autoComplete="cc-name"
                          className="mt-1 w-full rounded-xl border border-white/10 bg-slate-950/40 px-3 py-2 text-sm text-slate-100 outline-none focus:border-sky-400/40"
                        />
                      </div>

                      <div className="md:col-span-2">
                        <label className="text-xs text-slate-300">Card number</label>
                        <input
                          name="cardNumber"
                          inputMode="numeric"
                          autoComplete="cc-number"
                          placeholder="1111 2222 3333 4444"
                          value={cardNumber}
                          maxLength={19}
                          onChange={(e) => {
                            const digits = e.target.value.replace(/\D/g, "").slice(0, 16);
                            const formatted = digits.replace(/(\d{4})(?=\d)/g, "$1 ").trim();
                            setCardNumber(formatted);
                          }}
                          className="mt-1 w-full rounded-xl border border-white/10 bg-slate-950/40 px-3 py-2 text-sm text-slate-100 outline-none focus:border-sky-400/40"
                        />
                      </div>

                      <div>
                        <label className="text-xs text-slate-300">Expiry date</label>
                        <input
                          name="expDate"
                          inputMode="numeric"
                          autoComplete="cc-exp"
                          placeholder="08/26"
                          value={expDate}
                          maxLength={5}
                          onChange={(e) => {
                            const digits = e.target.value.replace(/\D/g, "").slice(0, 4);
                            const formatted = digits.length > 2 ? `${digits.slice(0, 2)}/${digits.slice(2)}` : digits;
                            setExpDate(formatted);
                          }}
                          className="mt-1 w-full rounded-xl border border-white/10 bg-slate-950/40 px-3 py-2 text-sm text-slate-100 outline-none focus:border-sky-400/40"
                        />
                      </div>

                      <div>
                        <label className="text-xs text-slate-300">CVV</label>
                        <input
                          name="cvv"
                          inputMode="numeric"
                          autoComplete="cc-csc"
                          placeholder="123"
                          className="mt-1 w-full rounded-xl border border-white/10 bg-slate-950/40 px-3 py-2 text-sm text-slate-100 outline-none focus:border-sky-400/40"
                        />
                      </div>
                    </div>
                    ) : null}

                    {!selectedSavedCardId ? (
                    <label className="mt-3 flex items-center gap-2 text-sm text-slate-200">
                      <input type="checkbox" name="saveCard" className="h-4 w-4 accent-sky-400" />
                      Save this card for my account
                    </label>
                    ) : null}
                    <div className="mt-1 text-xs text-slate-400">
                      Security note: CVV is never stored. Only masked card details are saved.
                    </div>
                  </div>
                ) : null}

                {option.id === "transfer" && isSelected ? (
                  <div className="mt-3 rounded-xl border border-white/10 bg-slate-950/30 p-3 text-xs text-slate-200">
                    <div className="text-sm font-semibold text-slate-100">7 / 24 All Banks 0% Commission</div>
                    <div className="mt-3 space-y-3">
                      <div>
                        <div className="text-[11px] uppercase tracking-wide text-slate-400">IBAN</div>
                        <div className="mt-1 font-semibold text-emerald-200">{maskedIban}</div>
                      </div>
                      <div>
                        <div className="text-[11px] uppercase tracking-wide text-slate-400">Account Holder</div>
                        <div className="mt-1 text-slate-100">TradeHub</div>
                      </div>
                      <div>
                        <div className="text-[11px] uppercase tracking-wide text-slate-400">Description</div>
                        <div className="mt-1 text-slate-100">
                          Payment Information - Wire transfer description: write your user ID in the
                          "Description" field.
                        </div>
                        <div className="mt-2 inline-flex rounded-xl border border-cyan-400/30 bg-cyan-400/10 px-3 py-2 text-xs font-semibold text-cyan-100">
                          User ID: {props.userId}
                        </div>
                      </div>
                    </div>
                    <div className="mt-3 text-[11px] text-slate-400">
                      After transfer, your payment is processed quickly even before manual notification.
                    </div>
                  </div>
                ) : null}
              </div>
            );
          })}
        </div>
      </div>

      {props.children}
    </form>
  );
}

function detectCardBrand(digits: string): "visa" | "mastercard" | "amex" | "unionpay" | "unknown" {
  if (/^4\d{0,}$/.test(digits)) return "visa";
  if (/^(5[1-5]\d{0,}|2(2[2-9]|[3-6]\d|7[01])\d{0,})$/.test(digits)) return "mastercard";
  if (/^62\d{0,}$/.test(digits)) return "unionpay";
  if (/^3[47]\d{0,}$/.test(digits)) return "amex";
  return "unknown";
}

