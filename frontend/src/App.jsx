import { useEffect, useState } from "react";
import LandingPage from "./pages";
import ApiPage from "./pages/api";
import DashboardPage from "./pages/dashboard";

const tabs = [
  { id: "overview", label: "Overview" },
  { id: "api", label: "API Playground" },
  { id: "dashboard", label: "Dashboard" },
];

export default function App() {
  const [tab, setTab] = useState("overview");
  const [schema, setSchema] = useState(null);
  const [schemaError, setSchemaError] = useState("");
  const [telemetry, setTelemetry] = useState([]);

  useEffect(() => {
    fetch("/schema")
      .then((res) => res.json())
      .then(setSchema)
      .catch(() => setSchemaError("Schema unavailable in static preview. Deploy Worker to enable live data."));
  }, []);

  useEffect(() => {
    if (tab !== "dashboard") return;
    fetch("/iot/devices")
      .then((res) => res.json())
      .then((data) => setTelemetry(data.devices ?? []))
      .catch(() => setTelemetry([]));
  }, [tab]);

  return (
    <div className="min-h-screen bg-gradient-to-b from-slate-50 via-white to-slate-100 text-slate-900">
      <div className="mx-auto flex max-w-6xl flex-col gap-6 px-6 py-10">
        <header className="space-y-2">
          <p className="text-sm font-semibold text-indigo-600">AxiomCore + Cloudflare AI Playground</p>
          <h1 className="text-4xl font-bold">Copilot scaffold for agent workflows</h1>
          <p className="max-w-3xl text-lg text-slate-600">
            Durable Objects for state, Workflows for human-in-the-loop, Workers AI + HuggingFace for ML/CV, and a React chat UI using the
            <code className="mx-1 rounded bg-slate-100 px-2 py-1 text-sm">useAgent</code> hook.
          </p>
        </header>

        <nav className="flex gap-3 rounded-2xl bg-white p-2 shadow-sm ring-1 ring-slate-200">
          {tabs.map((item) => (
            <button
              key={item.id}
              onClick={() => setTab(item.id)}
              className={`flex-1 rounded-xl px-3 py-2 text-sm font-semibold ${
                tab === item.id ? "bg-indigo-600 text-white shadow-sm" : "text-slate-700 hover:bg-slate-100"
              }`}
            >
              {item.label}
            </button>
          ))}
        </nav>

        {tab === "overview" && <LandingPage schema={schema} />}
        {tab === "api" && <ApiPage schema={schema} schemaError={schemaError} />}
        {tab === "dashboard" && <DashboardPage telemetry={telemetry} />}
      </div>
    </div>
  );
}
