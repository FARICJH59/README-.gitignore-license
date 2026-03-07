import { LogEntry } from "../../types/dashboard";

type Props = {
  logs: LogEntry[];
  loading: boolean;
};

/**
 * Uses GET /api/logs -> System log entries (errors, alerts).
 */
export function LogsPanel({ logs, loading }: Props) {
  return (
    <div className="rounded-2xl bg-white p-4 shadow-sm ring-1 ring-slate-200">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-xs font-semibold uppercase tracking-wide text-indigo-500">System Logs</p>
          <h3 className="text-lg font-semibold text-slate-900">Latest alerts</h3>
        </div>
        <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-700">{logs.length} entries</span>
      </div>
      <div className="mt-3 space-y-2">
        {logs.map((log) => (
          <div key={log.timestamp + log.message} className="rounded-xl border border-slate-200 bg-slate-50 px-3 py-2">
            <div className="flex items-center justify-between text-xs text-slate-600">
              <span>{new Date(log.timestamp).toLocaleTimeString()}</span>
              <span className={`font-semibold ${log.level === "error" ? "text-rose-600" : log.level === "warn" ? "text-amber-600" : "text-emerald-700"}`}>
                {log.level.toUpperCase()}
              </span>
            </div>
            <p className="mt-1 text-sm text-slate-800">{log.message}</p>
          </div>
        ))}
        {logs.length === 0 && <p className="text-sm text-slate-500">{loading ? "Loading logs…" : "No recent logs"}</p>}
      </div>
    </div>
  );
}
