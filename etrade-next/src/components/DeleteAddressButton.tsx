"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { Button } from "./ui/Button";
import { showToast } from "./ToastHost";

export function DeleteAddressButton(props: { id: number }) {
  const router = useRouter();
  const [loading, setLoading] = useState(false);

  const del = async () => {
    if (loading) return;
    setLoading(true);
    try {
      const res = await fetch(`/api/account/addresses?id=${props.id}`, { method: "DELETE" });
      if (!res.ok) throw new Error("Could not delete.");
      showToast({ type: "success", message: "Address deleted." });
      router.refresh();
    } catch (e) {
      showToast({ type: "danger", message: e instanceof Error ? e.message : "Error" });
    } finally {
      setLoading(false);
    }
  };

  return (
    <Button variant="danger" size="sm" disabled={loading} onClick={del}>
      {loading ? "Deleting..." : "Delete"}
    </Button>
  );
}

