import { Agent, callable } from "../shims/agents";
import { AuditLogger } from "../governance/auditLogger";
import { MetricsRecorder } from "../telemetry/metricsRecorder";
import { AgentDescriptor, Capability, Permission } from "../types";
import { registerExecutorAgent } from "../executor/agentRegistry";
import { BuilderOutput, StackSelection } from "./types";

type BuilderState = { lastBuild?: BuilderOutput };

const AGENT_NAME = "MLBuilderAgent";

export class MLBuilderAgent extends Agent<BuilderState> {
  readonly capabilities: Capability[] = ["buildML"];
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
  buildML(selection: StackSelection): BuilderOutput {
    this.metrics.recordExecution(1);
    const artifacts: BuilderOutput["artifacts"] = [
      {
        path: "ml/",
        description: `ML scaffold using ${selection.mlStack ?? "python"} stack`,
        files: ["notebooks", "pipelines", "models"],
      },
    ];
    const output: BuilderOutput = { artifacts, summary: "ML scaffolding prepared" };
    this.audit.record(AGENT_NAME, "buildML", "write", { mlStack: selection.mlStack });
    this.setState({ lastBuild: output });
    return output;
  }
}

export const MLBuilderAgentDescriptor: AgentDescriptor = {
  name: AGENT_NAME,
  layer: "project-generator",
  capabilities: ["buildML"],
  permissions: ["read", "write"],
  path: "runtime/project-generator/mlBuilderAgent.ts",
  tags: ["builder", "ml"],
};

registerExecutorAgent(MLBuilderAgentDescriptor);
