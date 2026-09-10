// eval fixture: baseline order service, no seeded bugs
import { db } from "./db";

export async function searchOrders(orgId: string, keyword: string) {
  return db.query(
    "SELECT * FROM orders WHERE org_id = $1 AND name ILIKE $2",
    [orgId, `%${keyword}%`]
  );
}

export async function getOrderById(orgId: string, orderId: string) {
  return db.query(
    "SELECT * FROM orders WHERE id = $1 AND org_id = $2",
    [orderId, orgId]
  );
}

export async function getOrderItemsForOrders(orderIds: string[]) {
  return db.query(
    "SELECT * FROM order_items WHERE order_id = ANY($1)",
    [orderIds]
  );
}
