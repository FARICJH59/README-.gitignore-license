import { Agent, callable } from "../shims/agents";
import { AuditLogger } from "../governance/auditLogger";
import { MetricsRecorder } from "../telemetry/metricsRecorder";
import { AgentDescriptor, Capability, Permission } from "../types";
import { registerExecutorAgent } from "../executor/agentRegistry";
import { BuilderOutput, StackSelection } from "./types";

type BuilderState = { lastBuild?: BuilderOutput };

const AGENT_NAME = "BackendBuilderAgent";

export class BackendBuilderAgent extends Agent<BuilderState> {
  readonly capabilities: Capability[] = ["buildBackend"];
  readonly permissions: Permission[] = ["read", "write"];
  private audit = new AuditLogger();
  private metrics = new MetricsRecorder();
  initialState: BuilderState;

  constructor() {
    const baseState: BuilderState = {};
    super({ state: baseState });
    this.initialState = baseState;
  }

  @callable()
  buildBackend(selection: StackSelection): BuilderOutput {
    this.metrics.recordExecution(1);
    const artifacts: BuilderOutput["artifacts"] = [
      {
        path: "backend/",
        description: `Scaffold for ${selection.backendFramework} services`,
        files: ["src/index.ts", "src/services", "package.json"],
      },
      { path: "backend/api", description: "API layer", files: ["routes", "controllers"] },
      { path: "backend/config", description: "Configuration and env", files: ["default.yaml"] },
    ];
    const output: BuilderOutput = {
      artifacts,
      summary: `Backend scaffold prepared with ${selection.backendFramework} and ${selection.database}`,
    };
    this.audit.record(AGENT_NAME, "buildBackend", "write", {
      backend: selection.backendFramework,
      database: selection.database,
    });
    this.setState({ lastBuild: output });
    return output;
  }
}

export const BackendBuilderAgentDescriptor: AgentDescriptor = {
  name: AGENT_NAME,
  layer: "project-generator",
  capabilities: ["buildBackend"],
  permissions: ["read", "write"],
  path: "runtime/project-generator/backendBuilderAgent.ts",
  tags: ["builder", "backend"],
};

registerExecutorAgent(BackendBuilderAgentDescriptor);
