export async function getUsers(c) {
  const users = await userService.list();
  return c.json(users);
}
