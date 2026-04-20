"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

type ConfirmDeliveryButtonProps = {
  orderId: number;
};

export function ConfirmDeliveryButton({ orderId }: ConfirmDeliveryButtonProps) {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleConfirm = async () => {
    setLoading(true);
    setError("");
    try {
      const res = await fetch(`/api/account/orders/${orderId}/confirm-delivery`, {
        method: "POST",
      });
      const data = (await res.json().catch(() => null)) as { ok?: boolean; error?: string } | null;
      if (!res.ok || !data?.ok) {
        setError(data?.error || "Could not confirm delivery.");
        return;
      }
      router.refresh();
    } catch {
      setError("Could not confirm delivery.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-2">
      <button
        type="button"
        onClick={handleConfirm}
        disabled={loading}
        className="w-full rounded-xl bg-emerald-500 px-3 py-2 text-sm font-semibold text-emerald-950 disabled:opacity-70"
      >
        {loading ? "Confirming..." : "I received my order"}
      </button>
      {error ? <p className="text-xs text-rose-300">{error}</p> : null}
    </div>
  );
}

