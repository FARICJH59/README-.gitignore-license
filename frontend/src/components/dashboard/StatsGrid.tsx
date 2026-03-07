import { DriftReport, UsageMetrics } from "../../types/dashboard";

type Props = {
  usage?: UsageMetrics;
  drift?: DriftReport;
  loading: boolean;
};

export function StatsGrid({ usage, drift, loading }: Props) {
  const cards = [
    { label: "Brain Cluster", value: usage?.active_brain_nodes ?? "—", hint: "Nodes orchestrating workloads" },
    { label: "Worker Pool", value: usage?.active_worker_nodes ?? "—", hint: "Task executors" },
    { label: "Queue Depth", value: usage ? usage.active_worker_nodes * 2 : "—", hint: "Synthetic placeholder load" },
    { label: "Energy (MWh)", value: usage?.energy_consumption_mwh ?? "—", hint: "Energy footprint" },
    { label: "Carbon Quota", value: usage?.carbon_quota ?? "—", hint: "Budget alignment" },
    {
      label: "Drift Status",
      value: drift?.drift_detected ? "Drift detected" : "Aligned",
      hint: drift?.summary ?? "Awaiting report",
    },
  ];

  return (
    <div className="grid gap-3 md:grid-cols-3">
      {cards.map((card) => (
        <div key={card.label} className="rounded-2xl bg-white p-4 shadow-sm ring-1 ring-slate-200">
          <p className="text-xs font-semibold uppercase tracking-wide text-indigo-500">{card.label}</p>
          <p className="mt-2 text-2xl font-semibold text-slate-900">{loading ? "…" : card.value}</p>
          <p className="mt-1 text-sm text-slate-600">{card.hint}</p>
        </div>
      ))}
    </div>
  );
}
