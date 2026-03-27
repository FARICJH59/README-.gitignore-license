"""Generate a lightweight AI/ML workflow report for monitoring."""

from __future__ import annotations

import argparse
import datetime as dt
import json
from pathlib import Path
from typing import List, Dict, Any


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Summarize AI/ML workflows.")
    parser.add_argument(
        "--ai-dir",
        default="ai",
        help="Path to the AI modules directory.",
    )
    parser.add_argument(
        "--output",
        default="ai-workflow-report.md",
        help="Path to write the markdown report.",
    )
    parser.add_argument(
        "--as-json",
        action="store_true",
        help="Emit report as JSON instead of markdown.",
    )
    return parser.parse_args()


def collect_ai_modules(ai_dir: Path) -> List[Dict[str, Any]]:
    modules: List[Dict[str, Any]] = []
    for path in ai_dir.glob("**/*.py"):
        rel = path.relative_to(ai_dir)
        stats = path.stat()
        modules.append(
            {
                "module": str(rel),
                "size_bytes": stats.st_size,
                "updated": dt.datetime.fromtimestamp(stats.st_mtime, tz=dt.timezone.utc)
                .isoformat()
                .replace("+00:00", "Z"),
            }
        )
    return sorted(modules, key=lambda item: item["module"])


def build_report(ai_dir: Path) -> Dict[str, Any]:
    ai_dir.mkdir(exist_ok=True)
    modules = collect_ai_modules(ai_dir)
    last_updated = (
        max((m["updated"] for m in modules), default=dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z"))
    )
    return {
        "ai_dir": str(ai_dir),
        "module_count": len(modules),
        "modules": modules,
        "last_updated": last_updated,
        "generated_at": dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z"),
        "recommendations": [
            "Add unit tests per model/pipeline with >=80% coverage.",
            "Track dataset versions and document provenance.",
            "Enable CI alerts for stale models or missing evaluations.",
        ],
    }


def render_markdown(report: Dict[str, Any]) -> str:
    lines = [
        "# AI/ML Workflow Report",
        f"- Generated: {report['generated_at']}",
        f"- AI Directory: {report['ai_dir']}",
        f"- Modules Discovered: {report['module_count']}",
        f"- Last Updated: {report['last_updated']}",
        "",
        "## Modules",
    ]
    if not report["modules"]:
        lines.append("_No AI modules detected; add pipelines under `ai/`._")
    else:
        for module in report["modules"]:
            lines.append(
                f"- `{module['module']}` — {module['size_bytes']} bytes (updated {module['updated']})"
            )
    lines.extend(
        [
            "",
            "## Recommendations",
            *(f"- {rec}" for rec in report["recommendations"]),
        ]
    )
    return "\n".join(lines) + "\n"


def main() -> int:
    args = parse_args()
    ai_dir = Path(args.ai_dir)
    report = build_report(ai_dir)

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    if args.as_json:
        output_path.write_text(json.dumps(report, indent=2))
    else:
        output_path.write_text(render_markdown(report))

    print(f"Wrote AI workflow report to {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
