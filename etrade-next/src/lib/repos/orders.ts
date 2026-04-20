import { sql, getPool } from "../db";
import type { CartLine } from "../cart";
import { shippingFee } from "../shipping";
import type { PaymentMethod } from "../payment";

export async function createOrder(opts: {
  userId: number;
  addressId: number;
  paymentMethod: PaymentMethod;
  lines: CartLine[];
}) {
  const pool = await getPool();
  const tx = new sql.Transaction(pool);

  const safeLines = (opts.lines || []).filter((l) => Number(l.qty) > 0);
  if (!safeLines.length) throw new Error("Cart is empty.");

  const subtotal = safeLines.reduce((sum, l) => sum + Number(l.unitPrice) * Number(l.qty), 0);
  const ship = shippingFee(subtotal);
  const totalPrice = subtotal + ship;

  await tx.begin();
  try {
    const orderReq = new sql.Request(tx);
    orderReq.input("userId", Number(opts.userId));
    orderReq.input("addressId", Number(opts.addressId));
    orderReq.input("totalPrice", totalPrice);
    orderReq.input("status", 0);
    // Keep available for upcoming DB persistence (PAYMENTMETHOD column can be added later).
    orderReq.input("paymentMethod", opts.paymentMethod);

    const orderRes = await orderReq.query<{ ID: number }>(`
      INSERT INTO dbo.ORDERS (USERID, DATE_, TOTALPRICE, STATUS_, ADDRESSID)
      OUTPUT INSERTED.ID AS ID
      VALUES (@userId, GETDATE(), @totalPrice, @status, @addressId);
    `);

    const orderId = Number(orderRes.recordset?.[0]?.ID);
    if (!orderId) throw new Error("Could not create order.");

    for (const line of safeLines) {
      const req = new sql.Request(tx);
      const qty = Number(line.qty);
      const unitPrice = Number(line.unitPrice);
      req.input("orderId", orderId);
      req.input("itemId", Number(line.itemId));
      req.input("amount", qty);
      req.input("unitPrice", unitPrice);
      req.input("lineTotal", unitPrice * qty);

      await req.query(`
        INSERT INTO dbo.ORDERDETAILS (ORDERID, ITEMID, AMOUNT, UNITPRICE, LINETOTAL)
        VALUES (@orderId, @itemId, @amount, @unitPrice, @lineTotal);
      `);
    }

    await tx.commit();
    return orderId;
  } catch (e) {
    try {
      await tx.rollback();
    } catch {
      // ignore rollback errors
    }
    throw e;
  }
}

