export const ORDER_STATUS = {
  PLACED: 0,
  PREPARING: 1,
  SHIPPED: 2,
  DELIVERED: 3,
  REJECTED: 4,
  COMPLETED: 5,
} as const;

export function orderStatusLabel(status: number) {
  if (status === ORDER_STATUS.PLACED) return "Order placed";
  if (status === ORDER_STATUS.PREPARING) return "Preparing";
  if (status === ORDER_STATUS.SHIPPED) return "Shipped";
  if (status === ORDER_STATUS.DELIVERED) return "Delivered";
  if (status === ORDER_STATUS.REJECTED) return "Rejected";
  if (status === ORDER_STATUS.COMPLETED) return "Completed";
  return `Status: ${status}`;
}

