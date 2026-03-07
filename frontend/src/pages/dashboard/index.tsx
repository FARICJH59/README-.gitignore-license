import { LogsPanel } from "../../components/dashboard/LogsPanel";
import { QueuePanel } from "../../components/dashboard/QueuePanel";
import { StatsGrid } from "../../components/dashboard/StatsGrid";
import { ThroughputChart } from "../../components/dashboard/ThroughputChart";
import { GpuChart } from "../../components/dashboard/GpuChart";
import { useDashboardData } from "../../hooks/useDashboardData";

export default function DashboardPage() {
  const { usage, drift, jobs, logs, loading, error } = useDashboardData();

  return (
    <div className="flex flex-col gap-4">
      {error && <div className="rounded-xl bg-amber-50 px-4 py-2 text-sm text-amber-700">Backend unreachable: {error}</div>}
      <StatsGrid usage={usage} drift={drift} loading={loading} />
      <div className="grid gap-4 lg:grid-cols-2">
        <ThroughputChart jobs={jobs} />
        <GpuChart gpu={usage?.gpu_clusters} />
      </div>
      <div className="grid gap-4 lg:grid-cols-2">
        <QueuePanel jobs={jobs} loading={loading} />
        <LogsPanel logs={logs} loading={loading} />
      </div>
    </div>
  );
}
