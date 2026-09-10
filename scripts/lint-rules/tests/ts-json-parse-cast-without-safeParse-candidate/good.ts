export function loadConfig(raw: string) {
  const result = configSchema.safeParse(JSON.parse(raw));
  return result.success ? result.data : null;
}
