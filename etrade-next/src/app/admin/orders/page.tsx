"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { formatTry } from "@/lib/format";
import { orderStatusLabel } from "@/lib/orderStatus";

type AdminOrder = {
  ID: number;
  UserId: number;
  Username: string | null;
  NameSurname: string | null;
  TotalPrice: number;
  Status: number;
};

type AdminOrderDetail = {
  ID: number;
  UserId: number;
  Username: string | null;
  NameSurname: string | null;
  Date: string | null;
  TotalPrice: number;
  Status: number;
  AddressText: string | null;
  City: string | null;
  Town: string | null;
};

type AdminOrderLine = {
  ItemId: number;
  ItemName: string | null;
  Brand: string | null;
  Qty: number;
  UnitPrice: number;
  LineTotal: number;
};

export default function AdminOrdersPage() {
  const router = useRouter();
  const [ready, setReady] = useState(false);
  const [orders, setOrders] = useState<AdminOrder[]>([]);
  const [error, setError] = useState("");

  const loadOrders = async () => {
    const res = await fetch("/api/admin/orders?page=1&pageSize=20", { cache: "no-store" });
    const data = await res.json().catch(() => null);
    if (!res.ok || !data?.ok || !Array.isArray(data.orders)) {
      throw new Error(data?.error || "Could not load orders.");
    }
    setOrders(data.orders);
  };

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
    void loadOrders();
  }, [ready]);

  const handleDetailsClick = (orderId: number) => {
    router.push(`/admin/orders/${orderId}`);
  };

  if (!ready) {
    return <main className="p-6 text-sm text-slate-300">Loading orders...</main>;
  }

  return (
    <main className="space-y-4 p-3">
      <div className="flex items-center justify-between rounded-2xl border border-slate-800 bg-slate-900/70 p-4">
        <div>
          <p className="text-xs uppercase tracking-[0.2em] text-cyan-300">Admin</p>
          <h1 className="text-2xl font-bold text-white">Orders</h1>
        </div>
        <button
          type="button"
          onClick={() => router.push("/admin/dashboard")}
          className="rounded-lg border border-slate-700 px-3 py-2 text-sm text-slate-200 hover:bg-slate-800"
        >
          Back to dashboard
        </button>
      </div>

      {error ? (
        <p className="rounded-lg border border-rose-500/40 bg-rose-500/10 px-3 py-2 text-xs text-rose-200">
          {error}
        </p>
      ) : null}

      <div className="overflow-hidden rounded-xl border border-slate-800">
          <table className="w-full text-left text-sm">
            <thead className="bg-slate-900 text-slate-300">
              <tr>
                <th className="px-3 py-2">Order</th>
                <th className="px-3 py-2">Customer</th>
                <th className="px-3 py-2">Status</th>
                <th className="px-3 py-2">Total</th>
                <th className="px-3 py-2">Action</th>
              </tr>
            </thead>
            <tbody>
              {orders.map((o) => (
                <tr key={o.ID} className="border-t border-slate-800 bg-slate-900/40">
                  <td className="px-3 py-2 text-slate-100">#{o.ID}</td>
                  <td className="px-3 py-2 text-slate-300">{o.NameSurname || o.Username || `User #${o.UserId}`}</td>
                  <td className="px-3 py-2 text-slate-300">{orderStatusLabel(o.Status)}</td>
                  <td className="px-3 py-2 text-slate-300">{formatTry(Number(o.TotalPrice || 0))}</td>
                  <td className="px-3 py-2">
                    <div className="flex flex-wrap gap-1.5">
                      <button
                        type="button"
                        onClick={() => handleDetailsClick(o.ID)}
                        className="rounded border border-slate-500/40 bg-slate-500/10 px-2 py-1 text-xs text-slate-200"
                      >
                        Details
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
    </main>
  );
}

