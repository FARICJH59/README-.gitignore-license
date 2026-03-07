from pathlib import Path
import json
import os
from typing import Any, Literal, Type, TypeVar

import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, ConfigDict, Field, RootModel, ValidationError, model_validator


BASE_DIR = Path(__file__).parent
STATIC_DIR = BASE_DIR / "static"
REPORTS_DIR = BASE_DIR.parent / "reports"
USAGE_FILENAME = "USAGE_REPORT.json"
DRIFT_FILENAME = "DRIFT_REPORT.json"
JOBS_FILENAME = "JOBS_REPORT.json"
LOGS_FILENAME = "LOGS_REPORT.json"


class GPUClusters(BaseModel):
    model_config = ConfigDict(extra="ignore", populate_by_name=True)

    llm_cluster_count: int = Field(alias="LLM")
    vision_cluster_count: int = Field(alias="Vision")
    ml_cluster_count: int = Field(alias="ML")
    embedding_cluster_count: int = Field(alias="Embedding")


class Alert(BaseModel):
    """Alert entry surfaced in usage reports and dashboard notifications."""
    model_config = ConfigDict(extra="ignore")

    message: str
    level: Literal["info", "warn", "error"] = "info"


class Project(BaseModel):
    model_config = ConfigDict(extra="ignore")

    id: str | None = None
    name: str


class UsageReport(BaseModel):
    model_config = ConfigDict(extra="ignore")

    timestamp: str
    active_brain_nodes: int
    active_worker_nodes: int
    gpu_clusters: GPUClusters
    energy_consumption_mwh: float
    carbon_quota: str
    alerts: list[Alert] | None = None
    projects: list[Project] | None = None
    notes: str | None = None


class DriftControls(BaseModel):
    model_config = ConfigDict(extra="ignore")

    rbac: str | None = None
    network_policy: str | None = None


class DriftReport(BaseModel):
    model_config = ConfigDict(extra="ignore")

    timestamp: str
    drift_detected: bool
    changed_files: list[str]
    summary: str
    controls: DriftControls | None = None


class JobRow(BaseModel):
    model_config = ConfigDict(extra="ignore")

    id: str
    type: str
    status: str
    eta_sec: int


class JobsReport(BaseModel):
    model_config = ConfigDict(extra="ignore")

    timestamp: str
    queue_depth: int
    throughput_per_min: int
    pending: int
    active: int
    completed_last_hour: int
    failures_last_hour: int
    jobs: list[JobRow]


class LogEntry(BaseModel):
    model_config = ConfigDict(extra="ignore")

    timestamp: str
    level: Literal["info", "warn", "error"]
    message: str


class LogsReport(RootModel[list[LogEntry]]):
    """Wraps the logs array as the root JSON structure for validation."""

app = FastAPI(title="GPT-5 Dashboard", version="1.0.0")

# Serve built frontend assets when present
if STATIC_DIR.exists():
    assets_dir = STATIC_DIR / "assets"
    if assets_dir.exists():
        app.mount("/assets", StaticFiles(directory=assets_dir, html=False), name="assets")
    app.mount("/static", StaticFiles(directory=STATIC_DIR, html=True), name="static")


@app.get("/health", tags=["system"])
async def health() -> dict:
    return {"status": "healthy"}


@app.get("/api/ping", tags=["system"])
async def ping() -> dict:
    return {"message": "pong"}


def _load_report(filename: str) -> Any:
    report_path = REPORTS_DIR / filename
    if not report_path.exists():
        raise HTTPException(status_code=404, detail=f"Report not found: {filename}")
    try:
        with report_path.open("r", encoding="utf-8") as fp:
            return json.load(fp)
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=500, detail=f"Invalid report JSON: {filename}") from exc


def _load_report_as(model: Type[BaseModel], filename: str) -> BaseModel:
    try:
        return model.model_validate(_load_report(filename))
    except ValidationError as exc:
        raise HTTPException(status_code=500, detail=f"Report validation failed: {filename}") from exc


@app.get("/api/usage", tags=["dashboard"])
async def get_usage() -> UsageReport:
    """
    Cluster usage stats (nodes, workers, energy, GPU allocation).
    """
    return _load_report_as(UsageReport, USAGE_FILENAME)


@app.get("/api/drift", tags=["dashboard"])
async def get_drift() -> DriftReport:
    """
    Drift status and change summary.
    """
    return _load_report_as(DriftReport, DRIFT_FILENAME)


@app.get("/api/jobs", tags=["dashboard"])
async def get_jobs() -> JobsReport:
    """
    Queue depth, throughput, and job statuses.
    """
    return _load_report_as(JobsReport, JOBS_FILENAME)


@app.get("/api/logs", tags=["dashboard"])
async def get_logs() -> list[LogEntry]:
    """
    Latest system log entries.
    """
    return _load_report_as(LogsReport, LOGS_FILENAME).root


@app.get("/", include_in_schema=False)
async def serve_index():
    index_path = STATIC_DIR / "index.html"
    if index_path.exists():
        return FileResponse(index_path)
    return JSONResponse(
        {
            "status": "ok",
            "message": "Frontend build not found. Run `npm run build` in /frontend.",
        }
    )


@app.get("/{full_path:path}", include_in_schema=False)
async def spa_handler(full_path: str):
    asset_path = STATIC_DIR / full_path
    if asset_path.exists() and asset_path.is_file():
        return FileResponse(asset_path)

    index_path = STATIC_DIR / "index.html"
    if index_path.exists():
        return FileResponse(index_path)
    raise HTTPException(status_code=404, detail="Not Found")


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=int(os.getenv("PORT", "8080")),
        reload=False,
    )
