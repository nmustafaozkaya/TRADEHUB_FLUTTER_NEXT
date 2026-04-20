"use client";

import { useEffect, useState } from "react";

type ToastPayload = {
  type?: "success" | "danger";
  message: string;
  action?: { label: string; href: string };
};

export function ToastHost() {
  const [toast, setToast] = useState<ToastPayload | null>(null);

  useEffect(() => {
    let t: number | null = null;

    const onToast = (e: Event) => {
      const ce = e as CustomEvent<ToastPayload>;
      const payload = ce.detail;
      if (!payload?.message) return;

      setToast(payload);
      if (t) window.clearTimeout(t);
      t = window.setTimeout(() => setToast(null), 2200);
    };

    window.addEventListener("toast", onToast as EventListener);
    return () => {
      window.removeEventListener("toast", onToast as EventListener);
      if (t) window.clearTimeout(t);
    };
  }, []);

  if (!toast) return null;

  const cls =
    toast.type === "danger" ? "toast toast-danger" : toast.type === "success" ? "toast toast-success" : "toast";

  return (
    <div className={cls}>
      <div className="flex items-center justify-between gap-3">
        <div className="text-sm text-slate-100">{toast.message}</div>
        {toast.action ? (
          <a
            href={toast.action.href}
            onClick={() => setToast(null)}
            className="shrink-0 rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-xs font-semibold text-slate-200 hover:bg-white/10"
          >
            {toast.action.label}
          </a>
        ) : null}
      </div>
    </div>
  );
}

export function showToast(payload: ToastPayload) {
  if (typeof window === "undefined") return;
  window.dispatchEvent(new CustomEvent<ToastPayload>("toast", { detail: payload }));
}

