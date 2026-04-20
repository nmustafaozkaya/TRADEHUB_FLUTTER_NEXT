"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { showToast } from "./ToastHost";

export function CartLineEditor(props: { itemId: number; qty: number }) {
  const router = useRouter();
  const [qty, setQty] = useState(props.qty);
  const [loading, setLoading] = useState(false);

  const update = async (nextQty: number) => {
    setLoading(true);
    try {
      const res = await fetch("/api/cart/update", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ itemId: props.itemId, qty: nextQty }),
      });
      if (!res.ok) throw new Error("Could not update.");
      router.refresh();
      setQty(Math.max(0, Number(nextQty)));
    } catch (e) {
      showToast({ type: "danger", message: e instanceof Error ? e.message : "Error" });
    } finally {
      setLoading(false);
    }
  };

  const remove = async () => {
    setLoading(true);
    try {
      const res = await fetch("/api/cart/remove", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ itemId: props.itemId }),
      });
      if (!res.ok) throw new Error("Could not remove.");
      router.refresh();
    } catch (e) {
      showToast({ type: "danger", message: e instanceof Error ? e.message : "Error" });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex items-center gap-2">
      <div className="inline-flex items-center overflow-hidden rounded-xl border border-white/10 bg-slate-950/30">
        <button
          type="button"
          disabled={loading}
          onClick={() => update(Math.max(0, Number(qty) - 1))}
          className="px-3 py-2 text-sm text-slate-200 hover:bg-white/10 disabled:opacity-60"
          aria-label="Decrease quantity"
          title="Decrease"
        >
          −
        </button>
        <input
          inputMode="numeric"
          value={qty}
          onChange={(e) => setQty(Math.max(0, Number(e.target.value)))}
          onBlur={() => update(qty)}
          className="w-12 bg-transparent px-2 py-2 text-center text-sm text-slate-100 outline-none"
          aria-label="Quantity"
        />
        <button
          type="button"
          disabled={loading}
          onClick={() => update(Number(qty) + 1)}
          className="px-3 py-2 text-sm text-slate-200 hover:bg-white/10 disabled:opacity-60"
          aria-label="Increase quantity"
          title="Increase"
        >
          +
        </button>
      </div>

      <button
        type="button"
        disabled={loading}
        onClick={remove}
        className="rounded-xl border border-rose-400/25 bg-rose-400/10 px-3 py-2 text-xs font-semibold text-rose-100 hover:bg-rose-400/15 disabled:opacity-60"
      >
        Remove
      </button>
    </div>
  );
}

