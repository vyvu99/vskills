export async function loadDashboard(orgId: string) {
  const [user, posts] = await Promise.all([db.select().from(users), db.select().from(posts)]);
  return { user, posts };
}
