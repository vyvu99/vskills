export async function attachOwners(items: Item[], owners: Map<string, Owner>) {
  return items.map(async (item) => {
    return { ...item, owner: owners.get(item.ownerId) };
  });
}
