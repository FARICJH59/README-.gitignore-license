import { WorkflowEntrypoint, WorkflowStep, WorkflowEvent } from "cloudflare/workflows";
import { upsertVector } from "../utils/vectorize";
import { ContentApprovalAgent } from "../agents/workflowAgents/contentApprovalAgent";

interface WorkflowEnv {
  AI: any;
  R2_BUCKET: any;
  VECTORIZE: any;
}

export class ContentWorkflow extends WorkflowEntrypoint<WorkflowEnv> {
  async run(event: WorkflowEvent, step: WorkflowStep) {
    const data = await step.do("fetch material", async () => {
      const obj = await this.env.R2_BUCKET.get(event.params.key);
      if (!obj) throw new Error(`Missing object for key ${event.params.key}`);
      return await obj.arrayBuffer();
    });

    const output = await step.do("generate content", async () => {
      return await this.env.AI.run("@cf/meta/llama-3-8b-instruct", {
        prompt: `Generate a concise article from supplied data ${event.params.key}`,
        max_tokens: 400,
        stream: false,
        data: Array.from(new Uint8Array(data)),
      });
    });
    const serializedOutput = typeof output === "string" ? output : JSON.stringify(output);

    await step.do("vectorize draft", async () => {
      const text = serializedOutput;
      const embedding = await this.env.AI.run("@cf/baai/bge-small-en-v1.5", { text });
      const vector = Array.isArray(embedding.data) ? embedding.data : embedding;
      await upsertVector(this.env as any, "content-drafts", event.params.key, vector as number[], {
        key: event.params.key,
        status: "pending",
      });
    });

    const approval = await step.do("human approval", async () => {
      const agent = new ContentApprovalAgent({ state: { status: "pending" } });
      await agent.requestApproval(event.params.key, "editor@example.com");
      return agent.state;
    });

    await step.waitForEvent("await approval", { event: "approved", timeout: "24h" });

    await step.do("publish", async () => {
      await this.env.R2_BUCKET.put(`public/${event.params.key}`, serializedOutput, { httpMetadata: { contentType: "application/json" } });
    });

    return { output, approval };
  }
}
