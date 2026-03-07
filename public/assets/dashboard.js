const API_BASE = "/api";
const REFRESH_MS = 30_000;

const translations = {
  en: {
    neural: "Neural + Quantum + DevOps",
    liveState: "Live cluster state, drift protection, and carbon-aware monetization.",
    refresh: "Refresh",
    kpis: "Live KPIs",
    alerts: "Alerts & Drift",
  },
  fr: {
    neural: "Neuronal + Quantique + DevOps",
    liveState: "État du cluster en direct, protection contre la dérive, monétisation carbone.",
    refresh: "Rafraîchir",
    kpis: "Indicateurs en direct",
    alerts: "Alertes et dérive",
  },
};

const $ = (id) => document.getElementById(id);

const formatNumber = (val) => new Intl.NumberFormat().format(val);

async function fetchJSON(url) {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error(`Request failed: ${res.status}`);
  return res.json();
}

function applyTranslations(locale) {
  document.querySelectorAll("[data-i18n]").forEach((el) => {
    const key = el.getAttribute("data-i18n");
    el.textContent = translations[locale]?.[key] ?? translations.en[key] ?? el.textContent;
  });
}

function renderKPIs(usage) {
  const gpu = usage.gpu_clusters || {};
  const cards = [
    { label: "Brain Nodes", value: formatNumber(usage.active_brain_nodes) },
    { label: "Worker Nodes", value: formatNumber(usage.active_worker_nodes) },
    { label: "LLM GPUs", value: formatNumber(gpu.LLM ?? 0) },
    { label: "Vision GPUs", value: formatNumber(gpu.Vision ?? 0) },
    { label: "ML GPUs", value: formatNumber(gpu.ML ?? 0) },
    { label: "Embedding GPUs", value: formatNumber(gpu.Embedding ?? 0) },
    { label: "Energy (MWh)", value: usage.energy_consumption_mwh ?? "n/a" },
    { label: "Carbon Quota", value: usage.carbon_quota ?? "n/a" },
  ];

  $("kpi-grid").innerHTML = cards
    .map(
      (card) => `
        <div class="kpi-card">
          <p class="kpi-label">${card.label}</p>
          <p class="kpi-value">${card.value}</p>
        </div>
      `
    )
    .join("");
}

function renderAlerts(drift) {
  const alertsEl = $("alerts");
  const hasDrift = drift?.drift_detected;
  const files = (drift?.changed_files ?? []).filter(Boolean);
  const summary = drift?.summary ?? "No drift reported.";

  alertsEl.innerHTML = `
    <div class="alert ${hasDrift ? "alert-warning" : "alert-ok"}">
      <div>
        <p class="eyebrow">Drift Status</p>
        <p class="alert-title">${hasDrift ? "Drift Detected" : "Aligned with Blueprint"}</p>
        <p class="alert-desc">${summary}</p>
      </div>
      <div class="alert-meta">
        <span class="chip ${hasDrift ? "accent" : "calm"}">${hasDrift ? "Action Needed" : "Green"}</span>
        <p class="timestamp">${drift?.timestamp ?? ""}</p>
      </div>
    </div>
    <div class="alert-list">
      ${
        files.length
          ? `<p class="eyebrow">Changed Files</p><ul>${files.map((f) => `<li>${f}</li>`).join("")}</ul>`
          : `<p class="eyebrow">No changed files detected.</p>`
      }
    </div>
  `;
}

function renderMermaid(usage) {
  const gpu = usage.gpu_clusters || {};
  const diagram = `
graph LR
  BrainCluster(("Brain Cluster (${usage.active_brain_nodes || 0})")) -->|tasks| WorkerPool["Worker Pool (${usage.active_worker_nodes || 0})"]
  WorkerPool -->|routes| TaskQueue["Task Queue"]
  WorkerPool -->|LLM| LLM["LLM GPUs (${gpu.LLM || 0})"]
  WorkerPool -->|Vision| Vision["Vision GPUs (${gpu.Vision || 0})"]
  WorkerPool -->|ML| ML["ML GPUs (${gpu.ML || 0})"]
  WorkerPool -->|Embedding| Embedding["Embedding GPUs (${gpu.Embedding || 0})"]
  BrainCluster --> Telemetry["Telemetry & OTEL"]
  TaskQueue -->|metrics| Telemetry
`;

  const node = $("cluster-diagram");
  node.textContent = diagram.trim();
  if (window.mermaid && window.mermaid.initialize) {
    window.mermaid.initialize({ startOnLoad: false, theme: "dark" });
    window.mermaid.init(undefined, node);
  }
}

async function renderDashboard() {
  try {
    const [usage, drift] = await Promise.all([fetchJSON(`${API_BASE}/usage`), fetchJSON(`${API_BASE}/drift`)]);
    renderKPIs(usage);
    renderAlerts(drift);
    renderMermaid(usage);
  } catch (err) {
    $("alerts").innerHTML = `<div class="alert alert-warning"><p>${err.message}</p></div>`;
  }
}

function init() {
  $("refresh").addEventListener("click", renderDashboard);
  $("locale").addEventListener("change", (e) => applyTranslations(e.target.value));
  applyTranslations("en");
  renderDashboard();
  setInterval(renderDashboard, REFRESH_MS);
}

document.addEventListener("DOMContentLoaded", init);
