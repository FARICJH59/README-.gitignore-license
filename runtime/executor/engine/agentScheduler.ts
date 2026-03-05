import { AuditLogger } from "../../governance/auditLogger";
import { AgentExecutor } from "./agentExecutor";

type TimerHandle = ReturnType<typeof setTimeout> | ReturnType<typeof setInterval>;
type TimerKind = "timeout" | "interval";
type StoredTimer = { handle: TimerHandle; type: TimerKind };

const isDebugEnabled = () =>
  (typeof process !== "undefined" && process.env?.DEBUG_BOOTSTRAP === "true") ||
  (globalThis as { DEBUG_BOOTSTRAP?: boolean }).DEBUG_BOOTSTRAP === true;

export class AgentScheduler {
  private timers = new Map<string, StoredTimer>();
  private audit: AuditLogger;
  private debug: boolean;

  constructor(private executor: AgentExecutor, options?: { auditLogger?: AuditLogger; debug?: boolean }) {
    this.audit = options?.auditLogger ?? new AuditLogger();
    this.debug = options?.debug ?? isDebugEnabled();
  }

  private logDebug(message: string, extra?: Record<string, unknown>) {
    if (this.debug) console.debug(`[AgentScheduler] ${message}`, extra ?? {});
  }

  schedule(agentName: string, input: unknown, delayMs: number) {
    const id = `timeout-${Date.now()}-${Math.random().toString(16).slice(2)}`;
    const handle = setTimeout(async () => {
      try {
        await this.executor.run(agentName, input);
        this.audit.record(agentName, "scheduled-execution", "read", { delayMs });
      } catch (err) {
        this.audit.record(agentName, "scheduled-failure", "read", { error: (err as Error).message });
      } finally {
        this.timers.delete(id);
      }
    }, delayMs);
    this.timers.set(id, { handle, type: "timeout" });
    this.logDebug(`Scheduled ${agentName} in ${delayMs}ms`, { id });
    return id;
  }

  scheduleRecurring(agentName: string, intervalMs: number, input?: unknown) {
    const id = `interval-${Date.now()}-${Math.random().toString(16).slice(2)}`;
    const handle = setInterval(async () => {
      try {
        await this.executor.run(agentName, input);
        this.audit.record(agentName, "recurring-execution", "read", { intervalMs });
      } catch (err) {
        this.audit.record(agentName, "recurring-failure", "read", { error: (err as Error).message });
      }
    }, intervalMs);
    this.timers.set(id, { handle, type: "interval" });
    this.logDebug(`Scheduled recurring ${agentName} every ${intervalMs}ms`, { id });
    return id;
  }

  cancelScheduled(id: string) {
    const stored = this.timers.get(id);
    if (!stored) return false;
    if (stored.type === "timeout") {
      clearTimeout(stored.handle as ReturnType<typeof setTimeout>);
    } else {
      clearInterval(stored.handle as ReturnType<typeof setInterval>);
    }
    this.timers.delete(id);
    this.logDebug(`Cancelled schedule ${id}`);
    return true;
  }
}
