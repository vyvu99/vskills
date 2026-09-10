export async function getUsers(c) {
  const users = await db.select().from(tables.users);
  return c.json(users);
}
