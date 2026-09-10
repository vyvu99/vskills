export async function attachOwners(items: Item[]) {
  return items.map(async (item) => {
    const owner = await db.select().from(users).where(eq(users.id, item.ownerId));
    return { ...item, owner };
  });
}
