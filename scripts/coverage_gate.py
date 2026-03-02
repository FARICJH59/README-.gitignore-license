"""Lightweight coverage gate to enforce repository thresholds."""

from __future__ import annotations

import argparse
import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate coverage threshold.")
    parser.add_argument(
        "--coverage-file",
        required=True,
        help="Path to coverage report (XML or coverage-summary JSON).",
    )
    parser.add_argument(
        "--threshold",
        type=float,
        default=80.0,
        help="Minimum total coverage percentage required.",
    )
    parser.add_argument(
        "--require-data",
        action="store_true",
        help="Fail if the coverage file is missing.",
    )
    return parser.parse_args()


def load_coverage(path: Path) -> float | None:
    if not path.exists():
        return None

    if path.suffix.lower() == ".xml":
        tree = ET.parse(path)
        root = tree.getroot()
        line_rate = root.attrib.get("line-rate")
        if line_rate is not None:
            return float(line_rate) * 100
        lines_covered = root.attrib.get("lines-covered")
        lines_valid = root.attrib.get("lines-valid")
        if lines_covered and lines_valid:
            return (float(lines_covered) / float(lines_valid)) * 100
        raise ValueError("Unable to read line-rate from coverage XML.")

    data = json.loads(path.read_text())
    totals = data.get("total") or data.get("coverage", {}).get("total")
    if not totals:
        raise ValueError("Coverage JSON missing totals section.")
    statements = totals.get("statements") or totals.get("lines")
    covered = totals.get("covered") or totals.get("coveredStatements")
    if statements and covered is not None:
        return (float(covered) / float(statements)) * 100
    percent = totals.get("pct") or totals.get("percent")
    if percent is not None:
        return float(percent)
    raise ValueError("Unable to derive percentage from coverage JSON.")


def main() -> int:
    args = parse_args()
    coverage_path = Path(args.coverage_file)
    percentage = load_coverage(coverage_path)

    if percentage is None:
        message = f"Coverage file not found at {coverage_path}."
        if args.require-data:
            print(f"❌ {message}")
            return 1
        print(f"⚠️  {message} Skipping threshold enforcement.")
        return 0

    if percentage < args.threshold:
        print(f"❌ Coverage {percentage:.2f}% is below required {args.threshold:.2f}%")
        return 1

    print(f"✅ Coverage {percentage:.2f}% meets threshold {args.threshold:.2f}%")
    return 0


if __name__ == "__main__":
    sys.exit(main())
