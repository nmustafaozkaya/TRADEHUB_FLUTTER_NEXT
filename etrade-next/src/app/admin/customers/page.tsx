"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { formatTry } from "@/lib/format";
import { orderStatusLabel } from "@/lib/orderStatus";

type AdminUser = {
  id: number;
  username: string;
  nameSurname: string;
  email: string;
};

type RecentOrder = {
  id: number;
  customer: string;
  product: string;
  amount: number;
  status: number;
};

export default function AdminCustomersPage() {
  const router = useRouter();
  const [ready, setReady] = useState(false);
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [recentOrders, setRecentOrders] = useState<RecentOrder[]>([]);

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
      const [usersRes, dashboardRes] = await Promise.all([
        fetch("/api/admin/users", { cache: "no-store" }),
        fetch("/api/admin/dashboard", { cache: "no-store" }),
      ]);
      const usersData = await usersRes.json().catch(() => null);
      const dashboardData = await dashboardRes.json().catch(() => null);
      if (usersRes.ok && usersData?.ok && Array.isArray(usersData.users)) {
        setUsers(usersData.users.slice(0, 200));
      }
      if (dashboardRes.ok && dashboardData?.ok && Array.isArray(dashboardData.recentOrders)) {
        setRecentOrders(dashboardData.recentOrders);
      }
    };
    void load();
  }, [ready]);

  if (!ready) return <main className="p-6 text-sm text-slate-300">Loading customers...</main>;

  return (
    <main className="space-y-4 p-3">
      <div className="flex items-center justify-between rounded-2xl border border-slate-800 bg-slate-900/70 p-4">
        <h1 className="text-2xl font-bold text-white">Customers</h1>
        <button
          type="button"
          onClick={() => router.push("/admin/dashboard")}
          className="rounded-lg border border-slate-700 px-3 py-2 text-sm text-slate-200 hover:bg-slate-800"
        >
          Back to dashboard
        </button>
      </div>

      <section className="rounded-2xl border border-slate-800 bg-slate-900/70 p-4">
        <h2 className="text-base font-semibold text-white">Recent Orders</h2>
        <div className="mt-3 overflow-hidden rounded-xl border border-slate-800">
          <table className="w-full text-left text-sm">
            <thead className="bg-slate-900 text-slate-300">
              <tr>
                <th className="px-3 py-2">Order ID</th>
                <th className="px-3 py-2">Customer</th>
                <th className="px-3 py-2">Product</th>
                <th className="px-3 py-2">Amount</th>
                <th className="px-3 py-2">Status</th>
              </tr>
            </thead>
            <tbody>
              {recentOrders.map((row) => (
                <tr key={row.id} className="border-t border-slate-800 bg-slate-900/40">
                  <td className="px-3 py-2 text-slate-100">#{row.id}</td>
                  <td className="px-3 py-2 text-slate-300">{row.customer}</td>
                  <td className="px-3 py-2 text-slate-300">{row.product}</td>
                  <td className="px-3 py-2 text-slate-300">{formatTry(row.amount)}</td>
                  <td className="px-3 py-2 text-slate-300">{orderStatusLabel(row.status)}</td>
                </tr>
              ))}
              {!recentOrders.length ? (
                <tr className="border-t border-slate-800 bg-slate-900/40">
                  <td className="px-3 py-3 text-slate-400" colSpan={5}>
                    No recent orders found.
                  </td>
                </tr>
              ) : null}
            </tbody>
          </table>
        </div>
      </section>

      <div className="overflow-hidden rounded-xl border border-slate-800">
        <table className="w-full text-left text-sm">
          <thead className="bg-slate-900 text-slate-300">
            <tr>
              <th className="px-3 py-2">ID</th>
              <th className="px-3 py-2">Username</th>
              <th className="px-3 py-2">Name</th>
              <th className="px-3 py-2">Email</th>
            </tr>
          </thead>
          <tbody>
            {users.map((user) => (
              <tr key={user.id} className="border-t border-slate-800 bg-slate-900/40">
                <td className="px-3 py-2 text-slate-100">#{user.id}</td>
                <td className="px-3 py-2 text-slate-300">{user.username || "-"}</td>
                <td className="px-3 py-2 text-slate-300">{user.nameSurname || "-"}</td>
                <td className="px-3 py-2 text-slate-300">{user.email || "-"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </main>
  );
}

