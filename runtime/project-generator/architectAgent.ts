import { Agent, callable } from "../shims/agents";
import { AuditLogger } from "../governance/auditLogger";
import { MetricsRecorder } from "../telemetry/metricsRecorder";
import { AgentDescriptor, Capability, Permission } from "../types";
import { registerExecutorAgent } from "../executor/agentRegistry";
import { TemplateDefinition } from "./templateLoader";
import { ArchitecturePlan, ProjectIntent } from "./types";

type ArchitectState = { lastPlan?: ArchitecturePlan };

const AGENT_NAME = "ArchitectAgent";

export class ArchitectAgent extends Agent<ArchitectState> {
  readonly capabilities: Capability[] = ["designArchitecture"];
  readonly permissions: Permission[] = ["read", "write"];
  private audit = new AuditLogger();
  private metrics = new MetricsRecorder();
  initialState: ArchitectState;

  constructor() {
    const baseState: ArchitectState = {};
    super({ state: baseState });
    this.initialState = baseState;
  }

  private deriveFromTemplate(template: TemplateDefinition): ArchitecturePlan {
    return {
      services: template.microservices,
      apis: template.apis,
      dataModels: template.dataModels,
      mlModules: template.mlModules,
      frontendComponents: template.frontend,
      infrastructure: template.infrastructure,
      notes: `Derived from ${template.name}`,
    };
  }

  @callable()
  designArchitecture(intent: ProjectIntent): ArchitecturePlan {
    this.metrics.recordExecution(1);
    const template = intent.template;
    const plan = template ? this.deriveFromTemplate(template) : this.deriveFromTemplate({
      name: intent.industry,
      industry: intent.industry,
      microservices: [],
      dataModels: [],
      mlModules: [],
      apis: [],
      frontend: [],
      infrastructure: [],
    });
    this.audit.record(AGENT_NAME, "designArchitecture", "read", { industry: intent.industry, template: template?.name });
    this.setState({ lastPlan: plan });
    return plan;
  }
}

export const ArchitectAgentDescriptor: AgentDescriptor = {
  name: AGENT_NAME,
  layer: "project-generator",
  capabilities: ["designArchitecture"],
  permissions: ["read", "write"],
  path: "runtime/project-generator/architectAgent.ts",
  tags: ["architecture", "project-generator"],
};

registerExecutorAgent(ArchitectAgentDescriptor);
