"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

import type { ExtendedWarrantyOffer } from "@/lib/extendedWarranty";
import { formatTry } from "@/lib/format";

type CartProtectionPlansProps = {
  itemId: number;
  offers: ExtendedWarrantyOffer[];
  selectedYears?: 1 | 2 | 3 | null;
};

export function CartProtectionPlans({ itemId, offers, selectedYears = null }: CartProtectionPlansProps) {
  const router = useRouter();
  const [selected, setSelected] = useState<number | null>(selectedYears);
  const [pendingYears, setPendingYears] = useState<number | null>(null);

  const toggleProtection = async (years: 1 | 2 | 3, price: number) => {
    const isSelected = selected === years;
    const nextYears = isSelected ? null : years;
    const nextPrice = isSelected ? null : price;

    setPendingYears(years);
    try {
      const res = await fetch("/api/cart/protection", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          itemId,
          years: nextYears,
          price: nextPrice,
        }),
      });
      if (!res.ok) return;
      setSelected(nextYears);
      router.refresh();
    } finally {
      setPendingYears(null);
    }
  };

  return (
    <div className="mt-3 grid gap-2 sm:grid-cols-3">
      {offers.map((s) => {
        const isSelected = selected === s.years;
        const isPending = pendingYears === s.years;
        return (
          <div
            key={`${itemId}-${s.years}`}
            className={`rounded-xl border p-3 ${
              isSelected ? "border-emerald-400/40 bg-emerald-500/10" : "border-white/10 bg-slate-950/30"
            }`}
          >
            <div className="text-sm font-semibold text-slate-100">{s.years}-year plan</div>
            <div className="mt-1 text-xs text-slate-400">Protection plan preview for this item.</div>
            <div className="mt-2 flex items-center justify-between gap-2">
              <div className="text-sm font-bold text-slate-100">{formatTry(s.price)}</div>
              <button
                type="button"
                onClick={() => void toggleProtection(s.years, s.price)}
                disabled={isPending}
                className={`rounded-lg px-3 py-1.5 text-xs font-medium ${
                  isSelected
                    ? "border border-emerald-400/40 bg-emerald-500/20 text-emerald-100"
                    : "border border-white/10 bg-white/5 text-slate-200 hover:bg-white/10"
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

