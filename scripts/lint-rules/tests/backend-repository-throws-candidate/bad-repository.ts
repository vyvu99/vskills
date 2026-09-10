export function findUser(id: string) {
  if (!id) {
    throw new Error('Missing id');
  }
  return db.select().from(users);
}
