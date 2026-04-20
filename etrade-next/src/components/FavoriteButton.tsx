"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { showToast } from "./ToastHost";

export function FavoriteButton(props: { itemId: number; active: boolean }) {
  const router = useRouter();
  const [loading, setLoading] = useState(false);

  const toggle = async () => {
    if (loading) return;
    setLoading(true);
    try {
      const res = await fetch("/api/favorites/toggle", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ itemId: props.itemId }),
      });
      if (!res.ok) throw new Error("Could not update favorites.");
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
      disabled={loading}
      onClick={toggle}
      className={[
        "inline-flex items-center justify-center rounded-xl border px-3 py-2 text-sm font-medium transition active:translate-y-px disabled:opacity-60",
        props.active
          ? "border-rose-400/25 bg-rose-400/10 text-rose-100 hover:bg-rose-400/15"
          : "border-white/10 bg-white/5 text-slate-200 hover:bg-white/10",
      ].join(" ")}
      aria-label={props.active ? "Remove from favorites" : "Add to favorites"}
      title={props.active ? "Remove from favorites" : "Add to favorites"}
    >
      {props.active ? "♥" : "♡"}
    </button>
  );
}

