const express = require("express");
const { execFile } = require("child_process");
const fs = require("fs");
const path = require("path");
const util = require("util");

const execFileAsync = util.promisify(execFile);
const app = express();
const PORT = process.env.PORT || 3000;
const POWERSHELL_BIN = process.env.POWERSHELL_PATH || (process.platform === "win32" ? "powershell" : "pwsh");

app.use(express.json());

// Serve public assets including dashboard and static resources
app.use("/assets", express.static(path.join(__dirname, "../public/assets")));

// Serve Mermaid from node_modules (with CDN fallback handled in HTML)
app.use(
  "/assets/mermaid.min.js",
  express.static(path.join(__dirname, "../node_modules/mermaid/dist/mermaid.min.js"))
);

// Serve static HTML dashboard
app.get("/HYPERSCALE_DASHBOARD.html", (_req, res) => {
  res.sendFile(path.join(__dirname, "../public/HYPERSCALE_DASHBOARD.html"));
});

const runScript = async (scriptName, args = []) => {
  const scriptPath = path.join(__dirname, "../ps", scriptName);
  if (!fs.existsSync(scriptPath)) {
    throw new Error(`Script not found: ${scriptName}`);
  }

  const result = await execFileAsync(POWERSHELL_BIN, ["-File", scriptPath, ...args], {
    windowsHide: true,
    maxBuffer: 1024 * 1024,
  });

  return { stdout: result.stdout.trim(), stderr: result.stderr.trim() };
};

// Deploy endpoint
app.post("/api/deploy", async (req, res) => {
  try {
    const args = req.body?.planOnly ? ["-PlanOnly"] : [];
    const result = await runScript("deploy_axiomcore_prod.ps1", args);
    res.json({ status: "ok", ...result });
  } catch (err) {
    res.status(500).json({ status: "error", message: err.message, stderr: err.stderr, stdout: err.stdout });
  }
});

// Drift protection
app.post("/api/drift", async (_req, res) => {
  try {
    const result = await runScript("axiocore_hyperscale_drift_suite.ps1");
    res.json({ status: "ok", ...result });
  } catch (err) {
    res.status(500).json({ status: "error", message: err.message, stderr: err.stderr, stdout: err.stdout });
  }
});

// Bootstrap
app.post("/api/bootstrap", async (_req, res) => {
  try {
    const result = await runScript("bootstrap_axiomcore.ps1");
    res.json({ status: "ok", ...result });
  } catch (err) {
    res.status(500).json({ status: "error", message: err.message, stderr: err.stderr, stdout: err.stdout });
  }
});

// JSON reports
app.get("/api/usage", (_req, res) => {
  res.sendFile(path.join(__dirname, "../reports/USAGE_REPORT.json"));
});

app.get("/api/drift", (_req, res) => {
  res.sendFile(path.join(__dirname, "../reports/DRIFT_REPORT.json"));
});

app.listen(PORT, () => {
  console.log(`AxiomCore backend running at http://localhost:${PORT}`);
});
