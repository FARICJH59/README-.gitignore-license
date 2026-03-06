import { Agent, callable } from "../shims/agents";
import { AuditLogger } from "../governance/auditLogger";
import { MetricsRecorder } from "../telemetry/metricsRecorder";
import { AgentDescriptor, Capability, Permission } from "../types";
import { registerExecutorAgent } from "../executor/agentRegistry";
import { loadTemplate } from "./templateLoader";
import { ProjectIntent } from "./types";

type IntentState = { lastIntent?: ProjectIntent };

const AGENT_NAME = "IntentAgent";

export class IntentAgent extends Agent<IntentState> {
  readonly capabilities: Capability[] = ["parseIntent"];
  readonly permissions: Permission[] = ["read", "write"];
  private audit = new AuditLogger();
  private metrics = new MetricsRecorder();
  initialState: IntentState;

  constructor() {
    const baseState: IntentState = { lastIntent: undefined };
    super({ state: baseState });
    this.initialState = baseState;
  }

  private recordAudit(action: string, details?: Record<string, unknown>) {
    this.audit.record(AGENT_NAME, action, "read", details);
  }

  private normalizeIndustry(request: string) {
    const lower = request.toLowerCase();
    if (lower.includes("fintech")) return "fintech";
    if (lower.includes("health")) return "healthcare";
    if (lower.includes("robot")) return "robotics";
    if (lower.includes("ai")) return "ai_platform";
    if (lower.includes("iot")) return "iot";
    if (lower.includes("city")) return "smart_city";
    if (lower.includes("saas")) return "saas";
    return "saas";
  }

  @callable()
  parseIntent(request: string): ProjectIntent {
    this.metrics.recordExecution(1);
    const industry = this.normalizeIndustry(request);
    const template = loadTemplate(industry);
    const intent: ProjectIntent = {
      industry,
      objectives: [request],
      targetUsers: ["primary"],
      constraints: [],
      template,
      raw: request,
    };
    this.recordAudit("parseIntent", { industry, template: template.name });
    this.setState({ lastIntent: intent });
    return intent;
  }
}

export const IntentAgentDescriptor: AgentDescriptor = {
  name: AGENT_NAME,
  layer: "project-generator",
  capabilities: ["parseIntent"],
  permissions: ["read", "write"],
  path: "runtime/project-generator/intentAgent.ts",
  tags: ["project-generator", "intent"],
};

registerExecutorAgent(IntentAgentDescriptor);
