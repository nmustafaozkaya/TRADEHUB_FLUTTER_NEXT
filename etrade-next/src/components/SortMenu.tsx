"use client";

import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { useEffect, useRef, useState } from "react";

type SortKey = "newest" | "price_asc" | "price_desc" | "name_asc";

const OPTIONS: Array<{ key: SortKey; label: string }> = [
  { key: "newest", label: "Newest" },
  { key: "price_asc", label: "Price: Low to High" },
  { key: "price_desc", label: "Price: High to Low" },
  { key: "name_asc", label: "Name: A → Z" },
];

export function SortMenu() {
  const router = useRouter();
  const pathname = usePathname();
  const sp = useSearchParams();
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement | null>(null);

  const current = (sp.get("sort") as SortKey | null) || "newest";
  const currentLabel = OPTIONS.find((o) => o.key === current)?.label || "Sort";

  useEffect(() => {
    const onDown = (e: PointerEvent) => {
      const el = rootRef.current;
      if (!el) return;
      if (el.contains(e.target as Node)) return;
      setOpen(false);
    };
    window.addEventListener("pointerdown", onDown);
    return () => window.removeEventListener("pointerdown", onDown);
  }, []);

  const go = (key: SortKey) => {
    const next = new URLSearchParams(sp.toString());
    if (key === "newest") next.delete("sort");
    else next.set("sort", key);
    next.delete("page"); // reset pagination when sorting
    router.push(`${pathname}?${next.toString()}`);
    router.refresh();
    setOpen(false);
  };

  return (
    <div ref={rootRef} className="relative">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className="inline-flex items-center gap-2 rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-sm font-medium text-slate-200 hover:bg-white/10"
      >
        Sort
        <span className="hidden md:inline text-slate-400">({currentLabel})</span>
        <span className="text-slate-400">▾</span>
      </button>

      {open ? (
        <div className="absolute right-0 mt-2 w-56 overflow-hidden rounded-2xl border border-white/10 bg-slate-950/95 shadow-[0_18px_44px_rgba(0,0,0,0.45)] backdrop-blur">
          {OPTIONS.map((o) => (
            <button
              key={o.key}
              type="button"
              onClick={() => go(o.key)}
              className={[
                "w-full px-3 py-2 text-left text-sm hover:bg-white/10",
                o.key === current ? "text-sky-200" : "text-slate-200",
              ].join(" ")}
            >
              {o.label}
            </button>
          ))}
        </div>
      ) : null}
    </div>
  );
}

