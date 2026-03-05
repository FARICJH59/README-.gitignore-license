import { Agent, callable } from "agents";
import { AuditLogger } from "../governance/auditLogger";
import { registerExecutorAgent } from "./agentRegistry";
import { AgentDescriptor, Capability, MetricSnapshot, Permission } from "../types";

type Transaction = {
  id: string;
  amount: number;
  currency?: string;
  location?: string;
  device?: string;
  velocity?: number;
  accountId?: string;
};

type FraudState = {
  metrics: MetricSnapshot;
  lastAuditLogCount: number;
  flagged: { id: string; reason: string; score: number }[];
};

const FRAUD_AGENT_NAME = "FraudDetectionAgent";
const AMOUNT_THRESHOLD = 1000;
const VELOCITY_THRESHOLD = 10;
const SUSPICIOUS_THRESHOLD = 0.7;
const HIGH_RISK_THRESHOLD = 0.9;
const DEVICE_UNKNOWN_PATTERN_SCORE = 0.6;
const DEVICE_KNOWN_SCORE = 0.2;
const LOCATION_REMOTE_SCORE = 0.4;
const LOCATION_NON_HOME_SCORE = 0.2;
const LOCATION_HOME_SCORE = 0;
const WEIGHT_SUM_EPSILON = 1e-6;
const SCORE_WEIGHTS = { amount: 0.4, velocity: 0.3, device: 0.2, location: 0.1 };
const SCORE_WEIGHT_SUM = Object.values(SCORE_WEIGHTS).reduce((sum, weight) => sum + weight, 0);
const DEVICE_UNKNOWN_PATTERN = /\bunknown\b/i;

if (Math.abs(SCORE_WEIGHT_SUM - 1) > WEIGHT_SUM_EPSILON) {
  throw new Error("SCORE_WEIGHTS must sum to 1");
}

export class FraudDetectionAgent extends Agent {
  readonly capabilities: Capability[] = ["analyzeTransactions", "flagSuspicious"];
  readonly permissions: Permission[] = ["read", "write", "alert"];
  private audit = new AuditLogger();

  initialState: FraudState = {
    metrics: { analyzed: 0, flagged: 0, alerts: 0, lastUpdated: Date.now() },
    lastAuditLogCount: 0,
    flagged: [],
  };

  private ensurePermission(permission: Permission) {
    if (!this.permissions.includes(permission)) {
      throw new Error(`Permission ${permission} not granted for ${FRAUD_AGENT_NAME}`);
    }
  }

  private updateMetrics(partial: Partial<MetricSnapshot>) {
    const metrics = { ...this.state.metrics, ...partial, lastUpdated: Date.now() };
    this.setState({ ...this.state, metrics });
  }

  private recordAudit(action: string, permission: Permission, details?: Record<string, unknown>) {
    this.audit.record(FRAUD_AGENT_NAME, action, permission, details);
    this.setState({ ...this.state, lastAuditLogCount: this.audit.getEvents().length });
  }

  @callable()
  analyzeTransactions(transactions: Transaction[]) {
    this.ensurePermission("read");
    const suspicious = transactions
      .map((t) => ({
        tx: t,
        score: this.computeRiskScore(t),
      }))
      .filter(({ score }) => score >= SUSPICIOUS_THRESHOLD);

    const flaggedEntries = suspicious.map(({ tx, score }) => ({
      id: tx.id,
      reason: score > HIGH_RISK_THRESHOLD ? "high-risk pattern" : "velocity/anomaly",
      score,
    }));

    this.recordAudit("analyzeTransactions", "read", {
      total: transactions.length,
      flagged: flaggedEntries.length,
    });

    this.updateMetrics({
      analyzed: this.state.metrics.analyzed + transactions.length,
      flagged: this.state.metrics.flagged + flaggedEntries.length,
    });

    const flagged = [...this.state.flagged, ...flaggedEntries];
    this.setState({ ...this.state, flagged });

    console.debug(`[${FRAUD_AGENT_NAME}] analyzed=${transactions.length} flagged=${flaggedEntries.length}`);
    return { flagged: flaggedEntries, totalAnalyzed: transactions.length };
  }

  @callable()
  flagSuspicious(id: string, reason: string, score: number) {
    this.ensurePermission("alert");
    const entry = { id, reason, score };
    const flagged = [...this.state.flagged, entry];
    this.recordAudit("flagSuspicious", "alert", { id, score, reason });
    this.updateMetrics({ flagged: this.state.metrics.flagged + 1, alerts: this.state.metrics.alerts + 1 });
    this.setState({ ...this.state, flagged });
    console.debug(`[${FRAUD_AGENT_NAME}] alert raised for ${id} reason=${reason} score=${score}`);
    return entry;
  }

  @callable()
  getMetrics() {
    this.ensurePermission("read");
    this.recordAudit("getMetrics", "read");
    return this.state.metrics;
  }

  @callable()
  listFlags() {
    this.ensurePermission("read");
    this.recordAudit("listFlags", "read", { count: this.state.flagged.length });
    return this.state.flagged;
  }

  private computeRiskScore(tx: Transaction) {
    const normalizedAmount = Math.max(tx.amount, 0);
    const amountScore = Math.min(normalizedAmount / AMOUNT_THRESHOLD, 1);
    const normalizedVelocity = Math.max(tx.velocity ?? 0, 0);
    const velocityScore = Math.min(normalizedVelocity / VELOCITY_THRESHOLD, 1);
    const deviceScore = !tx.device
      ? DEVICE_UNKNOWN_PATTERN_SCORE
      : DEVICE_UNKNOWN_PATTERN.test(tx.device)
        ? DEVICE_UNKNOWN_PATTERN_SCORE
        : DEVICE_KNOWN_SCORE;
    const locationScore =
      tx.location === "remote"
        ? LOCATION_REMOTE_SCORE
        : tx.location && tx.location !== "home"
          ? LOCATION_NON_HOME_SCORE
          : LOCATION_HOME_SCORE;
    const weightedScore =
      SCORE_WEIGHTS.amount * amountScore +
      SCORE_WEIGHTS.velocity * velocityScore +
      SCORE_WEIGHTS.device * deviceScore +
      SCORE_WEIGHTS.location * locationScore;
    const score = Number(weightedScore.toFixed(2));
    return score;
  }
}

export const FraudDetectionAgentDescriptor: AgentDescriptor = {
  name: FRAUD_AGENT_NAME,
  layer: "executor",
  capabilities: ["analyzeTransactions", "flagSuspicious"],
  permissions: ["read", "write", "alert"],
  path: "runtime/executor/fraudDetectionAgent.ts",
  tags: ["fraud", "risk", "alerts"],
};

registerExecutorAgent(FraudDetectionAgentDescriptor);
