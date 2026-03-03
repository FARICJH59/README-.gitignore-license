import ChatUI from "./components/ChatUI";

export default function App() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-slate-50 via-white to-slate-100 text-slate-900">
      <div className="mx-auto flex max-w-6xl flex-col gap-10 px-6 py-12">
        <header className="space-y-3">
          <p className="text-sm font-semibold text-indigo-600">AxiomCore + Cloudflare AI Playground</p>
          <h1 className="text-4xl font-bold">Copilot scaffold for agent workflows</h1>
          <p className="max-w-3xl text-lg text-slate-600">
            Stateful agents on Durable Objects, multi-step Cloudflare Workflows, and a React chat UI using the
            <code className="mx-1 rounded bg-slate-100 px-2 py-1 text-sm">useAgent</code> hook.
          </p>
        </header>

        <section className="grid gap-6 md:grid-cols-2">
          <div className="rounded-2xl bg-white p-6 shadow-sm ring-1 ring-slate-200">
            <h2 className="text-xl font-semibold text-slate-900">Backend</h2>
            <ul className="mt-3 list-disc space-y-2 pl-5 text-sm text-slate-700">
              <li>
                <span className="font-semibold">CoreAgent</span> with callable task orchestration
              </li>
              <li>
                <span className="font-semibold">ChatAgent</span> streaming via Workers AI provider
              </li>
              <li>Workflow example: fetch → generate → approve → publish</li>
            </ul>
          </div>
          <div className="rounded-2xl bg-white p-6 shadow-sm ring-1 ring-slate-200">
            <h2 className="text-xl font-semibold text-slate-900">Tooling</h2>
            <ul className="mt-3 list-disc space-y-2 pl-5 text-sm text-slate-700">
              <li>Vectorize and R2 helpers for RAG pipelines</li>
              <li>HuggingFace integration for multimodal models</li>
              <li>CLI script to scaffold and launch backend + frontend</li>
            </ul>
          </div>
        </section>

        <ChatUI />
      </div>
    </div>
  );
}
