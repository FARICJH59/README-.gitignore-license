import { create } from "zustand";
import { api, createBackoff } from "../services/api";
import { DriftReport, JobsReport, LogEntry, UsageMetrics } from "../types/dashboard";

type DashboardState = {
  usage?: UsageMetrics;
  drift?: DriftReport;
  jobs?: JobsReport;
  logs: LogEntry[];
  loading: boolean;
  error?: string;
  startPolling: () => void;
  stopPolling: () => void;
};

let intervalId: number | undefined;
let attempt = 0;

export const useDashboardStore = create<DashboardState>((set) => ({
  usage: undefined,
  drift: undefined,
  jobs: undefined,
  logs: [],
  loading: true,
  error: undefined,
  startPolling: () => {
    const poll = async () => {
      const controller = new AbortController();
      try {
        const [usage, drift, jobs, logs] = await Promise.all([
          api.getUsage(controller.signal),
          api.getDrift(controller.signal),
          api.getJobs(controller.signal),
          api.getLogs(controller.signal),
        ]);
        attempt = 0;
        set({ usage, drift, jobs, logs, loading: false, error: undefined });
      } catch (err) {
        attempt += 1;
        set({ error: (err as Error).message, loading: false });
        const delay = createBackoff(attempt);
        if (intervalId) {
          clearInterval(intervalId);
        }
        intervalId = window.setInterval(poll, delay);
        return;
      }
    };

    poll();
    if (!intervalId) {
      intervalId = window.setInterval(poll, 15000);
    }
  },
  stopPolling: () => {
    if (intervalId) {
      clearInterval(intervalId);
      intervalId = undefined;
    }
  },
}));
