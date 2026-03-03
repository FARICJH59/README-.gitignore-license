import { DurableObject, DurableObjectNamespace, DurableObjectState, DurableObjectStub } from "cloudflare:workers";
import { CoreAgent } from "../agents/coreAgent";

interface AxiomEnv {
  AXIOM_DO: DurableObjectNamespace;
}

export class AxiomDurableObject extends DurableObject {
  private agent: CoreAgent;

  constructor(state: DurableObjectState, env: AxiomEnv) {
    super(state, env);
    this.agent = new CoreAgent({ state: { tasks: [] }, env });
  }

  async fetch(request: Request) {
    const url = new URL(request.url);
    if (request.method === "POST" && url.pathname === "/tasks") {
      const body = await request.json();
      const tasks = await this.agent.addTask(body.task);
      return new Response(JSON.stringify({ tasks }), { headers: { "content-type": "application/json" } });
    }
    if (request.method === "GET" && url.pathname === "/tasks") {
      const tasks = await this.agent.listTasks();
      return new Response(JSON.stringify({ tasks }), { headers: { "content-type": "application/json" } });
    }
    return new Response("Not found", { status: 404 });
  }
}

export default {
  async fetch(request: Request, env: AxiomEnv) {
    const url = new URL(request.url);
    if (url.pathname === "/health") {
      return new Response(JSON.stringify({ status: "ok" }), {
        headers: { "content-type": "application/json" },
      });
    }

    const id = env.AXIOM_DO.idFromName("axiomcore");
    const stub = env.AXIOM_DO.get(id) as DurableObjectStub;
    return stub.fetch(request);
  },
};
