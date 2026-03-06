import { Agent, callable } from "../shims/agents";
import { AuditLogger } from "../governance/auditLogger";
import { MetricsRecorder, MetricSnapshot } from "../telemetry/metricsRecorder";
import { AgentDescriptor, Capability, Permission } from "../types";
import { registerExecutorAgent } from "./agentRegistry";

type VisionInput = { labels?: string[]; confidence?: number } | string[];

type VisionState = {
  metrics: MetricSnapshot;
  lastAuditLogCount: number;
  lastSummary?: string;
};

const VISION_AGENT_NAME = "VisionAgent";
const CONFIDENCE_THRESHOLD = 0.6;

export class VisionAgent extends Agent<VisionState> {
  readonly capabilities: Capability[] = ["execute"];
  readonly permissions: Permission[] = ["read", "write"];
  private audit = new AuditLogger();
  private metrics = new MetricsRecorder();
  initialState: VisionState;

  constructor() {
    const baseState: VisionState = {
      metrics: {
        parsed: 0,
        errors: 0,
        executions: 0,
        retries: 0,
        recoveries: 0,
        lastUpdated: Date.now(),
      },
      lastAuditLogCount: 0,
      lastSummary: undefined,
    };
    super({ state: baseState });
    this.initialState = baseState;
  }

  private ensurePermission(permission: Permission) {
    if (!this.permissions.includes(permission)) {
      throw new Error(`Permission ${permission} not granted for ${VISION_AGENT_NAME}`);
    }
  }

  private recordAudit(action: string, permission: Permission, details?: Record<string, unknown>) {
    this.audit.record(VISION_AGENT_NAME, action, permission, details);
    this.setState({ ...this.state, lastAuditLogCount: this.audit.getCount() });
  }

  private updateMetrics() {
    const snapshot = this.metrics.getSnapshot();
    this.setState({ ...this.state, metrics: { ...snapshot } });
  }

  private normalize(input: VisionInput): { labels: string[]; confidence: number } {
    if (Array.isArray(input)) return { labels: input, confidence: 0.5 };
    const labels = Array.isArray(input.labels) ? input.labels : [];
    const confidence = typeof input.confidence === "number" ? input.confidence : 0.5;
    return { labels, confidence };
  }

  private summarize(labels: string[], confidence: number) {
    const filtered = labels.slice(0, 5);
    const primary = filtered.join(", ") || "unclassified";
    const status = confidence >= CONFIDENCE_THRESHOLD ? "confident" : "tentative";
    return { summary: `${status}: ${primary}`, status, labels: filtered, confidence };
  }

  @callable()
  execute(input: VisionInput = []) {
    this.ensurePermission("read");
    try {
      this.metrics.recordExecution(1);
      const normalized = this.normalize(input);
      const result = this.summarize(normalized.labels, normalized.confidence);
      this.recordAudit("execute", "read", { labels: result.labels.length, confidence: result.confidence });
      this.updateMetrics();
      this.setState({ ...this.state, lastSummary: result.summary });
      return result;
    } catch (error) {
      this.metrics.recordError(1);
      this.recordAudit("execute:error", "read", { error: (error as Error).message });
      this.updateMetrics();
      throw error;
    }
  }
}

export const VisionAgentDescriptor: AgentDescriptor = {
  name: VISION_AGENT_NAME,
  layer: "executor",
  capabilities: ["execute"],
  permissions: ["read", "write"],
  path: "runtime/executor/visionAgent.ts",
  tags: ["vision", "classification"],
};

registerExecutorAgent(VisionAgentDescriptor);
