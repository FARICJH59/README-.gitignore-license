import { Agent, callable } from "../shims/agents";
import { AuditLogger } from "../governance/auditLogger";
import { MetricSnapshot, MetricsRecorder } from "../telemetry/metricsRecorder";
import { AgentDescriptor, Capability, Permission } from "../types";
import { registerExecutorAgent } from "./agentRegistry";

type KeyValue = { key: string; value: unknown };

type ParseInput = Record<string, unknown> | string;

type ParseResult = {
  parsed: KeyValue[];
  errors: string[];
};

type ParserState = {
  metrics: MetricSnapshot;
  lastAuditLogCount: number;
};

const AGENT_NAME = "DataParserAgent";

export class DataParserAgent extends Agent<ParserState> {
  readonly capabilities: Capability[] = ["parseData"];
  readonly permissions: Permission[] = ["read", "write"];
  private audit = new AuditLogger();
  private metrics = new MetricsRecorder();
  private debug: boolean;
  initialState: ParserState;

  constructor(config?: { debug?: boolean }) {
    const baseState: ParserState = {
      metrics: { parsed: 0, errors: 0, lastUpdated: Date.now() },
      lastAuditLogCount: 0,
    };
    super({ state: baseState });
    this.initialState = baseState;
    this.debug = !!config?.debug;
  }

  private ensurePermission(permission: Permission) {
    if (!this.permissions.includes(permission)) {
      throw new Error(`Permission ${permission} not granted for ${AGENT_NAME}`);
    }
  }

  private recordAudit(action: string, permission: Permission, details?: Record<string, unknown>) {
    this.audit.record(AGENT_NAME, action, permission, details);
    this.setState({ ...this.state, lastAuditLogCount: this.audit.getCount() });
  }

  private normalizeInput(input: ParseInput): { data: Record<string, unknown> | null; error?: string } {
    if (typeof input === "string") {
      try {
        const parsed = JSON.parse(input);
        if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
          return { data: parsed as Record<string, unknown> };
        }
        return { data: null, error: "Parsed JSON is not a valid object" };
      } catch (err) {
        return { data: null, error: (err as Error).message };
      }
    }
    if (input && typeof input === "object" && !Array.isArray(input)) {
      return { data: input as Record<string, unknown> };
    }
    return { data: null, error: "Unsupported input type" };
  }

  private toKeyValues(obj: Record<string, unknown>): KeyValue[] {
    return Object.entries(obj).map(([key, value]) => ({ key, value }));
  }

  @callable()
  parseData(input: ParseInput): ParseResult {
    this.ensurePermission("read");
    const normalized = this.normalizeInput(input);
    const errors: string[] = [];
    if (!normalized.data) {
      errors.push(normalized.error ?? "Unknown parse error");
      this.metrics.recordError(1);
      this.recordAudit("parseData", "read", { errors: errors.length });
      this.updateMetrics();
      return { parsed: [], errors };
    }

    const parsed = this.toKeyValues(normalized.data);
    this.metrics.recordParsed(1);
    this.recordAudit("parseData", "read", { parsedKeys: parsed.length });
    this.updateMetrics();

    if (this.debug) {
      console.debug(`[${AGENT_NAME}] parsed ${parsed.length} entries`);
    }

    return { parsed, errors };
  }

  @callable()
  getMetrics() {
    this.ensurePermission("read");
    this.recordAudit("getMetrics", "read");
    this.updateMetrics();
    return this.state.metrics;
  }

  private updateMetrics() {
    const snapshot = this.metrics.getSnapshot();
    this.setState({ ...this.state, metrics: { ...snapshot } });
  }
}

export const DataParserAgentDescriptor: AgentDescriptor = {
  name: AGENT_NAME,
  layer: "executor",
  capabilities: ["parseData"],
  permissions: ["read", "write"],
  path: "runtime/executor/dataParserAgent.ts",
  tags: ["parser", "structured-data"],
};

registerExecutorAgent(DataParserAgentDescriptor);
