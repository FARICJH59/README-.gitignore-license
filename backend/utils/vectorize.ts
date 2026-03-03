export async function upsertVector(env: any, namespace: string, id: string, vector: number[], metadata: Record<string, any>) {
  return env.VECTORIZE.upsert(namespace, [{ id, values: vector, metadata }]);
}

export async function queryVector(env: any, namespace: string, vector: number[], topK = 5) {
  return env.VECTORIZE.query(namespace, { topK, vector });
}
