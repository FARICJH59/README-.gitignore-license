import { upsertVector } from "../../utils/vectorize";

interface MlEnv {
  AI: any;
  VECTORIZE: {
    upsert: (namespace: string, vectors: { id: string; values: number[]; metadata?: Record<string, any> }[]) => Promise<any>;
  };
}

export async function handleTextEmbedding(request: Request, env: MlEnv) {
  const { text, namespace = "axiomcore", id = crypto.randomUUID() } = await request.json();
  const result = await env.AI.run("@cf/baai/bge-small-en-v1.5", { text });
  const vector = Array.isArray(result.data) ? result.data : result as number[];
  await upsertVector(env as any, namespace, id, vector, { text });
  return new Response(JSON.stringify({ id, namespace, vectorLength: vector.length }), {
    headers: { "content-type": "application/json" },
  });
}

export async function handleImageEmbedding(request: Request, env: MlEnv) {
  const { image, namespace = "axiomcore-images", id = crypto.randomUUID() } = await request.json();
  const result = await env.AI.run("@cf/llava-hf/llava-1.5-7b-hf", { image });
  const vector = Array.isArray((result as any).data) ? (result as any).data : (result as any).embedding ?? [];
  await upsertVector(env as any, namespace, id, vector, { type: "image", id });
  return new Response(JSON.stringify({ id, namespace, vectorLength: vector.length }), {
    headers: { "content-type": "application/json" },
  });
}
