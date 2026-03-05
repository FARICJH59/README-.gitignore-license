import { DurableObject, DurableObjectNamespace, DurableObjectState, DurableObjectStub } from "cloudflare:workers";
import { CoreAgent } from "../agents/coreAgent";
import { handleTextEmbedding, handleImageEmbedding } from "./ml/embeddingWorker";
import { handleClassification, handleDetection } from "./cv/cvWorker";
import { handleListDevices, handleTelemetry } from "./iot/iotWorker";
import { generateSchema, validateBindings } from "../utils/schemaValidator";
import { AgentBootstrap } from "../runtime/orchestrator/agentBootstrap";

interface WorkerConfig {
  debugBootstrap: boolean;
}

const workerConfig: WorkerConfig = {
  debugBootstrap: Boolean((globalThis as { DEBUG_BOOTSTRAP?: unknown }).DEBUG_BOOTSTRAP),
};

const bootstrap = (() => {
  const instance = new AgentBootstrap();
  instance.autoRegister([
    {
      name: "CoreAgent",
      role: "core",
      permissions: ["tasks:create", "tasks:list", "tasks:complete", "context:update"],
      version: "1.0",
    },
    { name: "ChatAgent", role: "chat", permissions: ["read", "write"], version: "1.0" },
    { name: "ContentApprovalAgent", role: "workflow", permissions: ["approve", "publish"], version: "1.0" },
  ]);
  if (workerConfig.debugBootstrap) {
    console.debug("Registered agents:", instance.getRegisteredAgents());
  }
  return instance;
})();

interface AxiomEnv {
  AXIOM_DO: DurableObjectNamespace;
  AI: any;
  VECTORIZE: any;
  R2_BUCKET: any;
  KV_STATE: any;
  HF_TOKEN?: string;
  WORKFLOWS?: any;
}

export class AxiomDurableObject extends DurableObject {
  private agent: CoreAgent;
  private telemetry: Record<string, unknown>[] = [];

  constructor(state: DurableObjectState, env: AxiomEnv) {
    super(state, env);
    this.agent = new CoreAgent({ state: { tasks: [], context: {} }, env });
  }

  async fetch(request: Request) {
    const url = new URL(request.url);
    if (request.method === "POST" && url.pathname === "/tasks") {
      const body = await request.json();
      const task = await this.agent.addTask(body.task);
      return new Response(JSON.stringify({ task }), { headers: { "content-type": "application/json" } });
    }
    if (request.method === "GET" && url.pathname === "/tasks") {
      const tasks = await this.agent.listTasks();
      return new Response(JSON.stringify({ tasks }), { headers: { "content-type": "application/json" } });
    }
    if (request.method === "POST" && url.pathname === "/telemetry") {
      const body = await request.json();
      this.telemetry.push({ ...body, ts: Date.now() });
      if (this.telemetry.length > 50) this.telemetry.shift();
      await this.agent.updateContext("telemetry", this.telemetry);
      return new Response(JSON.stringify({ buffered: this.telemetry.length }), { headers: { "content-type": "application/json" } });
    }
    if (request.method === "GET" && url.pathname === "/telemetry") {
      return new Response(JSON.stringify({ telemetry: this.telemetry }), { headers: { "content-type": "application/json" } });
    }
    return new Response("Not found", { status: 404 });
  }
}

function json(data: unknown, init?: ResponseInit) {
  return new Response(JSON.stringify(data), {
    headers: { "content-type": "application/json" },
    ...init,
  });
}

export default {
  async fetch(request: Request, env: AxiomEnv) {
    const url = new URL(request.url);

    if (url.pathname === "/health") {
      return json({ status: "ok", bindings: validateBindings(env) });
    }

    if (url.pathname === "/schema") {
      return json(generateSchema());
    }

    if (url.pathname.startsWith("/ml")) {
      if (url.pathname.endsWith("/text-embedding") && request.method === "POST") {
        return handleTextEmbedding(request, env);
      }
      if (url.pathname.endsWith("/image-embedding") && request.method === "POST") {
        return handleImageEmbedding(request, env);
      }
    }

    if (url.pathname.startsWith("/cv")) {
      if (url.pathname.endsWith("/classify") && request.method === "POST") {
        return handleClassification(request, env);
      }
      if (url.pathname.endsWith("/detect") && request.method === "POST") {
        return handleDetection(request, env);
      }
    }

    if (url.pathname.startsWith("/iot")) {
      if (url.pathname.endsWith("/telemetry") && request.method === "POST") {
        return handleTelemetry(request, env);
      }
      if (url.pathname.endsWith("/devices") && request.method === "GET") {
        return handleListDevices(env);
      }
    }

    if (url.pathname === "/workflows/content" && request.method === "POST" && env.WORKFLOWS?.start) {
      const body = await request.json();
      const runId = await env.WORKFLOWS.start("ContentWorkflow", { params: { key: body.key } });
      return json({ status: "queued", runId });
    }

    const id = env.AXIOM_DO.idFromName("axiomcore");
    const stub = env.AXIOM_DO.get(id) as DurableObjectStub;
    return stub.fetch(request);
  },
};
