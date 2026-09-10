export function loadConfig(raw: string) {
  const data = JSON.parse(raw) as Config;
  return data;
}
