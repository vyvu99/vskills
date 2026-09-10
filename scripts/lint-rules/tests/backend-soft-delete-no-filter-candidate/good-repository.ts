export async function findUsers(orgId: string) {
  return db.select().from(users).where(and(eq(users.orgId, orgId), isNull(users.deletedAt)));
}
