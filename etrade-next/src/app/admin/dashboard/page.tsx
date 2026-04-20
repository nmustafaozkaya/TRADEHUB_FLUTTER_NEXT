"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { formatTry } from "@/lib/format";
import { orderStatusLabel } from "@/lib/orderStatus";

type DashboardLocation = {
  name: string;
  count: number;
  percent: number;
};

type DashboardStats = {
  totalEarnings: number;
  totalOrders: number;
  customers: number;
  myBalance: number;
  locations: DashboardLocation[];
  recentOrders: {
    id: number;
    customer: string;
    product: string;
    amount: number;
    status: number;
  }[];
  bestProducts: {
    name: string;
    amount: number;
  }[];
  topSellers: {
    name: string;
    amount: number;
  }[];
  topCategories: {
    name: string;
    count: number;
  }[];
  revenueCards: {
    revenueValue: number;
    ordersValue: number;
    refundsValue: number;
    conversionRatio: number;
  };
};

export default function AdminDashboardPage() {
  const router = useRouter();
  const [ready, setReady] = useState(false);
  const [activeMenu, setActiveMenu] = useState("dashboard");
  const [stats, setStats] = useState<DashboardStats>({
    totalEarnings: 0,
    totalOrders: 0,
    customers: 0,
    myBalance: 0,
    locations: [],
    recentOrders: [],
    bestProducts: [],
    topSellers: [],
    topCategories: [],
    revenueCards: {
      revenueValue: 0,
      ordersValue: 0,
      refundsValue: 0,
      conversionRatio: 0,
    },
  });

  const loadDashboardStats = async () => {
    try {
      const res = await fetch("/api/admin/dashboard", { cache: "no-store" });
      const dashboardJson = await res.json().catch(() => null);
      const summary = dashboardJson?.summary ?? {};
      const locations = Array.isArray(dashboardJson?.locations) ? dashboardJson.locations : [];
      const recentOrders = Array.isArray(dashboardJson?.recentOrders)
        ? dashboardJson.recentOrders
        : [];
      const bestProducts = Array.isArray(dashboardJson?.bestProducts) ? dashboardJson.bestProducts : [];
      const topSellers = Array.isArray(dashboardJson?.topSellers) ? dashboardJson.topSellers : [];
      const topCategories = Array.isArray(dashboardJson?.topCategories) ? dashboardJson.topCategories : [];
      const revenue = dashboardJson?.revenue ?? {};

      setStats({
        totalEarnings: Number(summary.totalEarnings ?? 0),
        totalOrders: Number(summary.totalOrders ?? 0),
        customers: Number(summary.totalCustomers ?? 0),
        myBalance: Number(summary.myBalance ?? 0),
        locations,
        recentOrders,
        bestProducts,
        topSellers,
        topCategories,
        revenueCards: {
          revenueValue: Number(revenue.revenueValue ?? 0),
          ordersValue: Number(revenue.ordersValue ?? 0),
          refundsValue: Number(revenue.refundsValue ?? 0),
          conversionRatio: Number(revenue.conversionRatio ?? 0),
        },
      });
    } catch {
      setStats((prev) => ({
        ...prev,
        locations: [],
        recentOrders: [],
        bestProducts: [],
        topSellers: [],
        topCategories: [],
        revenueCards: {
          revenueValue: 0,
          ordersValue: 0,
          refundsValue: 0,
          conversionRatio: 0,
        },
      }));
    }
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
    void loadDashboardStats();
    const intervalId = window.setInterval(() => {
      void loadDashboardStats();
    }, 10000);
    return () => window.clearInterval(intervalId);
  }, [ready]);

  const handleMenuClick = (key: string) => {
    if (key === "dashboard") {
      setActiveMenu("dashboard");
      return;
    }
    if (key === "orders") {
      router.push("/admin/orders");
      return;
    }
    if (key === "products") {
      router.push("/admin/products");
      return;
    }
    if (key === "customers") {
      setActiveMenu("customers");
      const section = document.getElementById("section-customers");
      if (section) {
        section.scrollIntoView({ behavior: "smooth", block: "start" });
      }
      return;
    }
  };

  const handleLogout = () => {
    sessionStorage.removeItem("admin-auth");
    router.replace("/admin");
  };

  if (!ready) {
    return (
      <main className="mx-auto flex min-h-[72vh] w-full max-w-3xl items-center justify-center">
        <p className="text-sm text-slate-300">Loading admin panel...</p>
      </main>
    );
  }

  return (
    <main className="min-h-[76vh] w-full bg-slate-950 p-2 sm:p-3">
      <div className="grid gap-4 lg:grid-cols-[260px_1fr]">
        <aside className="rounded-2xl border border-slate-800 bg-slate-900/80 p-4 lg:sticky lg:top-6 lg:h-[calc(100vh-3rem)]">
          <div className="rounded-xl border border-cyan-400/20 bg-gradient-to-r from-cyan-500/15 to-indigo-500/10 p-3">
            <div className="text-xs uppercase tracking-[0.2em] text-cyan-300">TradeHub</div>
            <div className="mt-1 text-lg font-bold text-white">Admin Dashboard</div>
          </div>
          <div className="mt-4 space-y-2">
            {[
              { key: "dashboard", label: "Dashboard" },
              { key: "orders", label: "Orders" },
              { key: "customers", label: "Customers" },
              { key: "products", label: "Products" },
              { key: "reports", label: "Reports" },
              { key: "settings", label: "Settings" },
            ].map((item) => (
              <button
                key={item.key}
                type="button"
                onClick={() => handleMenuClick(item.key)}
                className={`w-full rounded-xl border px-3 py-2 text-left text-sm font-medium transition ${
                  activeMenu === item.key
                    ? "border-cyan-400/40 bg-cyan-400/10 text-cyan-200"
                    : "border-slate-700 text-slate-300 hover:bg-slate-800"
                }`}
              >
                {item.label}
              </button>
            ))}
          </div>
          <button
            type="button"
            onClick={handleLogout}
            className="mt-6 w-full rounded-xl border border-rose-400/30 bg-rose-500/10 px-3 py-2 text-sm font-semibold text-rose-200 hover:bg-rose-500/15"
          >
            Log out
          </button>
        </aside>

        <section className="space-y-4">
          <section className="flex items-center justify-between rounded-2xl border border-slate-800 bg-gradient-to-r from-slate-900/80 via-slate-900/60 to-cyan-950/40 p-5">
            <div>
              <p className="text-sm font-semibold text-cyan-300">Good Morning, admin!</p>
              <h1 className="mt-1 text-3xl font-bold text-white">
                Here&apos;s what&apos;s happening with your store today.
              </h1>
            </div>
            <button className="rounded-xl border border-slate-700 px-5 py-3 text-sm font-semibold text-slate-200 transition hover:bg-slate-800">
              View report
            </button>
          </section>

          <section id="section-dashboard" className="grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-4">
            {[
              {
                title: "Total Earnings",
                percent: "",
                value: formatTry(stats.totalEarnings),
                action: "From all orders in database",
              },
              {
                title: "Orders",
                percent: "",
                value: stats.totalOrders.toLocaleString("en-US"),
                action: "All recorded orders",
              },
              {
                title: "Customers",
                percent: "",
                value: stats.customers.toLocaleString("en-US"),
                action: "Registered users",
              },
              {
                title: "My Balance",
                percent: "",
                value: formatTry(stats.myBalance),
                action: "Delivered + completed orders",
              },
            ].map((card) => (
              <article key={card.title} className="rounded-2xl border border-slate-800 bg-slate-900/70 p-4">
                <p className="text-xs uppercase tracking-wide text-slate-400">{card.title}</p>
                {card.percent ? <p className="mt-1 text-xs text-emerald-300">{card.percent}</p> : null}
                <p className="mt-2 text-2xl font-bold text-white">{card.value}</p>
                <p className="mt-1 text-xs text-slate-400">{card.action}</p>
              </article>
            ))}
          </section>

          <section className="grid grid-cols-1 gap-3 xl:grid-cols-3">
            <article className="rounded-2xl border border-slate-800 bg-slate-900/70 p-4 xl:col-span-2">
              <h3 className="text-base font-semibold text-white">Revenue</h3>
              <div className="mt-3 grid gap-3 sm:grid-cols-4">
                {[
                  [formatTry(stats.revenueCards.revenueValue), "Revenue"],
                  [stats.revenueCards.ordersValue.toLocaleString("en-US"), "Orders"],
                  [stats.revenueCards.refundsValue.toLocaleString("en-US"), "Refunds"],
                  [`${stats.revenueCards.conversionRatio.toFixed(2)}%`, "Conversion Ratio"],
                ].map(([value, label]) => (
                  <div key={label} className="rounded-xl border border-slate-800 bg-slate-950/50 p-3">
                    <p className="text-lg font-bold text-slate-100">{value}</p>
                    <p className="text-xs text-slate-400">{label}</p>
                  </div>
                ))}
              </div>
            </article>
            <article className="rounded-2xl border border-slate-800 bg-slate-900/70 p-4">
              <h3 className="text-base font-semibold text-white">Sales by Locations</h3>
              <div className="mt-3 space-y-2 text-sm">
                {(stats.locations.length ? stats.locations : [{ name: "No data", count: 0, percent: 0 }]).map((item) => (
                  <div key={item.name} className="flex items-center justify-between rounded-lg bg-slate-950/40 px-3 py-2">
                    <span className="text-slate-300">{item.name}</span>
                    <span className="font-semibold text-slate-100">{item.percent.toFixed(2)}%</span>
                  </div>
                ))}
              </div>
            </article>
          </section>

          <section id="section-products" className="grid grid-cols-1 gap-3 xl:grid-cols-2">
            <article className="rounded-2xl border border-slate-800 bg-slate-900/70 p-4" onClick={() => setActiveMenu("products")}>
              <div className="mb-2 flex items-center justify-between">
                <h3 className="text-base font-semibold text-white">Best Selling Products</h3>
                <span className="text-xs text-slate-400">Sort by: Today</span>
              </div>
              <div className="space-y-2">
                {stats.bestProducts.map((item) => (
                  <div key={item.name} className="flex items-center justify-between rounded-lg border border-slate-800 bg-slate-950/40 px-3 py-2 text-sm">
                    <span className="text-slate-300">{item.name}</span>
                    <span className="font-semibold text-slate-100">{formatTry(item.amount)}</span>
                  </div>
                ))}
                {!stats.bestProducts.length ? <div className="text-xs text-slate-400">No data.</div> : null}
              </div>
            </article>
            <article className="rounded-2xl border border-slate-800 bg-slate-900/70 p-4" onClick={() => setActiveMenu("customers")}>
              <h3 className="text-base font-semibold text-white">Top Customers</h3>
              <div className="mt-3 space-y-2">
                {stats.topSellers.map((item) => (
                  <div key={item.name} className="flex items-center justify-between rounded-lg border border-slate-800 bg-slate-950/40 px-3 py-2 text-sm">
                    <span className="text-slate-300">{item.name}</span>
                    <span className="font-semibold text-slate-100">{formatTry(item.amount)}</span>
                  </div>
                ))}
                {!stats.topSellers.length ? <div className="text-xs text-slate-400">No data.</div> : null}
              </div>
            </article>
          </section>

          <section id="section-orders" className="rounded-2xl border border-slate-800 bg-slate-900/70 p-4">
            <h3 className="text-base font-semibold text-white">Recent Orders</h3>
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
                  {stats.recentOrders.map((row) => (
                    <tr key={row.id} className="border-t border-slate-800 bg-slate-900/40">
                      <td className="px-3 py-2 text-slate-100">#{row.id}</td>
                      <td className="px-3 py-2 text-slate-300">{row.customer}</td>
                      <td className="px-3 py-2 text-slate-300">{row.product}</td>
                      <td className="px-3 py-2 text-slate-300">{formatTry(row.amount)}</td>
                      <td className="px-3 py-2 text-slate-300">{orderStatusLabel(row.status)}</td>
                    </tr>
                  ))}
                  {!stats.recentOrders.length ? (
                    <tr className="border-t border-slate-800 bg-slate-900/40">
                      <td className="px-3 py-3 text-slate-400" colSpan={5}>
                        No recent orders found.
                      </td>
                    </tr>
                  ) : null}
                </tbody>
              </table>
            </div>
            <p className="mt-2 text-xs text-slate-400">Showing latest 5 purchases from database.</p>
          </section>

          <section id="section-customers" className="grid grid-cols-1 gap-3 xl:grid-cols-2">
            <article className="rounded-2xl border border-slate-800 bg-slate-900/70 p-4">
              <h3 className="text-base font-semibold text-white">Top 5 Categories</h3>
              <div className="mt-3 space-y-2 text-sm text-slate-300">
                {stats.topCategories.map((item) => (
                  <div key={item.name} className="rounded-lg border border-slate-800 bg-slate-950/40 px-3 py-2">
                    {item.name} ({item.count.toLocaleString("en-US")})
                  </div>
                ))}
                {!stats.topCategories.length ? <div className="text-xs text-slate-400">No data.</div> : null}
              </div>
            </article>
          </section>
        </section>
      </div>
    </main>
  );
}
