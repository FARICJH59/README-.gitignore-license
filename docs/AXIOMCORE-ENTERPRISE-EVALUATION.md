# AxiomCore Enterprise System Evaluation Report

## 1. Architecture Summary

**Core Layers**
- **Bootstrap:** Initializes agent descriptors from `newAgents.json`.
- **Registry:** `agentRegistry.ts` registers agents and enforces layer validation via `layerValidator.ts`.
- **Executor:** `agentExecutor.ts` orchestrates pipelines with retry (`agentRetryManager.ts`) and self-heal (`agentSelfHeal.ts`) support.
- **Scheduler:** `agentScheduler.ts` handles delayed, recurring, and timeout-based execution.
- **Telemetry & Governance:** `metricsRecorder.ts` captures metrics, and `auditLogger.ts` logs actions to ensure observability and compliance.

## 2. Pipeline Execution Flow

1. **Bootstrap load** — Agent descriptors are loaded from `newAgents.json`.
2. **Registry + validation** — Agents are registered in `agentRegistry.ts`, with `layerValidator.ts` ensuring correct layer placement.
3. **Execution orchestration** — `agentExecutor.ts` runs pipelines (sequential or parallel), invoking agents and coordinating results.
4. **Resilience controls** — `agentRetryManager.ts` applies exponential backoff retries; `agentSelfHeal.ts` restarts failed agents when needed.
5. **Scheduling** — `agentScheduler.ts` schedules one-off, recurring, or timeout-based executions that feed back into the executor.
6. **Telemetry & audit** — `metricsRecorder.ts` records execution/failure/retry counts; `auditLogger.ts` logs each action with timestamps and layer validation context.
7. **Output delivery** — Pipeline results are returned to callers after governance hooks complete.
