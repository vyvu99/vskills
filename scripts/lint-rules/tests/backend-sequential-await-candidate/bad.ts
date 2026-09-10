export async function loadDashboard(orgId: string) {
  const user = await db.select().from(users);
  const posts = await db.select().from(posts);
  return { user, posts };
}
