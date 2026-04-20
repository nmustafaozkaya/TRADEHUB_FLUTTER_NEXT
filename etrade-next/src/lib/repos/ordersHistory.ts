import { query } from "../db";

export type OrderRow = {
  ID: number;
  USERID: number | null;
  DATE_: Date | string | null;
  TOTALPRICE: number | null;
  STATUS_: number | null;
  ADDRESSID: number | null;
};

export type OrderListItem = {
  ID: number;
  Date: Date | null;
  TotalPrice: number;
  Status: number;
  AddressText: string | null;
  City: string | null;
  Town: string | null;
  TotalQty?: number;
  DistinctItems?: number;
  ItemIds?: string | null;
  RejectReasonCode?: string | null;
  RejectReasonNote?: string | null;
  CargoCompany?: string | null;
  TrackingNo?: string | null;
  ApprovedAt?: Date | null;
  RejectedAt?: Date | null;
  ShippedAt?: Date | null;
  DeliveredAt?: Date | null;
  CustomerConfirmedAt?: Date | null;
};

export async function listOrdersForUser(userId: number, limit = 50): Promise<OrderListItem[]> {
  const rows = await query<OrderListItem>(
    `
    SELECT TOP (@limit)
      o.ID,
      o.DATE_ AS Date,
      o.TOTALPRICE AS TotalPrice,
      o.STATUS_ AS Status,
      o.CARGO_COMPANY AS CargoCompany,
      o.TRACKING_NO AS TrackingNo,
      a.ADDRESSTEXT AS AddressText,
      ci.CITY AS City,
      t.TOWN AS Town
    FROM dbo.ORDERS o
    LEFT JOIN dbo.ADDRESS a ON a.ID = o.ADDRESSID
    LEFT JOIN dbo.CITIES ci ON ci.ID = a.CITYID
    LEFT JOIN dbo.TOWNS t ON t.ID = a.TOWNID
    WHERE o.USERID = @userId
    ORDER BY o.DATE_ DESC, o.ID DESC;
    `,
    { userId: Number(userId), limit: Number(limit) }
  );
  return rows.map((r) => ({
    ...r,
    ID: Number(r.ID),
    TotalPrice: Number(r.TotalPrice ?? 0),
    Status: Number(r.Status ?? 0),
    Date: r.Date ? new Date(r.Date) : null,
      RejectReasonCode: null,
      RejectReasonNote: null,
      CargoCompany: r.CargoCompany || null,
      TrackingNo: r.TrackingNo || null,
      ApprovedAt: null,
      RejectedAt: null,
      ShippedAt: null,
      DeliveredAt: null,
      CustomerConfirmedAt: null,
  }));
}

export async function listOrdersForUserUi(
  userId: number,
  opts: { q?: string; status?: string } = {}
): Promise<OrderListItem[]> {
  const q = opts.q?.trim() || null;
  const status = opts.status?.trim() || "all";

  const rows = await query<OrderListItem>(
    `
    SELECT TOP (100)
      o.ID,
      o.DATE_ AS Date,
      o.TOTALPRICE AS TotalPrice,
      o.STATUS_ AS Status,
      o.CARGO_COMPANY AS CargoCompany,
      o.TRACKING_NO AS TrackingNo,
      a.ADDRESSTEXT AS AddressText,
      ci.CITY AS City,
      t.TOWN AS Town,
      SUM(od.AMOUNT) AS TotalQty,
      COUNT(DISTINCT od.ITEMID) AS DistinctItems,
      STRING_AGG(CONVERT(varchar(20), od.ITEMID), ',') AS ItemIds
    FROM dbo.ORDERS o
    LEFT JOIN dbo.ORDERDETAILS od ON od.ORDERID = o.ID
    LEFT JOIN dbo.ADDRESS a ON a.ID = o.ADDRESSID
    LEFT JOIN dbo.CITIES ci ON ci.ID = a.CITYID
    LEFT JOIN dbo.TOWNS t ON t.ID = a.TOWNID
    WHERE o.USERID = @userId
      AND (
        @q IS NULL OR EXISTS (
          SELECT 1
          FROM dbo.ORDERDETAILS od2
          LEFT JOIN dbo.ITEMS i2 ON i2.ID = od2.ITEMID
          WHERE od2.ORDERID = o.ID
            AND (
              i2.ITEMNAME LIKE '%' + @q + '%'
              OR i2.BRAND LIKE '%' + @q + '%'
            )
        )
      )
      AND (
        @status = 'all'
        OR (@status = 'ongoing' AND o.STATUS_ IN (0,1,2,3))
        OR (@status = 'cancelled' AND o.STATUS_ IN (4))
        OR (@status = 'completed' AND o.STATUS_ IN (5))
      )
    GROUP BY
      o.ID, o.DATE_, o.TOTALPRICE, o.STATUS_, o.CARGO_COMPANY, o.TRACKING_NO, a.ADDRESSTEXT, ci.CITY, t.TOWN
    ORDER BY o.DATE_ DESC, o.ID DESC;
    `,
    { userId: Number(userId), q, status }
  );

  return rows.map((r) => ({
    ...r,
    ID: Number(r.ID),
    TotalPrice: Number(r.TotalPrice ?? 0),
    Status: Number(r.Status ?? 0),
    TotalQty: Number(r.TotalQty ?? 0),
    DistinctItems: Number(r.DistinctItems ?? 0),
    Date: r.Date ? new Date(r.Date) : null,
    ItemIds: r.ItemIds ?? null,
    RejectReasonCode: null,
    RejectReasonNote: null,
    CargoCompany: r.CargoCompany || null,
    TrackingNo: r.TrackingNo || null,
    ApprovedAt: null,
    RejectedAt: null,
    ShippedAt: null,
    DeliveredAt: null,
    CustomerConfirmedAt: null,
  }));
}

export type OrderDetailLine = {
  ItemId: number;
  ItemName: string | null;
  Brand: string | null;
  Qty: number;
  UnitPrice: number;
  LineTotal: number;
};

export async function getOrderForUser(userId: number, orderId: number) {
  const rows = await query<OrderListItem>(
    `
    SELECT TOP (1)
      o.ID,
      o.DATE_ AS Date,
      o.TOTALPRICE AS TotalPrice,
      o.STATUS_ AS Status,
      o.CARGO_COMPANY AS CargoCompany,
      o.TRACKING_NO AS TrackingNo,
      a.ADDRESSTEXT AS AddressText,
      ci.CITY AS City,
      t.TOWN AS Town,
      (
        SELECT TOP (1) h.NOTE
        FROM dbo.ORDER_STATUS_HISTORY h
        WHERE h.ORDER_ID = o.ID
          AND h.NOTE IS NOT NULL
          AND (
            h.NOTE LIKE 'Kargo:%Tracking:%'
            OR h.NOTE LIKE 'Cargo:%Tracking:%'
            OR h.NOTE LIKE '%Tracking no:%'
          )
        ORDER BY h.CHANGED_AT DESC, h.ID DESC
      ) AS ShippingInfoNote
    FROM dbo.ORDERS o
    LEFT JOIN dbo.ADDRESS a ON a.ID = o.ADDRESSID
    LEFT JOIN dbo.CITIES ci ON ci.ID = a.CITYID
    LEFT JOIN dbo.TOWNS t ON t.ID = a.TOWNID
    WHERE o.USERID = @userId AND o.ID = @orderId;
    `,
    { userId: Number(userId), orderId: Number(orderId) }
  );
  const order = rows[0];
  if (!order) return null;
  return {
    ...order,
    ID: Number(order.ID),
    TotalPrice: Number(order.TotalPrice ?? 0),
    Status: Number(order.Status ?? 0),
    Date: order.Date ? new Date(order.Date) : null,
    RejectReasonCode: null,
    RejectReasonNote: null,
    CargoCompany:
      order.CargoCompany ||
      (typeof (order as OrderListItem & { ShippingInfoNote?: string | null }).ShippingInfoNote === "string"
        ? (((order as OrderListItem & { ShippingInfoNote?: string | null }).ShippingInfoNote || "")
            .match(/(?:Kargo|Cargo)\s*:\s*([^|]+)/i)?.[1]
            ?.trim() ?? null)
        : null),
    TrackingNo:
      order.TrackingNo ||
      (typeof (order as OrderListItem & { ShippingInfoNote?: string | null }).ShippingInfoNote === "string"
        ? (((order as OrderListItem & { ShippingInfoNote?: string | null }).ShippingInfoNote || "")
            .match(/Tracking(?:\s*no)?\s*:\s*(.+)$/i)?.[1]
            ?.trim() ?? null)
        : null),
    ApprovedAt: null,
    RejectedAt: null,
    ShippedAt: null,
    DeliveredAt: null,
    CustomerConfirmedAt: null,
  };
}

export async function listOrderLinesForUser(userId: number, orderId: number) {
  const rows = await query<OrderDetailLine>(
    `
    SELECT
      od.ITEMID AS ItemId,
      i.ITEMNAME AS ItemName,
      i.BRAND AS Brand,
      od.AMOUNT AS Qty,
      od.UNITPRICE AS UnitPrice,
      od.LINETOTAL AS LineTotal
    FROM dbo.ORDERDETAILS od
    INNER JOIN dbo.ORDERS o ON o.ID = od.ORDERID
    LEFT JOIN dbo.ITEMS i ON i.ID = od.ITEMID
    WHERE o.USERID = @userId AND od.ORDERID = @orderId
    ORDER BY od.ID ASC;
    `,
    { userId: Number(userId), orderId: Number(orderId) }
  );
  return rows.map((r) => ({
    ...r,
    ItemId: Number(r.ItemId),
    Qty: Number(r.Qty ?? 0),
    UnitPrice: Number(r.UnitPrice ?? 0),
    LineTotal: Number(r.LineTotal ?? 0),
  }));
}

