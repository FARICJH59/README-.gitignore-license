import { Agent, callable } from "../shims/agents";
import { AuditLogger } from "../governance/auditLogger";
import { MetricsRecorder, MetricSnapshot } from "../telemetry/metricsRecorder";
import { AgentDescriptor, Capability, Permission } from "../types";
import { registerExecutorAgent } from "./agentRegistry";

type PricingInput = {
  basePrice?: number;
  demandIndex?: number;
  riskScore?: number;
};

type PricingState = {
  metrics: MetricSnapshot;
  lastAuditLogCount: number;
  lastComputed?: number;
};

const PRICING_AGENT_NAME = "PricingAgent";

export class PricingAgent extends Agent<PricingState> {
  readonly capabilities: Capability[] = ["execute"];
  readonly permissions: Permission[] = ["read", "write"];
  private audit = new AuditLogger();
  private metrics = new MetricsRecorder();
  initialState: PricingState;

  constructor() {
    const baseState: PricingState = {
      metrics: {
        parsed: 0,
        errors: 0,
        executions: 0,
        retries: 0,
        recoveries: 0,
        lastUpdated: Date.now(),
      },
      lastAuditLogCount: 0,
      lastComputed: undefined,
    };
    super({ state: baseState });
    this.initialState = baseState;
  }

  private ensurePermission(permission: Permission) {
    if (!this.permissions.includes(permission)) {
      throw new Error(`Permission ${permission} not granted for ${PRICING_AGENT_NAME}`);
    }
  }

  private recordAudit(action: string, permission: Permission, details?: Record<string, unknown>) {
    this.audit.record(PRICING_AGENT_NAME, action, permission, details);
    this.setState({ ...this.state, lastAuditLogCount: this.audit.getCount() });
  }

  private updateMetrics() {
    const snapshot = this.metrics.getSnapshot();
    this.setState({ ...this.state, metrics: { ...snapshot } });
  }

  private computePrice(input: PricingInput) {
    const base = typeof input.basePrice === "number" ? input.basePrice : 100;
    const demand = typeof input.demandIndex === "number" ? input.demandIndex : 1;
    const risk = typeof input.riskScore === "number" ? input.riskScore : 0;
    const demandMultiplier = Math.max(0.5, Math.min(2, 0.8 + demand * 0.2));
    const riskAdjustment = Math.max(0.8, 1 - risk * 0.2);
    const price = Number((base * demandMultiplier * riskAdjustment).toFixed(2));
    return { price, demandMultiplier, riskAdjustment };
  }

  @callable()
  execute(input: PricingInput = {}) {
    this.ensurePermission("read");
    try {
      this.metrics.recordExecution(1);
      const result = this.computePrice(input);
      this.recordAudit("execute", "read", result);
      this.updateMetrics();
      this.setState({ ...this.state, lastComputed: result.price });
      return { ...result, priced: true };
    } catch (error) {
      this.metrics.recordError(1);
      this.recordAudit("execute:error", "read", { error: (error as Error).message });
      this.updateMetrics();
      throw error;
    }
  }
}

export const PricingAgentDescriptor: AgentDescriptor = {
  name: PRICING_AGENT_NAME,
  layer: "executor",
  capabilities: ["execute"],
  permissions: ["read", "write"],
  path: "runtime/executor/pricingAgent.ts",
  tags: ["pricing", "revenue"],
};

registerExecutorAgent(PricingAgentDescriptor);
