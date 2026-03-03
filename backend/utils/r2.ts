import { R2Bucket } from "cloudflare:workers";

interface R2Env {
  R2_BUCKET: R2Bucket;
}

export async function getFromR2(env: R2Env, key: string) {
  const obj = await env.R2_BUCKET.get(key);
  if (!obj) return null;
  return await obj.arrayBuffer();
}

export async function putToR2(env: R2Env, key: string, data: ArrayBuffer | string | ArrayBufferView) {
  await env.R2_BUCKET.put(key, data);
}
