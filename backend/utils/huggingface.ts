const HF_API = "https://api-inference.huggingface.co/models";

export async function hfInference(model: string, payload: Record<string, any>, token: string) {
  const res = await fetch(`${HF_API}/${model}`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    throw new Error(`HF request failed: ${res.status}`);
  }
  return res.json();
}
