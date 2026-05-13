"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export function ItemReviewForm(props: { itemId: number }) {
  const router = useRouter();
  const [rating, setRating] = useState(5);
  const [comment, setComment] = useState("");
  const [pending, setPending] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function submitReview() {
    setPending(true);
    setMessage(null);
    setError(null);
    try {
      const res = await fetch(`/api/items/${props.itemId}/reviews`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          rating,
          comment: comment.trim(),
        }),
      });
      const data = (await res.json().catch(() => null)) as
        | { error?: string; ok?: boolean; mode?: "created" | "updated" }
        | null;
      if (!res.ok || !data?.ok) {
        setError(data?.error || "Could not send your review.");
        return;
      }
      setMessage(data.mode === "updated" ? "Review updated." : "Review submitted.");
      setComment("");
      setRating(5);
      router.refresh();
    } catch {
      setError("Could not send your review.");
    } finally {
      setPending(false);
    }
  }

  return (
    <div className="mt-4 rounded-xl border border-white/10 bg-white/[0.04] p-3">
      <div className="text-sm font-semibold text-slate-100">Write a review</div>
      <div className="mt-2 flex items-center gap-2">
        <span className="text-sm text-slate-400">Rating</span>
        <select
          value={rating}
          onChange={(e) => setRating(Number(e.target.value))}
          className="rounded-lg border border-white/10 bg-slate-900 px-2 py-1 text-sm text-slate-100"
        >
          {[5, 4, 3, 2, 1].map((v) => (
            <option key={v} value={v}>
              {v} star{v > 1 ? "s" : ""}
            </option>
          ))}
        </select>
      </div>
      <textarea
        value={comment}
        onChange={(e) => setComment(e.target.value)}
        rows={3}
        placeholder="Share your experience..."
        className="mt-2 w-full rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm text-slate-100 outline-none focus:border-indigo-400/40"
      />
      {message ? <div className="mt-2 text-xs text-emerald-300">{message}</div> : null}
      {error ? <div className="mt-2 text-xs text-rose-300">{error}</div> : null}
      <button
        type="button"
        disabled={pending || comment.trim().length < 3}
        onClick={submitReview}
        className="mt-3 rounded-lg bg-indigo-500 px-3 py-2 text-sm font-semibold text-white disabled:opacity-50"
      >
        {pending ? "Sending..." : "Submit review"}
      </button>
      <div className="mt-2 text-[11px] text-slate-500">Only users with successful purchases can post.</div>
    </div>
  );
}

