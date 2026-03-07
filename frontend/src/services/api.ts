import { DriftReport, JobsReport, LogEntry, UsageMetrics } from "../types/dashboard";

const API_BASE = "/api";

async function fetchJSON<T>(path: string, signal?: AbortSignal): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, { signal, cache: "no-store" });
  if (!res.ok) {
    throw new Error(`Request failed: ${res.status} ${res.statusText}`);
  }
  return res.json();
}

export const api = {
  /**
   * GET /api/usage — Returns UsageMetrics with cluster counts and GPU breakdown.
   */
  getUsage: (signal?: AbortSignal) => fetchJSON<UsageMetrics>("/usage", signal),
  /**
   * GET /api/drift — Returns drift status and changed files.
   */
  getDrift: (signal?: AbortSignal) => fetchJSON<DriftReport>("/drift", signal),
  /**
   * GET /api/jobs — Returns queue depth, throughput, and active/pending jobs.
   */
  getJobs: (signal?: AbortSignal) => fetchJSON<JobsReport>("/jobs", signal),
  /**
   * GET /api/logs — Returns latest system log entries.
   */
  getLogs: (signal?: AbortSignal) => fetchJSON<LogEntry[]>("/logs", signal),
};

export const createBackoff = (attempt: number) => Math.min(30000, 2000 * attempt);
