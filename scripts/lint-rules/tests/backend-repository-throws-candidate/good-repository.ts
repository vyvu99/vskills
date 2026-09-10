export function findUser(id: string) {
  if (!id) {
    return null;
  }
  return db.select().from(users);
}
