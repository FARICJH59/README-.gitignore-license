import { AuditLogger } from "../../governance/auditLogger";
import { MetricsRecorder } from "../../telemetry/metricsRecorder";

type RecoveryHandler = () => Promise<unknown>;

const isDebugEnabled = () =>
  (typeof process !== "undefined" && process.env?.DEBUG_BOOTSTRAP === "true") ||
  (globalThis as { DEBUG_BOOTSTRAP?: boolean }).DEBUG_BOOTSTRAP === true;

export class AgentSelfHeal {
  private audit: AuditLogger;
  private metrics: MetricsRecorder;
  private debug: boolean;

  constructor(options?: { auditLogger?: AuditLogger; metricsRecorder?: MetricsRecorder; debug?: boolean }) {
    this.audit = options?.auditLogger ?? new AuditLogger();
    this.metrics = options?.metricsRecorder ?? new MetricsRecorder();
    this.debug = options?.debug ?? isDebugEnabled();
  }

  private logDebug(message: string, extra?: Record<string, unknown>) {
    if (this.debug) {
      console.debug(`[AgentSelfHeal] ${message}`, extra ?? {});
    }
  }

  /**
   * Attempt to recover a crashed agent by restarting it and resetting state.
   */
  async handleFailure(agentName: string, restart: RecoveryHandler, error?: Error) {
    this.audit.record(agentName, "detect-crash", "alert", { error: error?.message });
    this.logDebug(`Detected crash for ${agentName}`, { error: error?.message });
    await restart();
    this.metrics.recordRecovery(1);
    this.audit.record(agentName, "recovered", "alert", { recovered: true });
    this.logDebug(`Recovery completed for ${agentName}`);
  }
}
