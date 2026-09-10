export async function findUsers(orgId: string) {
  return db.select().from(users).where(eq(users.orgId, orgId));
}
