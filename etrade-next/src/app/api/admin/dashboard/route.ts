import { NextResponse } from "next/server";
import { query } from "@/lib/db";

type LocationRow = {
  name: string | null;
  count: number;
  pct: number;
};

type SummaryRow = {
  totalEarnings: number;
  totalOrders: number;
  totalCustomers: number;
  myBalance: number;
};

type RevenueRow = {
  revenueValue: number;
  ordersValue: number;
  refundsValue: number;
  conversionRatio: number;
};

type RecentOrderRow = {
  id: number;
  customer: string | null;
  product: string | null;
  amount: number;
  status: number;
};

type BestProductRow = {
  name: string | null;
  amount: number;
};

type TopSellerRow = {
  name: string | null;
  amount: number;
};

type TopCategoryRow = {
  name: string | null;
  count: number;
};

export async function GET() {
  try {
    const [summaryRows, revenueRows, locationRows, recentOrderRows, bestProductRows, topSellerRows, topCategoryRows] = await Promise.all([
      query<SummaryRow>(`
        SELECT
          COALESCE(SUM(o.TOTALPRICE), 0) AS totalEarnings,
          COUNT(*) AS totalOrders,
          (SELECT COUNT(*) FROM dbo.USERS) AS totalCustomers,
          COALESCE(SUM(CASE WHEN o.STATUS_ IN (4, 5) THEN o.TOTALPRICE ELSE 0 END), 0) AS myBalance
        FROM dbo.ORDERS o;
      `),
      query<RevenueRow>(`
        SELECT
          COALESCE(SUM(o.TOTALPRICE), 0) AS revenueValue,
          COUNT(*) AS ordersValue,
          SUM(CASE WHEN o.STATUS_ = 4 THEN 1 ELSE 0 END) AS refundsValue,
          CASE
            WHEN (SELECT COUNT(*) FROM dbo.USERS) = 0 THEN 0
            ELSE (COUNT(DISTINCT o.USERID) * 100.0 / (SELECT COUNT(*) FROM dbo.USERS))
          END AS conversionRatio
        FROM dbo.ORDERS o;
      `),
      query<LocationRow>(`
        WITH LocationTotals AS (
          SELECT
            COALESCE(c.CITY, 'Unknown') AS name,
            COUNT(*) AS count
          FROM dbo.ORDERS o
          LEFT JOIN dbo.ADDRESS a ON a.ID = o.ADDRESSID
          LEFT JOIN dbo.CITIES c ON c.ID = a.CITYID
          GROUP BY COALESCE(c.CITY, 'Unknown')
        ),
        GrandTotal AS (
          SELECT SUM(count) AS totalCount
          FROM LocationTotals
        )
        SELECT TOP (3)
          lt.name,
          lt.count,
          CASE
            WHEN gt.totalCount IS NULL OR gt.totalCount = 0 THEN 0
            ELSE (lt.count * 100.0 / gt.totalCount)
          END AS pct
        FROM LocationTotals lt
        CROSS JOIN GrandTotal gt
        ORDER BY lt.count DESC, lt.name ASC;
      `),
      query<RecentOrderRow>(`
        SELECT TOP (5)
          o.ID AS id,
          COALESCE(u.NAMESURNAME, u.USERNAME_, CONCAT('User #', CONVERT(varchar(20), o.USERID))) AS customer,
          COALESCE(p.ITEMNAME, '-') AS product,
          COALESCE(o.TOTALPRICE, 0) AS amount,
          COALESCE(o.STATUS_, 0) AS status
        FROM dbo.ORDERS o
        LEFT JOIN dbo.USERS u ON u.ID = o.USERID
        OUTER APPLY (
          SELECT TOP (1) i.ITEMNAME
          FROM dbo.ORDERDETAILS od
          LEFT JOIN dbo.ITEMS i ON i.ID = od.ITEMID
          WHERE od.ORDERID = o.ID
          ORDER BY od.ID ASC
        ) p
        ORDER BY o.DATE_ DESC, o.ID DESC;
      `),
      query<BestProductRow>(`
        SELECT TOP (5)
          COALESCE(i.ITEMNAME, '-') AS name,
          COALESCE(SUM(od.LINETOTAL), 0) AS amount
        FROM dbo.ORDERDETAILS od
        LEFT JOIN dbo.ITEMS i ON i.ID = od.ITEMID
        GROUP BY i.ITEMNAME
        ORDER BY COALESCE(SUM(od.LINETOTAL), 0) DESC, COALESCE(i.ITEMNAME, '-') ASC;
      `),
      query<TopSellerRow>(`
        SELECT TOP (5)
          COALESCE(u.NAMESURNAME, u.USERNAME_, CONCAT('User #', CONVERT(varchar(20), o.USERID))) AS name,
          COALESCE(SUM(o.TOTALPRICE), 0) AS amount
        FROM dbo.ORDERS o
        LEFT JOIN dbo.USERS u ON u.ID = o.USERID
        GROUP BY COALESCE(u.NAMESURNAME, u.USERNAME_, CONCAT('User #', CONVERT(varchar(20), o.USERID)))
        ORDER BY COALESCE(SUM(o.TOTALPRICE), 0) DESC, COALESCE(u.NAMESURNAME, u.USERNAME_, CONCAT('User #', CONVERT(varchar(20), o.USERID))) ASC;
      `),
      query<TopCategoryRow>(`
        SELECT TOP (5)
          COALESCE(i.CATEGORY1, 'Unknown') AS name,
          COUNT(*) AS count
        FROM dbo.ORDERDETAILS od
        LEFT JOIN dbo.ITEMS i ON i.ID = od.ITEMID
        GROUP BY COALESCE(i.CATEGORY1, 'Unknown')
        ORDER BY COUNT(*) DESC, COALESCE(i.CATEGORY1, 'Unknown') ASC;
      `),
    ]);

    const summary = summaryRows[0] ?? {
      totalEarnings: 0,
      totalOrders: 0,
      totalCustomers: 0,
      myBalance: 0,
    };
    const revenue = revenueRows[0] ?? {
      revenueValue: 0,
      ordersValue: 0,
      refundsValue: 0,
      conversionRatio: 0,
    };

    return NextResponse.json({
      ok: true,
      summary: {
        totalEarnings: Number(summary.totalEarnings ?? 0),
        totalOrders: Number(summary.totalOrders ?? 0),
        totalCustomers: Number(summary.totalCustomers ?? 0),
        myBalance: Number(summary.myBalance ?? 0),
      },
      revenue: {
        revenueValue: Number(revenue.revenueValue ?? 0),
        ordersValue: Number(revenue.ordersValue ?? 0),
        refundsValue: Number(revenue.refundsValue ?? 0),
        conversionRatio: Number(revenue.conversionRatio ?? 0),
      },
      locations: locationRows.map((row) => ({
        name: row.name ?? "Unknown",
        count: Number(row.count ?? 0),
        percent: Number(row.pct ?? 0),
      })),
      recentOrders: recentOrderRows.map((row) => ({
        id: Number(row.id),
        customer: row.customer ?? "-",
        product: row.product ?? "-",
        amount: Number(row.amount ?? 0),
        status: Number(row.status ?? 0),
      })),
      bestProducts: bestProductRows.map((row) => ({
        name: row.name ?? "-",
        amount: Number(row.amount ?? 0),
      })),
      topSellers: topSellerRows.map((row) => ({
        name: row.name ?? "-",
        amount: Number(row.amount ?? 0),
      })),
      topCategories: topCategoryRows.map((row) => ({
        name: row.name ?? "Unknown",
        count: Number(row.count ?? 0),
      })),
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Could not load dashboard data.";
    return NextResponse.json({ ok: false, error: message }, { status: 500 });
  }
}

