import { WorkflowEntrypoint, WorkflowStep, WorkflowEvent } from "cloudflare/workflows";

export class ContentWorkflow extends WorkflowEntrypoint {
  async run(event: WorkflowEvent, step: WorkflowStep) {
    const data = await step.do("fetch material", async () => {
      const obj = await this.env.R2_BUCKET.get(event.params.key);
      if (!obj) throw new Error(`Missing object for key ${event.params.key}`);
      return await obj.arrayBuffer();
    });

    const output = await step.do("generate content", async () => {
      return await this.env.AI.run("@cf/llava-hf/llava-1.5-7b-hf", {
        prompt: "Generate article based on this material",
        max_tokens: 300,
        data: Array.from(new Uint8Array(data)),
      });
    });
    const serializedOutput = typeof output === "string" ? output : JSON.stringify(output);

    // External systems should emit the "approved" event (e.g., via webhook/API) to resume the workflow.
    await step.waitForEvent("await approval", { event: "approved", timeout: "24h" });

    await step.do("publish", async () => {
      await this.env.R2_BUCKET.put(`public/${event.params.key}`, serializedOutput);
    });

    return output;
  }
}
