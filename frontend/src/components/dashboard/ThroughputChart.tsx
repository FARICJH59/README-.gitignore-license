import { ResponsiveContainer, LineChart, Line, XAxis, YAxis, Tooltip, CartesianGrid } from "recharts";
import { JobsReport } from "../../types/dashboard";

type Props = {
  jobs?: JobsReport;
};

/**
 * Uses GET /api/jobs -> throughput_per_min to show task throughput trend (synthetic rolling window).
 */
export function ThroughputChart({ jobs }: Props) {
  const data = Array.from({ length: 6 }, (_, idx) => ({
    name: `T-${5 - idx}m`,
    value: jobs ? Math.max(0, jobs.throughput_per_min - idx * 30) : 0,
  }));

  return (
    <div className="rounded-2xl bg-white p-4 shadow-sm ring-1 ring-slate-200">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-xs font-semibold uppercase tracking-wide text-indigo-500">Task Throughput</p>
          <h3 className="text-lg font-semibold text-slate-900">Tasks per minute</h3>
        </div>
      </div>
      <div className="mt-4 h-64">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={data}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="name" />
            <YAxis allowDecimals={false} />
            <Tooltip />
            <Line type="monotone" dataKey="value" stroke="#06b6d4" strokeWidth={2} dot={false} />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
