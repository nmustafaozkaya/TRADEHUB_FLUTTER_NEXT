"use client";

import { useState } from "react";
import { showToast } from "./ToastHost";

export function ComingSoonButton(props: {
  label: string;
  className?: string;
  message?: string;
}) {
  const [loading, setLoading] = useState(false);
  return (
    <button
      type="button"
      disabled={loading}
      className={
        props.className ||
        "rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-sm text-slate-200 hover:bg-white/10 disabled:opacity-60"
      }
      onClick={() => {
        if (loading) return;
        setLoading(true);
        showToast({ type: "success", message: props.message || "Coming soon." });
        window.setTimeout(() => setLoading(false), 350);
      }}
    >
      {props.label}
    </button>
  );
}

