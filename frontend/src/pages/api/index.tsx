import { useMemo, useState } from "react";

type Endpoint = { path: string; description: string; methods: string[] };
type Props = { schema: Record<string, any> | null; schemaError: string };

const fallbackEndpoints: Endpoint[] = [
  { path: "/ml/text-embedding", description: "Vectorize text and upsert into Vectorize", methods: ["POST"] },
  { path: "/ml/image-embedding", description: "Create multimodal embeddings for CV/RAG", methods: ["POST"] },
  { path: "/cv/classify", description: "Classify image content with Workers AI", methods: ["POST"] },
  { path: "/cv/detect", description: "Detect objects via HuggingFace DETR", methods: ["POST"] },
  { path: "/iot/telemetry", description: "Ingest IoT telemetry into KV + DO", methods: ["POST"] },
  { path: "/iot/devices", description: "List devices seen in telemetry", methods: ["GET"] },
];

export default function ApiPage({ schema, schemaError }: Props) {
  const endpoints = useMemo(() => {
    if (!schema) return fallbackEndpoints;
    return [...(schema.endpoints?.ml ?? []), ...(schema.endpoints?.cv ?? []), ...(schema.endpoints?.iot ?? [])];
  }, [schema]);

  const [requestBody, setRequestBody] = useState(JSON.stringify({ text: "hello world from AxiomCore" }, null, 2));
  const [response, setResponse] = useState("");

  const sendProbe = async () => {
    try {
      const res = await fetch("/ml/text-embedding", { method: "POST", body: requestBody, headers: { "content-type": "application/json" } });
      const data = await res.json();
      setResponse(JSON.stringify(data, null, 2));
    } catch (err) {
      setResponse(`Deploy the worker to test live endpoints. ${String(err)}`);
    }
  };

  return (
    <div className="grid gap-6 lg:grid-cols-3">
      <div className="space-y-3 lg:col-span-2">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-semibold text-slate-900">API endpoints</h2>
          {schemaError && <span className="text-xs font-semibold text-amber-600">{schemaError}</span>}
        </div>
        <div className="grid gap-3 sm:grid-cols-2">
          {endpoints.map((ep) => (
            <div key={ep.path} className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
              <p className="text-sm font-semibold text-indigo-600">{ep.path}</p>
              <p className="text-xs uppercase tracking-wide text-slate-500">{(ep.methods ?? []).join(", ")}</p>
              <p className="mt-2 text-sm text-slate-700">{ep.description}</p>
            </div>
          ))}
        </div>
      </div>

      <div className="space-y-3 rounded-2xl bg-white p-4 shadow-sm ring-1 ring-slate-200">
        <p className="text-xs font-semibold uppercase tracking-wide text-indigo-500">Try it</p>
        <textarea
          className="w-full rounded-xl border border-slate-200 p-3 text-xs font-mono"
          rows={8}
          value={requestBody}
          onChange={(e) => setRequestBody(e.target.value)}
        />
        <button onClick={sendProbe} className="w-full rounded-xl bg-indigo-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-700">
          Send to /ml/text-embedding
        </button>
        <pre className="max-h-48 overflow-auto rounded-xl bg-slate-900 p-3 text-xs text-slate-50">{response || "Response will appear here"}</pre>
      </div>
    </div>
  );
}
