import { AuditLogger } from "../../../runtime/governance/auditLogger";
import { MetricsRecorder } from "../../../runtime/telemetry/metricsRecorder";
import { AgentMemoryEntry } from "./graphTypes";

export class MemoryStore {
  private store = new Map<string, AgentMemoryEntry[]>();
  private metrics: MetricsRecorder;
  private audit: AuditLogger;

  constructor(options?: { metrics?: MetricsRecorder; audit?: AuditLogger }) {
    this.metrics = options?.metrics ?? new MetricsRecorder();
    this.audit = options?.audit ?? new AuditLogger();
  }

  saveMemory(agentId: string, entry: AgentMemoryEntry) {
    const current = this.store.get(agentId) ?? [];
    const next = [...current, entry];
    this.store.set(agentId, next);
    this.metrics.recordExecution(1);
    this.audit.record("MemoryStore", "saveMemory", "write", { agentId, entryId: entry.id });
    return entry;
  }

  getMemory(agentId: string) {
    const entries = this.store.get(agentId) ?? [];
    this.metrics.recordExecution(1);
    this.audit.record("MemoryStore", "getMemory", "read", { agentId, count: entries.length });
    return [...entries];
  }

  clearMemory(agentId: string) {
    const existed = this.store.delete(agentId);
    this.metrics.recordExecution(1);
    this.audit.record("MemoryStore", "clearMemory", "write", { agentId, existed });
    return existed;
  }
}
