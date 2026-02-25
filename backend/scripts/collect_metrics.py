"""
Collects lightweight operational metrics for Cloud Run projects.

Outputs backend/scripts/metrics.json with:
- usage, quota, and synthetic energy/carbon estimates
- placeholder revenue integration via Google Cloud Billing API
"""

from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional

from google.oauth2 import service_account
from googleapiclient import discovery


DEPLOY_REGION = os.getenv("DEPLOY_REGION", "us-central1")
OUTPUT_PATH = Path(__file__).parent / "metrics.json"
SCOPES = ["https://www.googleapis.com/auth/cloud-platform"]


def parse_projects(raw: str | None) -> List[str]:
    if not raw:
        return []
    return [p.strip() for p in raw.split(",") if p.strip()]


def build_billing_client() -> Optional[discovery.Resource]:
    """Create a Cloud Billing client from the injected service account key."""
    key = os.getenv("GCP_SA_KEY")
    if not key:
        return None

    info = json.loads(key)
    creds = service_account.Credentials.from_service_account_info(info, scopes=SCOPES)
    return discovery.build("cloudbilling", "v1", credentials=creds, cache_discovery=False)


def fetch_revenue(client: Optional[discovery.Resource], project_id: str) -> Dict:
    """
    Placeholder revenue fetch using Cloud Billing API.

    Swap this stub for a concrete call when a billing account is available.
    """
    if not client:
        return {"estimated_revenue_usd": None, "note": "No billing client configured"}

    try:
        # Example placeholder call; replace with SKU-level aggregation as needed.
        accounts = client.billingAccounts().list(pageSize=1).execute()
        account_name = accounts.get("billingAccounts", [{}])[0].get("name")
        return {
            "estimated_revenue_usd": 0.0,
            "billing_account": account_name,
            "note": "Replace stub with project-level spend query",
        }
    except Exception as exc:  # pragma: no cover - depends on live API
        return {"estimated_revenue_usd": None, "error": str(exc)}


def estimate_energy(request_count: int) -> Dict[str, float]:
    # Simple synthetic factors to keep the pipeline deterministic.
    kwh = round(request_count * 0.0002, 4)
    carbon_kg = round(kwh * 0.0004, 6)
    return {"energy_kwh": kwh, "carbon_kg": carbon_kg}


def collect_for_project(client: Optional[discovery.Resource], project_id: str) -> Dict:
    usage = {
        "requests": 0,
        "avg_latency_ms": 0,
        "region": DEPLOY_REGION,
    }

    quota = {
        "cpu_allocated": "shared",
        "memory_mb": 512,
        "concurrency": 80,
    }

    energy = estimate_energy(usage["requests"])
    revenue = fetch_revenue(client, project_id)

    return {
        "project_id": project_id,
        "usage": usage,
        "quota": quota,
        "energy": energy,
        "revenue": revenue,
    }


def main() -> int:
    projects = parse_projects(os.getenv("CLOUD_RUN_PROJECTS"))
    if not projects:
        print("No projects configured for metrics collection.")
        OUTPUT_PATH.write_text(json.dumps({"projects": [], "generated_at": datetime.now(timezone.utc).isoformat()}))
        return 0

    billing_client = build_billing_client()

    metrics: Dict[str, object] = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "projects": [],
        "totals": {"requests": 0, "estimated_revenue_usd": 0.0, "energy_kwh": 0.0, "carbon_kg": 0.0},
    }

    for project in projects:
        project_metrics = collect_for_project(billing_client, project)
        metrics["projects"].append(project_metrics)

        metrics["totals"]["requests"] += project_metrics["usage"]["requests"]
        revenue_val = project_metrics["revenue"].get("estimated_revenue_usd") or 0.0
        metrics["totals"]["estimated_revenue_usd"] += revenue_val
        metrics["totals"]["energy_kwh"] += project_metrics["energy"]["energy_kwh"]
        metrics["totals"]["carbon_kg"] += project_metrics["energy"]["carbon_kg"]

    OUTPUT_PATH.write_text(json.dumps(metrics, indent=2))
    print(f"Wrote metrics to {OUTPUT_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
