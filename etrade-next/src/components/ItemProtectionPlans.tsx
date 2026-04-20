"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

import type { ExtendedWarrantyOffer } from "@/lib/extendedWarranty";
import { formatTry } from "@/lib/format";

type ItemProtectionPlansProps = {
  itemId: number;
  itemName: string;
  unitPrice: number;
  offers: ExtendedWarrantyOffer[];
  selectedYears?: 1 | 2 | 3 | null;
};

export function ItemProtectionPlans(props: ItemProtectionPlansProps) {
  const router = useRouter();
  const [selectedYears, setSelectedYears] = useState<number | null>(props.selectedYears ?? null);
  const [pendingYears, setPendingYears] = useState<number | null>(null);

  const setProtection = async (years: 1 | 2 | 3, price: number) => {
    const isSelected = selectedYears === years;
    const nextYears = isSelected ? null : years;
    const nextPrice = isSelected ? null : price;

    setPendingYears(years);
    try {
      // Ensure item exists in cart first.
      await fetch("/api/cart/add", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          itemId: props.itemId,
          name: props.itemName,
          unitPrice: props.unitPrice,
          qty: 1,
        }),
      });

      const res = await fetch("/api/cart/protection", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          itemId: props.itemId,
          years: nextYears,
          price: nextPrice,
        }),
      });
      if (!res.ok) return;

      setSelectedYears(nextYears);
      router.refresh();
    } finally {
      setPendingYears(null);
    }
  };

  return (
    <div className="mt-3 space-y-2">
      {props.offers.map((s) => {
        const isSelected = selectedYears === s.years;
        const isPending = pendingYears === s.years;
        return (
          <div
            key={s.years}
            className={`flex items-center justify-between gap-3 rounded-2xl border p-3 ${
              isSelected ? "border-emerald-400/40 bg-emerald-500/10" : "border-white/10 bg-white/5"
            }`}
          >
            <div className="min-w-0">
              <div className="text-sm font-semibold text-slate-100">{s.years}-year plan</div>
              <div className="mt-1 text-xs text-slate-400">Protection coverage for eligible defects.</div>
            </div>
            <div className="shrink-0 text-right">
              <div className="text-sm font-bold text-slate-100">{formatTry(s.price)}</div>
              <button
                type="button"
                onClick={() => void setProtection(s.years, s.price)}
                disabled={isPending}
                className={`mt-2 rounded-xl border px-3 py-2 text-xs ${
                  isSelected
                    ? "border-emerald-400/40 bg-emerald-500/20 text-emerald-100"
                    : "border-white/10 bg-white/5 text-slate-200 hover:bg-white/10"
                }`}
              >
                {isPending ? "..." : isSelected ? "Added" : "Add"}
              </button>
            </div>
          </div>
        );
      })}
    </div>
  );
}

