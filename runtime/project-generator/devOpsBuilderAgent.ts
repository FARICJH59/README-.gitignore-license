import { Agent, callable } from "../shims/agents";
import { AuditLogger } from "../governance/auditLogger";
import { MetricsRecorder } from "../telemetry/metricsRecorder";
import { AgentDescriptor, Capability, Permission } from "../types";
import { registerExecutorAgent } from "../executor/agentRegistry";
import { BuilderOutput, StackSelection } from "./types";

type BuilderState = { lastBuild?: BuilderOutput };

const AGENT_NAME = "DevOpsBuilderAgent";

export class DevOpsBuilderAgent extends Agent<BuilderState> {
  readonly capabilities: Capability[] = ["buildDevOps"];
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
  buildDevOps(selection: StackSelection): BuilderOutput {
    this.metrics.recordExecution(1);
    const artifacts: BuilderOutput["artifacts"] = [
      { path: "infra/", description: "Infrastructure as code", files: ["terraform/", "helm/"] },
      { path: "docker/", description: "Container specs", files: ["backend.Dockerfile", "frontend.Dockerfile"] },
      { path: "ci/", description: "CI/CD pipelines", files: ["ci.yml"] },
    ];
    const output: BuilderOutput = { artifacts, summary: "DevOps scaffolding prepared" };
    this.audit.record(AGENT_NAME, "buildDevOps", "write", {
      backend: selection.backendFramework,
      infra: selection.infra?.length ?? 0,
    });
    this.setState({ lastBuild: output });
    return output;
  }
}

export const DevOpsBuilderAgentDescriptor: AgentDescriptor = {
  name: AGENT_NAME,
  layer: "project-generator",
  capabilities: ["buildDevOps"],
  permissions: ["read", "write"],
  path: "runtime/project-generator/devOpsBuilderAgent.ts",
  tags: ["builder", "devops"],
};

registerExecutorAgent(DevOpsBuilderAgentDescriptor);
