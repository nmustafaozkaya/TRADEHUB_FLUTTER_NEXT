"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { showToast } from "./ToastHost";

export function ClearCartButton() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);

  const clear = async () => {
    setLoading(true);
    try {
      const res = await fetch("/api/cart/clear", { method: "POST" });
      if (!res.ok) throw new Error("Could not clear cart.");
      router.refresh();
      showToast({ type: "success", message: "Cart cleared." });
    } catch (e) {
      showToast({ type: "danger", message: e instanceof Error ? e.message : "Error" });
    } finally {
      setLoading(false);
    }
  };

  return (
    <button
      type="button"
      disabled={loading}
      onClick={clear}
      className="rounded-xl border border-rose-400/25 bg-rose-400/10 px-3 py-2 text-sm text-rose-100 hover:bg-rose-400/15 disabled:opacity-60"
    >
      {loading ? "Clearing..." : "Clear cart"}
    </button>
  );
}

