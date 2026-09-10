export async function createUser(data: NewUser) {
  const [result] = await db.insert(users).values(data).returning();
  return result;
}
