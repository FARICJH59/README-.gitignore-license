import ChatUI from "../components/ChatUI";

type Props = {
  schema: Record<string, any> | null;
};

export default function LandingPage({ schema }: Props) {
  const agentCount = schema?.agents?.length ?? 2;
  const endpointCount =
    (schema?.endpoints?.ml?.length ?? 0) + (schema?.endpoints?.cv?.length ?? 0) + (schema?.endpoints?.iot?.length ?? 0);

  return (
    <div className="flex flex-col gap-6">
      <section className="grid gap-4 md:grid-cols-3">
        <Card title="Agents" metric={`${agentCount} registered`} description="CoreAgent, ChatAgent, workflow agents" />
        <Card title="Workflows" metric="ContentWorkflow" description="Fetch → AI → approval → publish" />
        <Card title="Endpoints" metric={`${endpointCount || 6} ML/CV/IoT`} description="Vector + telemetry ready" />
      </section>

      <section className="grid gap-6 md:grid-cols-2">
        <div className="rounded-2xl bg-white p-6 shadow-sm ring-1 ring-slate-200">
          <h2 className="text-xl font-semibold text-slate-900">Agentic backend</h2>
          <ul className="mt-3 list-disc space-y-2 pl-5 text-sm text-slate-700">
            <li>Durable Object powered CoreAgent and telemetry buffer</li>
            <li>Workers AI + HuggingFace integration for chat and multimodal tasks</li>
            <li>Vector DB helper for RAG + similarity search</li>
          </ul>
        </div>
        <div className="rounded-2xl bg-white p-6 shadow-sm ring-1 ring-slate-200">
          <h2 className="text-xl font-semibold text-slate-900">Frontend &amp; automation</h2>
          <ul className="mt-3 list-disc space-y-2 pl-5 text-sm text-slate-700">
            <li>React + Tailwind UI with useAgent chat experience</li>
            <li>API + dashboard pages wired to Worker endpoints</li>
            <li>Wrangler + deploy.ps1 ready for Cloudflare Edge shipping</li>
          </ul>
        </div>
      </section>

      <div className="rounded-2xl bg-white p-6 shadow-sm ring-1 ring-slate-200">
        <ChatUI />
      </div>
    </div>
  );
}

function Card({ title, metric, description }: { title: string; metric: string; description: string }) {
  return (
    <div className="rounded-2xl bg-white p-5 shadow-sm ring-1 ring-slate-200">
      <p className="text-xs font-semibold uppercase tracking-wide text-indigo-500">{title}</p>
      <p className="mt-1 text-2xl font-semibold text-slate-900">{metric}</p>
      <p className="mt-2 text-sm text-slate-600">{description}</p>
    </div>
  );
}
