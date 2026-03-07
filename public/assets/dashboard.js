const logEl = document.getElementById("actionLog");
const projectsTable = document.getElementById("projectsTable");
const clusterState = document.getElementById("clusterState");
const alertsList = document.getElementById("alerts");
const codeqlStatus = document.getElementById("codeqlStatus");
const driftStatus = document.getElementById("driftStatus");
const updatedAt = document.getElementById("updatedAt");

const api = (path, options = {}) =>
  fetch(path, {
    headers: { "Content-Type": "application/json" },
    ...options,
  }).then(async (res) => {
    const text = await res.text();
    let data;
    try {
      data = text ? JSON.parse(text) : {};
    } catch {
      data = { raw: text };
    }
    if (!res.ok) {
      throw new Error(data.error || res.statusText);
    }
    return data;
  });

const formatCurrency = (val) =>
  new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 }).format(val || 0);

const formatNumber = (val, digits = 0) =>
  Number(val || 0).toLocaleString(undefined, { maximumFractionDigits: digits });

const logLine = (msg) => {
  const now = new Date().toISOString();
  const line = `[${now}] ${msg}`;
  logEl.textContent = `${line}\n${logEl.textContent}`.slice(0, 4000);
};

async function loadData() {
  try {
    const [usage, drift, codeql] = await Promise.all([
      api("/api/usage"),
      api("/api/drift"),
      api("/api/codeql").catch(() => ({ status: "unknown" })),
    ]);
    renderKpis(usage);
    renderCluster(usage);
    renderProjects(usage.projects || []);
    renderAlerts(usage, drift, codeql);
    updatedAt.textContent = `Updated ${new Date(usage.updatedAt || Date.now()).toLocaleTimeString()}`;
    updatedAt.classList.remove("warning", "critical");
  } catch (err) {
    updatedAt.textContent = `Update failed: ${err.message}`;
    updatedAt.classList.add("critical");
    logLine(`Refresh error: ${err.message}`);
  }
}

function renderKpis(usage) {
  const { telemetry = {}, quotas = {} } = usage;
  document.getElementById("revenueValue").textContent = formatCurrency(telemetry.revenue);
  document.getElementById("profitValue").textContent = formatCurrency(telemetry.profit);
  document.getElementById("carbonValue").textContent = `${formatNumber(telemetry.carbonKg)} kg`;
  document.getElementById("queueValue").textContent = `${formatNumber(telemetry.taskQueueDepth || 0)} in queue`;
  document.getElementById("energyBadge").textContent = `Energy: ${formatNumber(telemetry.energyMWh)} MWh`;
  document.getElementById("profitBadge").textContent = telemetry.profit < 0 ? "Negative profit alert" : "Profitability steady";
  document.getElementById("profitBadge").className = telemetry.profit < 0 ? "badge critical" : "badge";
  const quotaPct = Math.round((telemetry.quotaUsed || 0) * 100);
  document.getElementById("quotaValue").textContent = `Quota usage: ${quotaPct}%`;
  document.getElementById("carbonBadge").textContent = `Budget: ${formatNumber(quotas.carbonKgBudget || 0)} kg`;
}

function renderCluster(usage) {
  clusterState.innerHTML = "";
  const { clusters = {} } = usage;
  const entries = [
    ["Brain", clusters.brain?.nodes, clusters.brain?.status, clusters.brain?.cpuUtilization, clusters.brain?.energyMWh],
    ["Workers", clusters.worker?.nodes, clusters.worker?.status, clusters.worker?.cpuUtilization, clusters.worker?.energyMWh],
    ["GPU LLM", clusters.gpu?.llm?.nodes, "healthy", clusters.gpu?.llm?.utilization, clusters.gpu?.llm?.energyMWh],
    ["GPU Vision", clusters.gpu?.vision?.nodes, "healthy", clusters.gpu?.vision?.utilization, clusters.gpu?.vision?.energyMWh],
    ["GPU ML", clusters.gpu?.ml?.nodes, "healthy", clusters.gpu?.ml?.utilization, clusters.gpu?.ml?.energyMWh],
    ["GPU Embedding", clusters.gpu?.embedding?.nodes, "healthy", clusters.gpu?.embedding?.utilization, clusters.gpu?.embedding?.energyMWh],
  ];
  entries.forEach(([label, nodes, status, utilization, energy]) => {
    const card = document.createElement("div");
    card.className = "card";
    const utilPct = utilization != null ? `${Math.round(utilization * 100)}%` : "—";
    card.innerHTML = `
      <div class="status-chip ${status === "healthy" ? "healthy" : "warning"}">${label}</div>
      <div class="kpis" style="grid-template-columns: repeat(3,1fr); margin-top:10px;">
        <div class="kpi"><div class="label">Nodes</div><div class="value">${formatNumber(nodes)}</div></div>
        <div class="kpi"><div class="label">Utilization</div><div class="value">${utilPct}</div></div>
        <div class="kpi"><div class="label">Energy</div><div class="value">${formatNumber(energy)} MWh</div></div>
      </div>
    `;
    clusterState.appendChild(card);
  });
}

function renderProjects(projects) {
  projectsTable.innerHTML = "";
  projects
    .slice(0, 5)
    .sort((a, b) => (b.profit || 0) - (a.profit || 0))
    .forEach((p) => {
      const tr = document.createElement("tr");
      tr.innerHTML = `
        <td>${p.name}</td>
        <td>${formatCurrency(p.revenue)}</td>
        <td>${formatCurrency(p.profit)}</td>
        <td>${formatNumber(p.energyMWh, 1)}</td>
        <td>${formatNumber(p.carbonKg, 1)}</td>
      `;
      if ((p.profit || 0) < 0) {
        tr.style.color = "#f87171";
      }
      projectsTable.appendChild(tr);
    });
}

function renderAlerts(usage, drift, codeql) {
  alertsList.innerHTML = "";
  const alerts = [
    ...(usage.telemetry?.alerts || []),
    ...(drift?.findings || []).map((f) => `${f.component}: ${f.details} (${f.severity})`),
  ];
  alerts.forEach((text) => {
    const div = document.createElement("div");
    div.className = "alert";
    div.textContent = text;
    alertsList.appendChild(div);
  });
  codeqlStatus.textContent = `CodeQL: ${codeql.status || "pending"} (${codeql.alerts ?? "n/a"} alerts)`;
  codeqlStatus.className = `status-chip ${codeql.alerts > 0 ? "warning" : "healthy"}`;
  driftStatus.textContent = `Drift: ${drift?.status || "unknown"}`;
  driftStatus.className = `status-chip ${drift?.status === "watch" ? "warning" : "healthy"}`;
}

async function postAction(path, payload) {
  logLine(`Calling ${path} with ${JSON.stringify(payload)}`);
  const data = await api(path, { method: "POST", body: JSON.stringify(payload || {}) });
  logLine(`${path} succeeded: ${data.message || "ok"}`);
}

function wireControls() {
  document.getElementById("workerForm").addEventListener("submit", async (e) => {
    e.preventDefault();
    const replicas = Number(document.getElementById("workerReplicas").value);
    if (!Number.isFinite(replicas) || replicas < 1) {
      return logLine("Worker replicas must be a positive number.");
    }
    try {
      await postAction("/api/updateWorkerReplicas", { replicas });
      loadData();
    } catch (err) {
      logLine(`Worker update failed: ${err.message}`);
    }
  });

  document.getElementById("gpuForm").addEventListener("submit", async (e) => {
    e.preventDefault();
    const cluster = document.getElementById("gpuCluster").value;
    const nodes = Number(document.getElementById("gpuNodes").value);
    if (!Number.isFinite(nodes) || nodes < 1) {
      return logLine("GPU nodes must be positive.");
    }
    try {
      await postAction("/api/updateGPUCluster", { cluster, nodes });
      loadData();
    } catch (err) {
      logLine(`GPU update failed: ${err.message}`);
    }
  });

  document.getElementById("redeployBtn").addEventListener("click", async () => {
    try {
      await postAction("/api/redeployClusters", {});
    } catch (err) {
      logLine(`Redeploy failed: ${err.message}`);
    }
  });

  document.getElementById("dryRunBtn").addEventListener("click", async () => {
    try {
      await postAction("/api/deployDryRun", { planOnly: true });
    } catch (err) {
      logLine(`Dry-run failed: ${err.message}`);
    }
  });

  document.getElementById("codeqlBtn").addEventListener("click", async () => {
    try {
      await postAction("/api/runCodeQL", {});
      loadData();
    } catch (err) {
      logLine(`CodeQL failed: ${err.message}`);
    }
  });
}

wireControls();
loadData();
setInterval(loadData, 30_000);
