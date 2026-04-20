"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { formatTry } from "@/lib/format";

type AdminItem = {
  ID: number;
  ITEMCODE: string | null;
  ITEMNAME: string | null;
  UNITPRICE: number | null;
  BRAND: string | null;
};

export default function AdminProductsPage() {
  const router = useRouter();
  const [ready, setReady] = useState(false);
  const [items, setItems] = useState<AdminItem[]>([]);

  useEffect(() => {
    const isAdminLoggedIn = sessionStorage.getItem("admin-auth") === "ok";
    if (!isAdminLoggedIn) {
      router.replace("/admin");
      return;
    }
    setReady(true);
  }, [router]);

  useEffect(() => {
    if (!ready) return;
    const load = async () => {
      const res = await fetch("/api/admin/items", { cache: "no-store" });
      const data = await res.json().catch(() => null);
      if (res.ok && data?.ok && Array.isArray(data.items)) {
        setItems(data.items.slice(0, 100));
      }
    };
    void load();
  }, [ready]);

  if (!ready) return <main className="p-6 text-sm text-slate-300">Loading products...</main>;

  return (
    <main className="space-y-4 p-3">
      <div className="flex items-center justify-between rounded-2xl border border-slate-800 bg-slate-900/70 p-4">
        <h1 className="text-2xl font-bold text-white">Products</h1>
        <button
          type="button"
          onClick={() => router.push("/admin/dashboard")}
          className="rounded-lg border border-slate-700 px-3 py-2 text-sm text-slate-200 hover:bg-slate-800"
        >
          Back to dashboard
        </button>
      </div>
      <div className="overflow-hidden rounded-xl border border-slate-800">
        <table className="w-full text-left text-sm">
          <thead className="bg-slate-900 text-slate-300">
            <tr>
              <th className="px-3 py-2">ID</th>
              <th className="px-3 py-2">Code</th>
              <th className="px-3 py-2">Name</th>
              <th className="px-3 py-2">Brand</th>
              <th className="px-3 py-2">Price</th>
            </tr>
          </thead>
          <tbody>
            {items.map((item) => (
              <tr key={item.ID} className="border-t border-slate-800 bg-slate-900/40">
                <td className="px-3 py-2 text-slate-100">#{item.ID}</td>
                <td className="px-3 py-2 text-slate-300">{item.ITEMCODE || "-"}</td>
                <td className="px-3 py-2 text-slate-300">{item.ITEMNAME || "-"}</td>
                <td className="px-3 py-2 text-slate-300">{item.BRAND || "-"}</td>
                <td className="px-3 py-2 text-slate-300">{formatTry(Number(item.UNITPRICE || 0))}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </main>
  );
}

