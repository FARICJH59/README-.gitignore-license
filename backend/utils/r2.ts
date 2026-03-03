export async function getFromR2(env: any, key: string) {
  const obj = await env.R2_BUCKET.get(key);
  if (!obj) return null;
  return await obj.arrayBuffer();
}

export async function putToR2(env: any, key: string, data: ArrayBuffer | string | ArrayBufferView) {
  await env.R2_BUCKET.put(key, data);
}
