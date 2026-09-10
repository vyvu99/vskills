export async function getPlan(c) {
  const plan = await planService.find(c.req.param('id'));
  return c.json(responseSchema.parse(plan), 200);
}
