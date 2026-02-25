"""
Simple Cloud Run health and synthetic monitoring.

- Reads project list from CLOUD_RUN_PROJECTS (comma separated).
- Builds service URLs from CLOUD_RUN_SERVICE_URL_TEMPLATE or a sane default.
- Fails with non-zero exit code when any service returns an unhealthy status.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import time
from pathlib import Path
from typing import Dict, List, Tuple

import requests


DEPLOY_REGION = os.getenv("DEPLOY_REGION", "us-central1")
SERVICE_NAME = os.getenv("CLOUD_RUN_SERVICE", "gpt5-dashboard")
TEMPLATE = os.getenv(
    "CLOUD_RUN_SERVICE_URL_TEMPLATE",
    # Default pattern; adjust if your Cloud Run domain differs.
    "https://{service}-{region}-{project}.run.app",
)
METRICS_PATH = Path(__file__).parent / "monitor_results.json"


def parse_projects(raw: str | None) -> List[str]:
    if not raw:
        return []
    return [p.strip() for p in raw.split(",") if p.strip()]


def build_url(project: str) -> str:
    override = os.getenv("CLOUD_RUN_BASE_URL")
    if override:
        return override.rstrip("/")

    # Prefer discovering the live URL directly from Cloud Run to avoid drift.
    try:
        url = (
            subprocess.run(
                [
                    "gcloud",
                    "run",
                    "services",
                    "describe",
                    SERVICE_NAME,
                    "--project",
                    project,
                    "--region",
                    DEPLOY_REGION,
                    "--format=value(status.url)",
                ],
                check=True,
                capture_output=True,
                text=True,
            )
            .stdout.strip()
        )
        if url:
            return url.rstrip("/")
    except Exception:
        # Fallback to template when gcloud is unavailable (local runs, etc.).
        pass  # pragma: no cover

    return TEMPLATE.format(service=SERVICE_NAME, region=DEPLOY_REGION, project=project).rstrip(
        "/"
    )


def check_health(base_url: str) -> Tuple[bool, Dict]:
    """Ping the /health endpoint to verify liveness."""
    try:
        resp = requests.get(f"{base_url}/health", timeout=10)
        body: Dict | str
        if resp.headers.get("content-type", "").startswith("application/json"):
            try:
                body = resp.json()
            except Exception:  # pragma: no cover - defensive fallback
                body = resp.text
        else:
            body = resp.text

        return resp.status_code == 200, {
            "status_code": resp.status_code,
            "body": body,
        }
    except Exception as exc:  # pragma: no cover - best-effort monitoring
        return False, {"error": str(exc)}


def synthetic_probe(base_url: str) -> Dict:
    """Measure simple latency against the root endpoint."""
    start = time.perf_counter()
    try:
        resp = requests.get(base_url, timeout=15)
        latency_ms = (time.perf_counter() - start) * 1000
        return {
            "latency_ms": round(latency_ms, 2),
            "status_code": resp.status_code,
            "ok": resp.ok,
        }
    except Exception as exc:  # pragma: no cover - best-effort monitoring
        return {"latency_ms": None, "status_code": None, "ok": False, "error": str(exc)}


def main() -> int:
    projects = parse_projects(os.getenv("CLOUD_RUN_PROJECTS"))
    if not projects:
        print("No projects configured; set CLOUD_RUN_PROJECTS to enable monitoring.")
        return 0

    summary: Dict[str, Dict] = {}
    unhealthy: List[str] = []

    for project in projects:
        base_url = build_url(project)
        healthy, health_payload = check_health(base_url)
        synthetic = synthetic_probe(base_url)

        summary[project] = {
            "base_url": base_url,
            "health": health_payload,
            "synthetic": synthetic,
        }

        if not healthy or not synthetic.get("ok"):
            unhealthy.append(project)

    METRICS_PATH.write_text(json.dumps(summary, indent=2))
    print(f"Wrote monitor results to {METRICS_PATH}")

    if unhealthy:
        print(f"Unhealthy services detected: {', '.join(unhealthy)}")
        return 1

    print("All services reported healthy.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
