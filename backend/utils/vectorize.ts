interface VectorizeBinding {
  upsert: (namespace: string, vectors: { id: string; values: number[]; metadata?: Record<string, any> }[]) => Promise<any>;
  query: (namespace: string, options: { topK: number; vector: number[] }) => Promise<any>;
}

interface VectorizeEnv {
  VECTORIZE: VectorizeBinding;
}

export async function upsertVector(env: VectorizeEnv, namespace: string, id: string, vector: number[], metadata: Record<string, any>) {
  return env.VECTORIZE.upsert(namespace, [{ id, values: vector, metadata }]);
}

export async function queryVector(env: VectorizeEnv, namespace: string, vector: number[], topK = 5) {
  return env.VECTORIZE.query(namespace, { topK, vector });
}

export async function embedTextWithAI(env: { AI: any }, text: string) {
  const response = await env.AI.run("@cf/baai/bge-small-en-v1.5", { text });
  return Array.isArray(response.data) ? response.data : response;
}
