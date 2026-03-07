# AxiomCore + Cloudflare AI Playground Copilot Scaffold

An opinionated starter that pairs AxiomCore-style agents with Cloudflare Workers AI, Durable Objects, Workflows, and a React chat UI.

## 🚀 Hyperscale Ops Dashboard (AxiomCore)

- Dashboard: `public/HYPERSCALE_DASHBOARD.html` (auto-refresh every 30s, live alerts, Mermaid architecture/runtime/deployment diagrams)
- Backend API: `backend/server.js` (Express) with control endpoints:
  - `POST /api/updateWorkerReplicas` `{ replicas }`
  - `POST /api/updateGPUCluster` `{ cluster, nodes }`
  - `POST /api/redeployClusters`
  - `POST /api/deployDryRun`
  - `POST /api/runCodeQL`
  - plus `GET /api/usage`, `GET /api/drift`, `GET /api/codeql`
- Reports: `USAGE_REPORT.json`, `DRIFT_REPORT.json`, `codeql-results/summary.json`
- Ops scripts: `deploy_axiomcore_prod.ps1`, `bootstrap_axiomcore.ps1`, `axiocore_hyperscale_drift_suite.ps1`, `run_codeql_scan.ps1`
- Kubernetes: `k8s/` manifests for brain cluster (200), worker pool (500), GPU clusters (LLM 100 / Vision 50 / ML 50 / Embedding 50), task queue, telemetry
- CI/CD: `.github/workflows/axiomcore-ci-cd.yml` (Docker build/push to ghcr, dry-run validation, CodeQL, drift suite, conditional deploy)

**Run locally**
```bash
node backend/server.js
# open http://localhost:3000/HYPERSCALE_DASHBOARD.html
```

## 1️⃣ Project Structure

```
axiomcore-cloudflare/
├─ backend/
│   ├─ agents/
│   │   ├─ coreAgent.ts          # Base agent class (state + orchestration)
│   │   ├─ chatAgent.ts          # AIChatAgent for streaming chat
│   │   └─ workflowAgents/       # Multi-step workflow agents
│   ├─ workflows/
│   │   └─ contentWorkflow.ts    # Example workflow: fetch → AI → approve → publish
│   ├─ workers/
│   │   └─ mainWorker.ts         # Cloudflare Worker bootstrap
│   └─ utils/
│       ├─ r2.ts                 # Storage helpers
│       ├─ vectorize.ts          # RAG helpers
│       └─ huggingface.ts        # HF API integration
│
├─ frontend/
│   ├─ src/
│   │   ├─ App.jsx               # React entry
│   │   ├─ pages/
│   │   │   └─ index.jsx
│   │   └─ components/
│   │       └─ ChatUI.jsx        # Chat component using useAgent
│   └─ styles/
│       └─ globals.css
│
├─ package.json
├─ tailwind.config.ts
├─ tsconfig.json
└─ scripts/cloudflare-scaffold.sh
```

## 2️⃣ Backend Agent Classes

`backend/agents/coreAgent.ts`
```ts
import { Agent, callable } from "agents";

export class CoreAgent extends Agent {
  initialState = { tasks: [] };

  @callable()
  addTask(task: string) {
    this.setState({ tasks: [...this.state.tasks, task] });
    return this.state.tasks;
  }

  @callable()
  listTasks() {
    return this.state.tasks;
  }
}
```

`backend/agents/chatAgent.ts`
```ts
import { AIChatAgent } from "@cloudflare/ai-chat";
import { createWorkersAI } from "workers-ai-provider";
import { streamText, convertToModelMessages } from "ai";

export class ChatAgent extends AIChatAgent {
  async onChatMessage() {
    const workersai = createWorkersAI({ binding: this.env.AI });
    const result = streamText({
      model: workersai("@cf/zai-org/glm-4.7-flash"),
      messages: await convertToModelMessages(this.messages),
    });
    return result.toUIMessageStreamResponse();
  }
}
```

## 3️⃣ Cloudflare Workflow Example

`backend/workflows/contentWorkflow.ts`
```ts
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

    await step.waitForEvent("await approval", { event: "approved", timeout: "24h" });

    await step.do("publish", async () => {
      await this.env.R2_BUCKET.put(`public/${event.params.key}`, serializedOutput);
    });

    return output;
  }
}
```

## 4️⃣ Front-End Integration

`frontend/src/components/ChatUI.jsx`
```jsx
import { useAgent } from "agents/react";
import { useState } from "react";

export default function ChatUI() {
  const [messages, setMessages] = useState([]);
  const agent = useAgent({
    agent: "ChatAgent",
    onStateUpdate: (state) => setMessages(state.messages ?? []),
  });

  const sendMessage = (msg) => agent.stub.sendMessage(msg);

  return (
    // UI rendering chat history + composer
  );
}
```

The default `frontend/src/App.jsx` wires the chat UI alongside feature highlights.

## 5️⃣ CLI / Copilot Scaffold Script

Run the single-command scaffold:
```bash
bash scripts/cloudflare-scaffold.sh
```
This clones the scaffold, installs backend/frontend dependencies, and launches both dev servers.

## 6️⃣ Features Enabled

✅ Agentic, multi-agent orchestration with AxiomCore  
✅ Stateful agents on Cloudflare Durable Objects  
✅ Multi-step workflows with Cloudflare Workflows  
✅ RAG pipelines using Vectorize DB  
✅ HuggingFace / Workers AI integration for LLMs, vision, and embeddings  
✅ React front-end using useAgent hooks  
✅ Human-in-the-loop approvals and event-driven tasks  

---

### Local frontend
```bash
cd frontend
npm install
npm run dev
```

### Notes
- Backend TypeScript files are scaffolded for Cloudflare Worker + Durable Object deployment.
- A lightweight `useAgent` stub is provided so the chat UI functions locally without backend wiring.
