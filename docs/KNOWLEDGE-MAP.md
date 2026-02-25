# Knowledge Map: AxiomCore vs. Rugged-Silo

> **Scope notice:** This repository only contains AxiomCore assets. No Rugged-Silo source, scripts, or docs are present. Rugged-Silo is referenced in CI matrices but there is nothing to scan locally, so comparisons are limited to what is declared here.

## 1) Orchestration “Brain” (AxiomCore / QGPS)
- **Brain core** (`brain-core/`): holds `repo-registry.json` (agent/repo registry), `version.json` (brain version + “MCP integration ready”), and compliance policies (`compliance/mandatory-modules.json`, `infra-policy.json`).
- **Agent registration & MCP posture:** `scripts/generate-autopilot-repo.ps1` registers a repo into `repo-registry.json`, syncs policies (via `axiom-sync.ps1`), runs compliance checks (`axiom-compliance.ps1`), and refreshes orchestrator status. All flows are branded “Brain-driven, MCP-managed,” but no external MCP API calls are implemented—enforcement is via local policy sync.
- **Multi-repo orchestration:** `axiom-orchestrator.ps1` reads the registry and runs status/sync-all/check-all; `qgps-cockpit.ps1` enforces dependency install/build/dev-server launch with concurrency control and logs to `.brain/cockpit-log.json`.
- **Monitoring:** `multi-agent-dashboard.ps1` provides live TUI monitoring with progress bars, retries, and Docker lifecycle helpers; logs to `multi-agent-log.txt`. Dashboard inputs come from `brain-knowledge.json` (sample provided).

### Orchestration Flow (text diagram)
```
generate-autopilot-repo.ps1
    -> brain-core/repo-registry.json (register)
    -> axiom-sync.ps1 (copy policies to .brain/*)
    -> axiom-compliance.ps1 (validate/auto-fix)
    -> axiom-orchestrator.ps1 status

qgps-cockpit.ps1
    -> iterate registry repos
    -> npm install/build/dev with concurrency + logging (.brain/cockpit-log.json)

CI (ci-cd-autopilot.yml)
    -> matrix checkout (axiomcore, rugged-silo, veo3)
    -> axiom-sync -> axiom-compliance -> orchestrator status
    -> upload compliance + sync artifacts
```

## 2) Frontend / Backend Bootstrap
- **Frontend scaffolding:** `bootstrap-axiomcore-frontend.ps1` builds a Next.js-style structure, health route, installs npm deps, and launches `npm run dev`.
- **Backend/API scaffolding:** `api/server.ps1` is a placeholder REST server module with init/start/stop/endpoint registration; subfolders (`ingestion`, `dashboard`, `optimization`, `billing`) are stubs.
- **AI layer:** `ai/engine.ps1` plus placeholder model folders (`energy-predictor`, `forecasting`) define load/inference/unload hooks.
- **Repository creation:** `create-repo.sh`/`.ps1` scaffold a new AxiomCore repo with GitHub CLI; `create-qgps-starter.ps1` bootstraps a full QGPS workspace (brain core + scripts).

## 3) Containerization, Deployment, Cloud
- **Cloud Build** (`infra/cloudbuild.yaml`): builds/pushes Docker images for API and frontend to Artifact Registry.
- **Artifact registry setup** (`infra/artifact_registry_setup.ps1`) and Terraform placeholder (`infra/terraform/.gitkeep`).
- **Deployment script** (`scripts/deploy-axiomcore-fullstack.ps1`): provider-pluggable (`aws.ps1`, `azure.ps1`, `gcp.ps1`), runs DAG/state/UDO scaffolding, then deploys API services, frontend, AI models, and optional Terraform apply/plan. Persists `last-deployment.json`.
- **Dashboard Docker helpers:** `multi-agent-dashboard.ps1` builds/runs frontend+API containers per project with port mappings and cleanup.

## 4) Synthetic Monitoring / Analytics / Quotas
- **Runtime monitoring:** multi-agent dashboard (TUI) with retries and live stats; qgps-cockpit logs lifecycle/events.
- **Metrics/analytics/quotas/energy tracking:** not implemented—no quota enforcement, energy accounting, or analytics pipeline exists in code; placeholders only (e.g., energy predictor folders).

## 5) CI/CD & Automation
- **Full-stack deploy workflow** (`.github/workflows/main.yml`): Windows runner installs Node/Python/Docker and runs `deploy-axiomcore-fullstack.ps1`.
- **Autopilot workflow** (`.github/workflows/ci-cd-autopilot.yml`): matrix for `axiomcore`, `rugged-silo`, `veo3`; performs brain sync, compliance, orchestrator status, and uploads compliance/sync artifacts.
- **Auto-repo creation:** `create-repo.ps1/.sh` and `project.yaml` metadata; QGPS starter script for turnkey environments.

## 6) Rugged-Silo Coverage (current repo)
- No Rugged-Silo code, brain entries, or scripts exist here. Only mention is in the CI matrix; therefore:
  - **Workflow behavior:** CI would try to check out a `rugged-silo` path and run the same Brain sync/compliance steps.
  - **Unknowns:** No orchestration, deployment, or monitoring specifics are available for Rugged-Silo in this repository.

## 7) Similarities & Differences
- **Similar (intended):** CI/autopilot pipeline treats AxiomCore and Rugged-Silo uniformly (sync → compliance → status). Both presumed to be MCP-managed, brain-registered repos.
- **Differences (observable):** Only AxiomCore assets exist (scripts, policies, dashboard, deployment, cloud build). Rugged-Silo implementation details are absent; any comparison beyond CI intent cannot be derived from this codebase.
