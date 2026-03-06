import { Agent, callable } from "../shims/agents";
import { AuditLogger } from "../governance/auditLogger";
import { MetricsRecorder } from "../telemetry/metricsRecorder";
import { AgentDescriptor, Capability, Permission } from "../types";
import { registerExecutorAgent } from "../executor/agentRegistry";
import { TemplateDefinition } from "./templateLoader";
import { ArchitecturePlan, ProjectIntent, StackSelection } from "./types";

type StackState = { lastSelection?: StackSelection };

const AGENT_NAME = "StackAgent";

export class StackAgent extends Agent<StackState> {
  readonly capabilities: Capability[] = ["selectStack"];
  readonly permissions: Permission[] = ["read", "write"];
  private audit = new AuditLogger();
  private metrics = new MetricsRecorder();
  initialState: StackState;

  constructor() {
    const baseState: StackState = {};
    super({ state: baseState });
    this.initialState = baseState;
  }

  private pickStack(intent: ProjectIntent, template?: TemplateDefinition): StackSelection {
    const backend = template?.backendFramework ?? "fastapi";
    const frontend = template?.frontendFramework ?? "react";
    const database = template?.database ?? "postgres";
    const mq = template?.messageQueue ?? "kafka";
    return {
      backendFramework: backend,
      frontendFramework: frontend,
      database,
      messageQueue: mq,
      mlStack: template?.mlModules?.length ? "python-ml" : "lightweight",
      infra: template?.infrastructure ?? [],
      reasoning: `Selected based on ${template?.name ?? intent.industry} profile`,
    };
  }

  @callable()
  selectStack(payload: { intent: ProjectIntent; architecture: ArchitecturePlan; template?: TemplateDefinition }): StackSelection {
    this.metrics.recordExecution(1);
    const selection = this.pickStack(payload.intent, payload.template ?? payload.intent.template);
    this.audit.record(AGENT_NAME, "selectStack", "read", {
      industry: payload.intent.industry,
      backend: selection.backendFramework,
      frontend: selection.frontendFramework,
    });
    this.setState({ lastSelection: selection });
    return selection;
  }
}

export const StackAgentDescriptor: AgentDescriptor = {
  name: AGENT_NAME,
  layer: "project-generator",
  capabilities: ["selectStack"],
  permissions: ["read", "write"],
  path: "runtime/project-generator/stackAgent.ts",
  tags: ["stack", "project-generator"],
};

registerExecutorAgent(StackAgentDescriptor);
