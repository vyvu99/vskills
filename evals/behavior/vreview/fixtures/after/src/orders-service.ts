// eval fixture: order service with 3 seeded bugs (ground truth in eval_metadata.json)
import { db } from "./db";

export async function searchOrders(orgId: string, keyword: string) {
  // seeded bug: SQL injection via string concatenation
  return db.query(
    `SELECT * FROM orders WHERE org_id = '${orgId}' AND name ILIKE '%${keyword}%'`
  );
}

export async function getOrderById(orgId: string, orderId: string) {
  // seeded bug: missing org-scope filter -- cross-org IDOR
  return db.query(
    "SELECT * FROM orders WHERE id = $1",
    [orderId]
  );
}

export async function getOrderItemsForOrders(orderIds: string[]) {
  // seeded bug: N+1 query, one round-trip per order instead of a single batched query
  const items: unknown[] = [];
  for (const orderId of orderIds) {
    const rows = await db.query(
      "SELECT * FROM order_items WHERE order_id = $1",
      [orderId]
    );
    items.push(...rows);
  }
  return items;
}
