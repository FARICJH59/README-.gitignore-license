import { useEffect } from "react";
import { useDashboardStore } from "../store/dashboardStore";

export const useDashboardData = () => {
  const { usage, drift, jobs, logs, loading, error, startPolling, stopPolling } = useDashboardStore();

  useEffect(() => {
    startPolling();
    return () => stopPolling();
  }, [startPolling, stopPolling]);

  return { usage, drift, jobs, logs, loading, error };
};
