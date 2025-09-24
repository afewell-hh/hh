import { SecretsManagerClient, GetSecretValueCommand } from "@aws-sdk/client-secrets-manager";

const sm = new SecretsManagerClient({});
const cache = new Map(); // name -> {val, ts}
const TTL_MS = 5 * 60 * 1000;

export async function getJsonSecret(name) {
  const now = Date.now();
  const c = cache.get(name);
  if (c && (now - c.ts) < TTL_MS) return c.val;

  const out = await sm.send(new GetSecretValueCommand({ SecretId: name }));
  const str = out.SecretString ?? Buffer.from(out.SecretBinary).toString("utf8");
  const val = JSON.parse(str);
  cache.set(name, { val, ts: now });
  return val;
}