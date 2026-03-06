import { Agent, callable } from "../shims/agents";
import { AuditLogger } from "../governance/auditLogger";
import { MetricsRecorder } from "../telemetry/metricsRecorder";
import { AgentDescriptor, Capability, Permission } from "../types";
import { registerExecutorAgent } from "../executor/agentRegistry";
import { BuilderOutput, StackSelection } from "./types";

type BuilderState = { lastBuild?: BuilderOutput };

const AGENT_NAME = "FrontendBuilderAgent";

export class FrontendBuilderAgent extends Agent<BuilderState> {
  readonly capabilities: Capability[] = ["buildFrontend"];
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
  buildFrontend(selection: StackSelection): BuilderOutput {
    this.metrics.recordExecution(1);
    const artifacts: BuilderOutput["artifacts"] = [
      {
        path: "frontend/",
        description: `Scaffold for ${selection.frontendFramework} app`,
        files: ["src/main.tsx", "src/pages", "package.json"],
      },
      { path: "frontend/components", description: "Shared UI library", files: ["Button.tsx", "Layout.tsx"] },
    ];
    const output: BuilderOutput = {
      artifacts,
      summary: `Frontend scaffold prepared with ${selection.frontendFramework}`,
    };
    this.audit.record(AGENT_NAME, "buildFrontend", "write", {
      frontend: selection.frontendFramework,
    });
    this.setState({ lastBuild: output });
    return output;
  }
}

export const FrontendBuilderAgentDescriptor: AgentDescriptor = {
  name: AGENT_NAME,
  layer: "project-generator",
  capabilities: ["buildFrontend"],
  permissions: ["read", "write"],
  path: "runtime/project-generator/frontendBuilderAgent.ts",
  tags: ["builder", "frontend"],
};

registerExecutorAgent(FrontendBuilderAgentDescriptor);
