import { JobsReport } from "../../types/dashboard";

type Props = {
  jobs?: JobsReport;
  loading: boolean;
};

/**
 * Uses GET /api/jobs -> queue depth + active/pending jobs.
 */
export function QueuePanel({ jobs, loading }: Props) {
  const rows = jobs?.jobs ?? [];
  return (
    <div className="rounded-2xl bg-white p-4 shadow-sm ring-1 ring-slate-200">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-xs font-semibold uppercase tracking-wide text-indigo-500">Jobs Queue</p>
          <h3 className="text-lg font-semibold text-slate-900">Active & pending tasks</h3>
        </div>
        <div className="flex gap-3 text-sm text-slate-600">
          <span>Depth: {loading ? "…" : jobs?.queue_depth ?? "—"}</span>
          <span>Throughput/min: {loading ? "…" : jobs?.throughput_per_min ?? "—"}</span>
        </div>
      </div>
      <div className="mt-3 overflow-auto rounded-xl border border-slate-200">
        <table className="min-w-full text-left text-sm">
          <thead className="bg-slate-50 text-xs uppercase text-slate-500">
            <tr>
              <th className="px-3 py-2">ID</th>
              <th className="px-3 py-2">Type</th>
              <th className="px-3 py-2">Status</th>
              <th className="px-3 py-2">ETA (s)</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => (
              <tr key={row.id} className="border-t border-slate-100">
                <td className="px-3 py-2 font-mono text-xs text-slate-800">{row.id}</td>
                <td className="px-3 py-2">{row.type}</td>
                <td className="px-3 py-2">
                  <StatusPill status={row.status} />
                </td>
                <td className="px-3 py-2">{row.eta_sec ?? "—"}</td>
              </tr>
            ))}
            {rows.length === 0 && (
              <tr>
                <td colSpan={4} className="px-3 py-4 text-center text-slate-500">
                  {loading ? "Loading queue…" : "No queued jobs"}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function StatusPill({ status }: { status: string }) {
  const color =
    status === "active" ? "bg-emerald-100 text-emerald-700" : status === "pending" ? "bg-amber-100 text-amber-700" : "bg-slate-100 text-slate-700";
  return <span className={`rounded-full px-3 py-1 text-xs font-semibold ${color}`}>{status}</span>;
}
