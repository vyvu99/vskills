export async function getUser(c) {
  const user = await userService.find(c.req.param('id'));
  return c.json(user);
}
