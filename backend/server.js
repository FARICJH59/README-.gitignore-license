const express = require("express");
const path = require("path");
const fs = require("fs");
const { execFile } = require("child_process");

const app = express();
const PORT = process.env.PORT || 3000;
const ROOT = path.resolve(__dirname, "..");
const REPORTS = {
  usage: path.join(ROOT, "USAGE_REPORT.json"),
  drift: path.join(ROOT, "DRIFT_REPORT.json"),
  codeql: path.join(ROOT, "codeql-results", "summary.json"),
};

app.use(express.json());
app.use((req, res, next) => {
  const start = Date.now();
  res.on("finish", () => {
    const duration = Date.now() - start;
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.url} -> ${res.statusCode} (${duration}ms)`);
  });
  next();
});

app.use(express.static(path.join(ROOT, "public")));
app.use("/codeql-results", express.static(path.join(ROOT, "codeql-results")));

function runScript(scriptName, args = []) {
  return new Promise((resolve, reject) => {
    const scriptPath = path.join(ROOT, scriptName);
    execFile(
      "pwsh",
      ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", scriptPath, ...args],
      { timeout: 10 * 60 * 1000 },
      (error, stdout, stderr) => {
        if (error) {
          const message = stderr || error.message;
          return reject(new Error(message));
        }
        resolve(stdout.trim());
      }
    );
  });
}

function readJson(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, "utf-8"));
  } catch (err) {
    console.warn(`Failed to read ${filePath}: ${err.message}`);
    return {};
  }
}

function writeJson(filePath, data) {
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
}

function updateUsage(updater) {
  const data = readJson(REPORTS.usage);
  const updated = updater(data) || data;
  updated.updatedAt = new Date().toISOString();
  writeJson(REPORTS.usage, updated);
}

app.get("/api/usage", (_req, res) => res.json(readJson(REPORTS.usage)));
app.get("/api/drift", (_req, res) => res.json(readJson(REPORTS.drift)));
app.get("/api/codeql", (_req, res) => res.json(readJson(REPORTS.codeql)));

app.post("/api/updateWorkerReplicas", async (req, res) => {
  const replicas = Number(req.body?.replicas);
  if (!Number.isFinite(replicas) || replicas < 1 || replicas > 5000) {
    return res.status(400).json({ error: "replicas must be between 1 and 5000" });
  }
  try {
    const output = await runScript("deploy_axiomcore_prod.ps1", ["-WorkerReplicas", String(replicas)]);
    updateUsage((data) => {
      data.clusters = data.clusters || {};
      data.clusters.worker = { ...(data.clusters.worker || {}), nodes: replicas, status: "healthy" };
      return data;
    });
    return res.json({ message: "Worker replicas updated", output });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

app.post("/api/updateGPUCluster", async (req, res) => {
  const cluster = String(req.body?.cluster || "").toLowerCase();
  const nodes = Number(req.body?.nodes);
  if (!["llm", "vision", "ml", "embedding"].includes(cluster)) {
    return res.status(400).json({ error: "cluster must be one of llm|vision|ml|embedding" });
  }
  if (!Number.isFinite(nodes) || nodes < 1 || nodes > 500) {
    return res.status(400).json({ error: "nodes must be between 1 and 500" });
  }
  try {
    const output = await runScript("deploy_axiomcore_prod.ps1", [
      "-GPUCluster",
      cluster,
      "-GPUCount",
      String(nodes),
    ]);
    updateUsage((data) => {
      data.clusters = data.clusters || {};
      data.clusters.gpu = data.clusters.gpu || {};
      const current = data.clusters.gpu[cluster] || {};
      data.clusters.gpu[cluster] = { ...current, nodes, status: "healthy" };
      return data;
    });
    return res.json({ message: "GPU cluster updated", output });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

app.post("/api/redeployClusters", async (_req, res) => {
  try {
    const output = await runScript("deploy_axiomcore_prod.ps1", ["-Redeploy"]);
    return res.json({ message: "Redeploy triggered", output });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

app.post("/api/deployDryRun", async (_req, res) => {
  try {
    const output = await runScript("deploy_axiomcore_prod.ps1", ["-PlanOnly"]);
    return res.json({ message: "Dry-run completed", output });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

app.post("/api/runCodeQL", async (_req, res) => {
  try {
    const output = await runScript("run_codeql_scan.ps1", []);
    return res.json({ message: "CodeQL scan executed", output });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

app.get("/health", (_req, res) => res.json({ ok: true, time: new Date().toISOString() }));

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`AxiomCore hyperscale backend listening on http://localhost:${PORT}`);
  });
}

module.exports = app;
