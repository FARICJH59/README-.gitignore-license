import React, { useEffect, useState } from "react";

export default function Home() {
  const [backendMessage, setBackendMessage] = useState("Connecting to backend...");

  useEffect(() => {
    const fetchGreeting = async () => {
      try {
        const response = await fetch("/api/hello");
        const data = await response.json();
        setBackendMessage(data.message || "Backend responded");
      } catch (error) {
        setBackendMessage("Failed to connect to backend. Ensure it is running and reachable.");
      }
    };

    fetchGreeting();
  }, []);

  return (
    <div className="min-h-screen bg-slate-50">
      <div className="mx-auto flex max-w-5xl flex-col gap-10 px-6 py-12">
        <header className="space-y-3">
          <p className="text-sm font-semibold text-indigo-600">Agentic Fullstack Platform</p>
          <h1 className="text-4xl font-bold text-slate-900">Build, test, and deploy with confidence</h1>
          <p className="max-w-3xl text-lg text-slate-600">
            React + FastAPI starter wired for local development. TailwindCSS is ready to style your components,
            and the backend sample endpoint is reachable at <code>/api/hello</code>.
          </p>
        </header>

        <section className="grid gap-6 md:grid-cols-2">
          <div className="rounded-2xl bg-white p-6 shadow-sm ring-1 ring-slate-200">
            <h2 className="text-xl font-semibold text-slate-900">Frontend</h2>
            <p className="mt-2 text-sm text-slate-600">
              Edit <code>frontend/pages/index.jsx</code> to customize the landing experience. Global styles live in{" "}
              <code>frontend/styles/globals.css</code>.
            </p>
            <ul className="mt-4 list-disc space-y-2 pl-5 text-sm text-slate-700">
              <li>Runs on Vite with React 18+</li>
              <li>TailwindCSS configured for rapid UI work</li>
              <li>Proxy to backend API during local development</li>
            </ul>
          </div>

          <div className="rounded-2xl bg-white p-6 shadow-sm ring-1 ring-slate-200">
            <h2 className="text-xl font-semibold text-slate-900">Backend</h2>
            <p className="mt-2 text-sm text-slate-600">
              The FastAPI app in <code>server.py</code> exposes a starter endpoint. Extend{" "}
              <code>main.py</code> to connect AI/agent workflows.
            </p>
            <div className="mt-4 rounded-lg bg-slate-900 px-4 py-3 text-sm text-slate-100">
              <div className="text-slate-400">GET /api/hello</div>
              <div className="font-mono">{backendMessage}</div>
            </div>
          </div>
        </section>

        <section className="rounded-2xl bg-indigo-600 px-6 py-5 text-white shadow-sm">
          <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <p className="text-sm uppercase tracking-wide text-indigo-200">Next steps</p>
              <p className="text-lg font-semibold">Update components, connect APIs, and ship.</p>
            </div>
            <div className="flex gap-3 text-sm">
              <span className="rounded-full bg-white/10 px-3 py-1">npm run dev</span>
              <span className="rounded-full bg-white/10 px-3 py-1">python server.py</span>
            </div>
          </div>
        </section>
      </div>
    </div>
  );
}
