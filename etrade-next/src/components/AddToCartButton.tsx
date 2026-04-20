"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { showToast } from "./ToastHost";

export function AddToCartButton(props: {
  itemId: number;
  name: string;
  unitPrice: number;
  qty?: number;
  className?: string;
  children?: React.ReactNode;
}) {
  const router = useRouter();
  const [loading, setLoading] = useState(false);

  const onClick = async () => {
    if (loading) return;
    setLoading(true);
    try {
      const res = await fetch("/api/cart/add", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          itemId: props.itemId,
          name: props.name,
          unitPrice: props.unitPrice,
          qty: props.qty ?? 1,
        }),
      });

      if (!res.ok) throw new Error("Could not add to cart.");

      showToast({ type: "success", message: "Added to cart.", action: { label: "View cart", href: "/cart" } });
      router.refresh();
    } catch (e) {
      showToast({ type: "danger", message: e instanceof Error ? e.message : "Error" });
    } finally {
      setLoading(false);
    }
  };

  return (
    <button
      type="button"
      onClick={onClick}
      disabled={loading}
      className={
        props.className ||
        "inline-flex items-center justify-center gap-2 rounded-xl border border-white/10 bg-sky-400/20 px-3 py-2 text-sm font-medium text-sky-200 transition active:translate-y-px hover:bg-sky-400/25 disabled:opacity-60"
      }
    >
      {props.children || (loading ? "Adding..." : "Add to cart")}
    </button>
  );
}

