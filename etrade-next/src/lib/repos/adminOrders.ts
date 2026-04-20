import { getPool, query, sql } from "../db";
import { ORDER_STATUS } from "../orderStatus";

export type AdminOrderListItem = {
  ID: number;
  UserId: number;
  Username: string | null;
  NameSurname: string | null;
  Date: Date | null;
  TotalPrice: number;
  Status: number;
  RejectReasonCode: string | null;
  RejectReasonNote: string | null;
  CargoCompany: string | null;
  TrackingNo: string | null;
  ApprovedAt: Date | null;
  RejectedAt: Date | null;
  ShippedAt: Date | null;
  DeliveredAt: Date | null;
  CustomerConfirmedAt: Date | null;
};

export async function listOrdersForAdmin(
  opts: { page?: number; pageSize?: number } = {}
): Promise<{ orders: AdminOrderListItem[]; total: number; page: number; pageSize: number }> {
  const page = Math.max(1, Number(opts.page ?? 1));
  const pageSize = Math.min(100, Math.max(1, Number(opts.pageSize ?? 20)));
  const offset = (page - 1) * pageSize;

  const totalRows = await query<{ Total: number }>(
    `
    SELECT COUNT(*) AS Total
    FROM dbo.ORDERS;
    `
  );
  const total = Number(totalRows[0]?.Total ?? 0);

  const rows = await query<AdminOrderListItem>(
    `
    SELECT
      o.ID,
      o.USERID AS UserId,
      u.USERNAME_ AS Username,
      u.NAMESURNAME AS NameSurname,
      o.DATE_ AS Date,
      o.TOTALPRICE AS TotalPrice,
      o.STATUS_ AS Status
    FROM dbo.ORDERS o
    LEFT JOIN dbo.USERS u ON u.ID = o.USERID
    ORDER BY o.DATE_ DESC, o.ID DESC
    OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY;
    `,
    { offset, limit: pageSize }
  );

  const orders = rows.map((r) => ({
    ...r,
    ID: Number(r.ID),
    UserId: Number(r.UserId),
    TotalPrice: Number(r.TotalPrice ?? 0),
    Status: Number(r.Status ?? 0),
    Date: r.Date ? new Date(r.Date) : null,
    RejectReasonCode: null,
    RejectReasonNote: null,
    CargoCompany: null,
    TrackingNo: null,
    ApprovedAt: null,
    RejectedAt: null,
    ShippedAt: null,
    DeliveredAt: null,
    CustomerConfirmedAt: null,
  }));

  return { orders, total, page, pageSize };
}

export type AdminOrderDetail = AdminOrderListItem & {
  AddressText: string | null;
  City: string | null;
  Town: string | null;
  ShippedNote?: string | null;
  ShippingInfoNote?: string | null;
};

export type AdminOrderLine = {
  ItemId: number;
  ItemName: string | null;
  Brand: string | null;
  ImageUrl: string | null;
  Qty: number;
  UnitPrice: number;
  LineTotal: number;
};

export async function getOrderDetailForAdmin(orderId: number): Promise<AdminOrderDetail | null> {
  const rows = await query<AdminOrderDetail>(
    `
    SELECT TOP (1)
      o.ID,
      o.USERID AS UserId,
      u.USERNAME_ AS Username,
      u.NAMESURNAME AS NameSurname,
      o.DATE_ AS Date,
      o.TOTALPRICE AS TotalPrice,
      o.STATUS_ AS Status,
      a.ADDRESSTEXT AS AddressText,
      c.CITY AS City,
      t.TOWN AS Town,
      (
        SELECT TOP (1) h.NOTE
        FROM dbo.ORDER_STATUS_HISTORY h
        WHERE h.ORDER_ID = o.ID
          AND h.NEW_STATUS = ${ORDER_STATUS.SHIPPED}
        ORDER BY h.CHANGED_AT DESC, h.ID DESC
      ) AS ShippedNote,
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
    LEFT JOIN dbo.USERS u ON u.ID = o.USERID
    LEFT JOIN dbo.ADDRESS a ON a.ID = o.ADDRESSID
    LEFT JOIN dbo.CITIES c ON c.ID = a.CITYID
    LEFT JOIN dbo.TOWNS t ON t.ID = a.TOWNID
    WHERE o.ID = @orderId;
    `,
    { orderId: Number(orderId) }
  );
  const r = rows[0];
  if (!r) return null;
  return {
    ...r,
    ID: Number(r.ID),
    UserId: Number(r.UserId),
    TotalPrice: Number(r.TotalPrice ?? 0),
    Status: Number(r.Status ?? 0),
    Date: r.Date ? new Date(r.Date) : null,
    RejectReasonCode: null,
    RejectReasonNote: null,
    CargoCompany: null,
    TrackingNo: null,
    ApprovedAt: null,
    RejectedAt: null,
    ShippedAt: null,
    DeliveredAt: null,
    CustomerConfirmedAt: null,
  };
}

export async function listOrderLinesForAdmin(orderId: number): Promise<AdminOrderLine[]> {
  const rows = await query<AdminOrderLine>(
    `
    SELECT
      od.ITEMID AS ItemId,
      i.ITEMNAME AS ItemName,
      i.BRAND AS Brand,
      i.IMAGE_URL AS ImageUrl,
      od.AMOUNT AS Qty,
      od.UNITPRICE AS UnitPrice,
      od.LINETOTAL AS LineTotal
    FROM dbo.ORDERDETAILS od
    LEFT JOIN dbo.ITEMS i ON i.ID = od.ITEMID
    WHERE od.ORDERID = @orderId
    ORDER BY od.ID ASC;
    `,
    { orderId: Number(orderId) }
  );
  return rows.map((r) => ({
    ...r,
    ItemId: Number(r.ItemId),
    Qty: Number(r.Qty ?? 0),
    UnitPrice: Number(r.UnitPrice ?? 0),
    LineTotal: Number(r.LineTotal ?? 0),
  }));
}

type UpdateOrderStatusOpts = {
  orderId: number;
  newStatus: number;
  note?: string | null;
  rejectReasonCode?: string | null;
  rejectReasonNote?: string | null;
  cargoCompany?: string | null;
  trackingNo?: string | null;
};

export async function updateOrderStatusByAdmin(opts: UpdateOrderStatusOpts) {
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    const getReq = new sql.Request(tx);
    getReq.input("orderId", Number(opts.orderId));
    const currentOrder = await getReq.query<{ Status: number }>(`
      SELECT TOP (1) STATUS_ AS Status
      FROM dbo.ORDERS
      WHERE ID = @orderId;
    `);
    const oldStatus = Number(currentOrder.recordset?.[0]?.Status ?? -1);
    if (oldStatus < 0) throw new Error("Order not found.");

    const updateReq = new sql.Request(tx);
    updateReq.input("orderId", Number(opts.orderId));
    updateReq.input("newStatus", Number(opts.newStatus));
    await updateReq.query(`
      UPDATE dbo.ORDERS
      SET
        STATUS_ = @newStatus
      WHERE ID = @orderId;
    `);

    const historyReq = new sql.Request(tx);
    historyReq.input("orderId", Number(opts.orderId));
    historyReq.input("oldStatus", Number(oldStatus));
    historyReq.input("newStatus", Number(opts.newStatus));
    historyReq.input("note", opts.note ?? null);
    historyReq.input("changedBy", "admin");

    await historyReq.query(`
      INSERT INTO dbo.ORDER_STATUS_HISTORY
        (ORDER_ID, OLD_STATUS, NEW_STATUS, NOTE, CHANGED_BY)
      VALUES
        (@orderId, @oldStatus, @newStatus, @note, @changedBy);
    `);

    await tx.commit();
  } catch (error) {
    try {
      await tx.rollback();
    } catch {
      // ignore rollback errors
    }
    throw error;
  }
}

export async function confirmDeliveredByUser(orderId: number, userId: number) {
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    const getReq = new sql.Request(tx);
    getReq.input("orderId", Number(orderId));
    getReq.input("userId", Number(userId));
    const currentOrder = await getReq.query<{ Status: number }>(`
      SELECT TOP (1) STATUS_ AS Status
      FROM dbo.ORDERS
      WHERE ID = @orderId AND USERID = @userId;
    `);

    const oldStatus = Number(currentOrder.recordset?.[0]?.Status ?? -1);
    if (oldStatus !== ORDER_STATUS.DELIVERED && oldStatus !== ORDER_STATUS.SHIPPED) {
      throw new Error("Order is not in shippable confirmation status.");
    }

    const updateReq = new sql.Request(tx);
    updateReq.input("orderId", Number(orderId));
    updateReq.input("userId", Number(userId));
    await updateReq.query(`
      UPDATE dbo.ORDERS
      SET STATUS_ = ${ORDER_STATUS.COMPLETED}
      WHERE ID = @orderId AND USERID = @userId;
    `);

    const historyReq = new sql.Request(tx);
    historyReq.input("orderId", Number(orderId));
    historyReq.input("oldStatus", Number(oldStatus));
    historyReq.input("newStatus", ORDER_STATUS.COMPLETED);
    historyReq.input("note", "Customer confirmed delivery.");
    historyReq.input("changedBy", "customer");
    historyReq.input("changedByUserId", Number(userId));
    await historyReq.query(`
      INSERT INTO dbo.ORDER_STATUS_HISTORY
        (ORDER_ID, OLD_STATUS, NEW_STATUS, NOTE, CHANGED_BY, CHANGED_BY_USER_ID)
      VALUES
        (@orderId, @oldStatus, @newStatus, @note, @changedBy, @changedByUserId);
    `);

    await tx.commit();
  } catch (error) {
    try {
      await tx.rollback();
    } catch {
      // ignore rollback errors
    }
    throw error;
  }
}

