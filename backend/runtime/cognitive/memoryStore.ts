import { AuditLogger } from "../../../runtime/governance/auditLogger";
import { MetricsRecorder } from "../../../runtime/telemetry/metricsRecorder";
import { AgentMemoryEntry } from "./graphTypes";

const MEMORY_AGENT = "CognitiveMemoryStore";

export class MemoryStore {
  private store = new Map<string, AgentMemoryEntry[]>();
  private audit: AuditLogger;
  private metrics: MetricsRecorder;

  constructor(options?: { auditLogger?: AuditLogger; metricsRecorder?: MetricsRecorder }) {
    this.audit = options?.auditLogger ?? new AuditLogger();
    this.metrics = options?.metricsRecorder ?? new MetricsRecorder();
  }

  saveMemory(agentId: string, entry: AgentMemoryEntry) {
    const existing = this.store.get(agentId) ?? [];
    const normalized: AgentMemoryEntry = {
      timestamp: entry.timestamp ?? Date.now(),
      data: entry.data,
      tags: entry.tags ?? [],
      relatedNodeIds: entry.relatedNodeIds ?? [],
      summary: entry.summary,
    };
    this.store.set(agentId, [...existing, normalized]);
    this.metrics.recordExecution(1);
    this.audit.record(MEMORY_AGENT, "saveMemory", "write", {
      agentId,
      tags: normalized.tags,
      related: normalized.relatedNodeIds?.length ?? 0,
    });
    return normalized;
  }

  getMemory(agentId: string) {
    const entries = this.store.get(agentId) ?? [];
    this.audit.record(MEMORY_AGENT, "getMemory", "read", { agentId, count: entries.length });
    return [...entries];
  }

  clearMemory(agentId: string) {
    const existed = this.store.has(agentId);
    this.store.delete(agentId);
    this.metrics.recordExecution(1);
    this.audit.record(MEMORY_AGENT, "clearMemory", "write", { agentId, existed });
  }
}
