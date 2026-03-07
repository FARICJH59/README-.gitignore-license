import { KVNamespace } from "cloudflare:workers";

export interface KvEnv {
  KV_STATE: KVNamespace;
}

type JsonValue = string | number | boolean | null | JsonValue[] | { [key: string]: JsonValue };

export async function putJson(env: KvEnv, key: string, value: JsonValue, options?: { expirationTtl?: number }) {
  const payload = JSON.stringify(value);
  await env.KV_STATE.put(key, payload, { expirationTtl: options?.expirationTtl });
  return value;
}

export async function getJson<T extends JsonValue>(env: KvEnv, key: string): Promise<T | null> {
  const raw = await env.KV_STATE.get(key);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as T;
  } catch {
    return null;
  }
}

export async function listByPrefix(env: KvEnv, prefix: string) {
  const list = await env.KV_STATE.list({ prefix });
  return list.keys.map((k) => k.name);
}

export async function appendTelemetry(env: KvEnv, deviceId: string, payload: Record<string, unknown>) {
  const key = `iot:${deviceId}:${Date.now()}`;
  return putJson(env, key, { deviceId, payload, ts: Date.now() }, { expirationTtl: 60 * 60 * 24 });
}
