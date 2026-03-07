import { Agent, callable } from "../shims/agents";
import { AuditLogger } from "../governance/auditLogger";
import { MetricsRecorder, MetricSnapshot } from "../telemetry/metricsRecorder";
import { AgentDescriptor, Capability, Permission } from "../types";
import { registerExecutorAgent } from "./agentRegistry";

type PredictionInput =
  | { features: number[]; context?: Record<string, unknown> }
  | number[]
  | Record<string, number>;

type PredictionOutput = { score: number; label: "low" | "medium" | "high"; details?: Record<string, unknown> };

type PredictionState = {
  metrics: MetricSnapshot;
  lastScore: number | null;
  lastAuditLogCount: number;
};

const HIGH_THRESHOLD = 0.75;
const MEDIUM_THRESHOLD = 0.4;
// Feature vectors are expected to be percentile-style inputs (0-100).
const SCORE_NORMALIZATION_MAX = 100;
const isFiniteNumber = (value: unknown): value is number => typeof value === "number" && Number.isFinite(value);

const PREDICTION_AGENT_NAME = "PredictionAgent";

function normalizeFeatures(input: PredictionInput): number[] {
  let values: unknown[] = [];
  if (Array.isArray(input)) values = input;
  else if ("features" in input && Array.isArray(input.features)) values = input.features;
  else if (typeof input === "object" && input !== null) values = Object.values(input);
  else throw new Error("Unsupported prediction input type");

  const filtered = values.filter(isFiniteNumber);
  if (!filtered.length) {
    throw new Error("Prediction features must contain at least one finite number");
  }
  if (filtered.length !== values.length) {
    console.warn(
      `[${PREDICTION_AGENT_NAME}] Dropped ${values.length - filtered.length} non-numeric feature values from prediction input.`,
    );
  }
  return filtered;
}

function toLabel(score: number): PredictionOutput["label"] {
  if (score >= HIGH_THRESHOLD) return "high";
  if (score >= MEDIUM_THRESHOLD) return "medium";
  return "low";
}

export class PredictionAgent extends Agent<PredictionState> {
  readonly capabilities: Capability[] = ["execute"];
  readonly permissions: Permission[] = ["read", "write"];
  private audit = new AuditLogger();
  private metrics = new MetricsRecorder();
  private debug: boolean;
  initialState: PredictionState;

  constructor(config?: { debug?: boolean }) {
    const baseState: PredictionState = {
      metrics: {
        parsed: 0,
        errors: 0,
        executions: 0,
        retries: 0,
        recoveries: 0,
        lastUpdated: Date.now(),
      },
      lastScore: null,
      lastAuditLogCount: 0,
    };
    super({ state: baseState });
    this.initialState = baseState;
    this.debug = !!config?.debug;
  }

  private ensurePermission(permission: Permission) {
    if (!this.permissions.includes(permission)) {
      throw new Error(`Permission ${permission} not granted for ${PREDICTION_AGENT_NAME}`);
    }
  }

  private recordAudit(action: string, permission: Permission, details?: Record<string, unknown>) {
    this.audit.record(PREDICTION_AGENT_NAME, action, permission, details);
    this.setState({ ...this.state, lastAuditLogCount: this.audit.getCount() });
  }

  private updateMetrics() {
    const snapshot = this.metrics.getSnapshot();
    this.setState({ ...this.state, metrics: { ...snapshot } });
  }

  private computeScore(features: number[]) {
    if (!features.length) {
      throw new Error("No features available for scoring");
    }
    // Use compensated summation to reduce precision loss for larger inputs.
    let sum = 0;
    let compensation = 0;
    for (const value of features) {
      const y = value - compensation;
      const t = sum + y;
      compensation = t - sum - y;
      sum = t;
    }
    const mean = sum / features.length;
    // Normalize between 0 and 1. Use the greater of the configured ceiling or observed max to avoid ceiling effects.
    const maxObserved = Math.max(...features);
    const normalizationMax = Math.max(SCORE_NORMALIZATION_MAX, maxObserved);
    const bounded = Math.max(0, Math.min(1, mean / normalizationMax));
    return Number(bounded.toFixed(2));
  }

  @callable()
  execute(input: PredictionInput): PredictionOutput {
    this.ensurePermission("read");
    try {
      const features = normalizeFeatures(input);
      this.metrics.recordExecution(1);
      const score = this.computeScore(features);
      const label = toLabel(score);
      const details = { featureCount: features.length };
      this.recordAudit("execute", "read", { score, ...details });
      this.updateMetrics();
      this.setState({ ...this.state, lastScore: score });
      if (this.debug) {
        console.debug(`[${PREDICTION_AGENT_NAME}] score=${score} label=${label}`);
      }
      return { score, label, details };
    } catch (error) {
      this.metrics.recordError(1);
      this.recordAudit("execute:error", "read", { error: (error as Error).message });
      this.updateMetrics();
      throw error;
    }
  }

  @callable()
  getMetrics() {
    this.ensurePermission("read");
    this.recordAudit("getMetrics", "read");
    this.updateMetrics();
    return this.state.metrics;
  }
}

export const PredictionAgentDescriptor: AgentDescriptor = {
  name: PREDICTION_AGENT_NAME,
  layer: "executor",
  capabilities: ["execute"],
  permissions: ["read", "write"],
  path: "runtime/executor/predictionAgent.ts",
  tags: ["prediction", "scoring"],
};

registerExecutorAgent(PredictionAgentDescriptor);
