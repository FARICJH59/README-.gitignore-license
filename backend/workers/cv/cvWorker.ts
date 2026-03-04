import { hfInference } from "../../utils/huggingface";

interface CvEnv {
  AI: any;
  HF_TOKEN?: string;
}

export async function handleClassification(request: Request, env: CvEnv) {
  const { image, prompt = "Classify objects" } = await request.json();
  const output = await env.AI.run("@cf/llava-hf/llava-1.5-7b-hf", { prompt, image });
  return new Response(JSON.stringify({ output }), { headers: { "content-type": "application/json" } });
}

export async function handleDetection(request: Request, env: CvEnv) {
  const { image, model = "facebook/detr-resnet-50" } = await request.json();
  const output = await hfInference(model, { inputs: image }, env.HF_TOKEN ?? "");
  return new Response(JSON.stringify({ output }), { headers: { "content-type": "application/json" } });
}
