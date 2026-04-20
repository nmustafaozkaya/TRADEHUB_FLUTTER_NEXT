"use client";

import { useMemo, useState } from "react";
import { AddToCartButton } from "./AddToCartButton";

export function QtyPickerAddToCart(props: {
  itemId: number;
  name: string;
  unitPrice: number;
  min?: number;
  max?: number;
}) {
  const min = Math.max(1, Number(props.min ?? 1));
  const max = Math.max(min, Number(props.max ?? 10));
  const [qty, setQty] = useState(min);

  const safeQty = useMemo(() => Math.min(max, Math.max(min, Number(qty) || min)), [max, min, qty]);

  return (
    <div className="flex items-center gap-2">
      <div className="inline-flex items-center overflow-hidden rounded-xl border border-white/10 bg-slate-950/30">
        <button
          type="button"
          className="px-3 py-2 text-sm text-slate-200 hover:bg-white/10"
          onClick={() => setQty((q) => Math.max(min, Number(q) - 1))}
          aria-label="Decrease quantity"
          title="Decrease"
        >
          −
        </button>
        <input
          inputMode="numeric"
          value={safeQty}
          onChange={(e) => setQty(Number(e.target.value))}
          className="w-12 bg-transparent px-2 py-2 text-center text-sm text-slate-100 outline-none"
          aria-label="Quantity"
        />
        <button
          type="button"
          className="px-3 py-2 text-sm text-slate-200 hover:bg-white/10"
          onClick={() => setQty((q) => Math.min(max, Number(q) + 1))}
          aria-label="Increase quantity"
          title="Increase"
        >
          +
        </button>
      </div>

      <AddToCartButton itemId={props.itemId} name={props.name} unitPrice={props.unitPrice} qty={safeQty} />
    </div>
  );
}

