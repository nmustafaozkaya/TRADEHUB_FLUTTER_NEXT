"use client";

import { useMemo, useState } from "react";

type ReviewRow = {
  id: number;
  rating: number;
  comment: string;
  createdAt: string;
  reviewer: string;
};

export function ItemReviewsPanel(props: {
  averageRating: number;
  totalReviews: number;
  reviews: ReviewRow[];
}) {
  const pageSize = 5;
  const pages = Math.max(1, Math.ceil(props.reviews.length / pageSize));
  const [page, setPage] = useState(1);

  const sliced = useMemo(() => {
    const start = (page - 1) * pageSize;
    return props.reviews.slice(start, start + pageSize);
  }, [page, props.reviews]);

  return (
    <>
      <div className="mt-2 flex items-center gap-2">
        <span className="text-amber-300">★★★★★</span>
        <span className="text-sm text-slate-300">
          {props.averageRating > 0 ? props.averageRating.toFixed(1) : "0.0"} / 5
        </span>
        <span className="text-xs text-slate-400">({props.totalReviews} total)</span>
      </div>

      {!props.reviews.length ? (
        <div className="mt-3 rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-sm text-slate-400">
          No reviews yet.
        </div>
      ) : (
        <>
          <div className="mt-3 space-y-2">
            {sliced.map((r) => (
              <div key={r.id} className="rounded-xl border border-white/10 bg-white/5 p-3">
                <div className="flex items-center justify-between gap-2">
                  <span className="text-xs font-semibold text-slate-300">{r.reviewer || "an*** us***"}</span>
                  <span className="text-xs text-slate-500">
                    {r.createdAt ? new Date(r.createdAt).toLocaleDateString("en-US") : "-"}
                  </span>
                </div>
                <div className="mt-1 text-amber-300">{"★".repeat(Math.max(0, Math.min(5, r.rating)))}</div>
                <div className="mt-1 text-sm text-slate-300">{r.comment || "No comment."}</div>
              </div>
            ))}
          </div>
          {pages > 1 ? (
            <div className="mt-3 flex flex-wrap gap-2">
              {Array.from({ length: pages }, (_, i) => i + 1).map((n) => (
                <button
                  key={n}
                  type="button"
                  onClick={() => setPage(n)}
                  className={`rounded-lg border px-2 py-1 text-xs ${n === page ? "border-indigo-400/50 bg-indigo-500/20 text-indigo-200" : "border-white/10 bg-white/5 text-slate-300"}`}
                >
                  {n}
                </button>
              ))}
            </div>
          ) : null}
        </>
      )}
    </>
  );
}

