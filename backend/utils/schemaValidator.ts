import { ChatAgent } from "../agents/chatAgent";
import { CoreAgent } from "../agents/coreAgent";
import { ContentWorkflow } from "../workflows/contentWorkflow";

type EndpointMeta = { path: string; description: string; methods: string[] };

const mlEndpoints: EndpointMeta[] = [
  { path: "/ml/text-embedding", description: "Text embedding and vector upsert", methods: ["POST"] },
  { path: "/ml/image-embedding", description: "Image embedding for RAG + CV", methods: ["POST"] },
];

const cvEndpoints: EndpointMeta[] = [
  { path: "/cv/classify", description: "Computer vision classification via Workers AI", methods: ["POST"] },
  { path: "/cv/detect", description: "Object detection with HuggingFace helper", methods: ["POST"] },
];

const iotEndpoints: EndpointMeta[] = [
  { path: "/iot/telemetry", description: "Ingest IoT telemetry and persist to KV + DO", methods: ["POST"] },
  { path: "/iot/devices", description: "List devices with recent telemetry", methods: ["GET"] },
];

export function generateSchema() {
  return {
    agents: [
      { name: "CoreAgent", classRef: CoreAgent.name, description: "Task/stateful agent with callable methods" },
      { name: "ChatAgent", classRef: ChatAgent.name, description: "Workers AI backed chat agent" },
    ],
    durableObjects: [{ name: "AxiomDurableObject", description: "Holds agent state and workflow context" }],
    workflows: [{ name: "ContentWorkflow", classRef: ContentWorkflow.name, description: "Fetch → AI → approval → publish" }],
    endpoints: { ml: mlEndpoints, cv: cvEndpoints, iot: iotEndpoints },
  };
}

export function validateBindings(env: Record<string, unknown>) {
  const required = ["AI", "AXIOM_DO", "VECTORIZE", "R2_BUCKET", "KV_STATE"];
  const missing = required.filter((key) => env[key] === undefined);
  return { ok: missing.length === 0, missing };
}
