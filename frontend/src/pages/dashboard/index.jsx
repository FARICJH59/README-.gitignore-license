export default function DashboardPage({ telemetry }) {
  return (
    <div className="grid gap-6 lg:grid-cols-3">
      <Card
        title="Workflows"
        metric="ContentWorkflow"
        description="Fetch → AI → approval → publish with Vectorize + R2 persistence."
      />
      <Card
        title="Vector index"
        metric="content-drafts / axiomcore"
        description="Text + image embeddings ready for RAG queries."
      />
      <Card title="Durable Object" metric="AXIOM_DO" description="Stores agent state + telemetry buffer." />

      <div className="lg:col-span-3 rounded-2xl bg-white p-6 shadow-sm ring-1 ring-slate-200">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide text-indigo-500">IoT Telemetry</p>
            <h3 className="text-lg font-semibold text-slate-900">Recent device updates</h3>
          </div>
          <span className="rounded-full bg-indigo-50 px-3 py-1 text-xs font-semibold text-indigo-700">
            {telemetry?.length ?? 0} device(s)
          </span>
        </div>
        <div className="mt-4 grid gap-3 md:grid-cols-2">
          {(telemetry ?? []).length === 0 && (
            <p className="text-sm text-slate-500">Deploy the worker and post to /iot/telemetry to see live device data.</p>
          )}
          {(telemetry ?? []).map((item) => (
            <div key={item.deviceId} className="rounded-xl border border-slate-200 p-4">
              <p className="text-sm font-semibold text-slate-900">{item.deviceId}</p>
              <p className="text-xs text-slate-500">Last payload</p>
              <pre className="mt-2 max-h-24 overflow-auto rounded bg-slate-50 p-2 text-xs text-slate-700">
                {JSON.stringify(item.last ?? {}, null, 2)}
              </pre>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function Card({ title, metric, description }) {
  return (
    <div className="rounded-2xl bg-white p-5 shadow-sm ring-1 ring-slate-200">
      <p className="text-xs font-semibold uppercase tracking-wide text-indigo-500">{title}</p>
      <p className="mt-1 text-2xl font-semibold text-slate-900">{metric}</p>
      <p className="mt-2 text-sm text-slate-600">{description}</p>
    </div>
  );
}
