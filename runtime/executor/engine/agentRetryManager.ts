import { AuditLogger } from "../../governance/auditLogger";
import { MetricsRecorder } from "../../telemetry/metricsRecorder";
import { AgentExecutor } from "./agentExecutor";

const isDebugEnabled = () =>
  (typeof process !== "undefined" && process.env?.DEBUG_BOOTSTRAP === "true") ||
  (globalThis as { DEBUG_BOOTSTRAP?: boolean }).DEBUG_BOOTSTRAP === true;

export class AgentRetryManager {
  private audit: AuditLogger;
  private metrics: MetricsRecorder;
  private debug: boolean;
  private baseDelayMs: number;

  constructor(
    private executor: AgentExecutor,
    options?: { auditLogger?: AuditLogger; metricsRecorder?: MetricsRecorder; baseDelayMs?: number; debug?: boolean },
  ) {
    this.audit = options?.auditLogger ?? new AuditLogger();
    this.metrics = options?.metricsRecorder ?? executor.getMetricsRecorder();
    this.debug = options?.debug ?? isDebugEnabled();
    this.baseDelayMs = options?.baseDelayMs ?? 100;
  }

  private logDebug(message: string, extra?: Record<string, unknown>) {
    if (this.debug) console.debug(`[AgentRetryManager] ${message}`, extra ?? {});
  }

  async retry(agentName: string, input: unknown, retries = 3) {
    let attempt = 0;
    let lastError: unknown;
    while (attempt <= retries) {
      try {
        if (attempt > 0) {
          this.metrics.recordRetry(1);
          this.audit.record(agentName, "retry-attempt", "read", { attempt });
          this.logDebug(`Retrying ${agentName}`, { attempt });
        }
        const result = await this.executor.run(agentName, input);
        return result;
      } catch (err) {
        lastError = err;
        if (attempt === retries) break;
        const delay = this.baseDelayMs * Math.pow(2, attempt);
        await new Promise((resolve) => setTimeout(resolve, delay));
        attempt += 1;
      }
    }
    this.audit.record(agentName, "retry-exhausted", "read", { retries, error: (lastError as Error)?.message });
    throw lastError;
  }
}
