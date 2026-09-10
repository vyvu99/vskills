export async function getUser(c) {
  try {
    const user = await userService.find(c.req.param('id'));
    return c.json(user);
  } catch (err) {
    return c.json({ error: 'fail' }, 500);
  }
}
