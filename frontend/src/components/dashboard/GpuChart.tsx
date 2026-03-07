import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip, Legend, CartesianGrid } from "recharts";
import { GPUClusters } from "../../types/dashboard";

type Props = {
  gpu?: GPUClusters;
};

/**
 * Uses GET /api/usage -> gpu_clusters to visualize per-cluster GPU counts.
 */
export function GpuChart({ gpu }: Props) {
  const data = [
    { name: "LLM", value: gpu?.LLM ?? 0 },
    { name: "Vision", value: gpu?.Vision ?? 0 },
    { name: "ML", value: gpu?.ML ?? 0 },
    { name: "Embedding", value: gpu?.Embedding ?? 0 },
  ];

  return (
    <div className="rounded-2xl bg-white p-4 shadow-sm ring-1 ring-slate-200">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-xs font-semibold uppercase tracking-wide text-indigo-500">GPU Clusters</p>
          <h3 className="text-lg font-semibold text-slate-900">Allocation by cluster</h3>
        </div>
      </div>
      <div className="mt-4 h-64">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={data}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="name" />
            <YAxis allowDecimals={false} />
            <Tooltip />
            <Legend />
            <Bar dataKey="value" fill="#6366f1" radius={[6, 6, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
