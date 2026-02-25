#!/usr/bin/env python3
"""
Test runner script with support for dry-run mode.

Usage:
    python run_tests.py              # Run all tests
    python run_tests.py --dry-run    # Show what tests would be run (dry mode)
    python run_tests.py -m unit      # Run only unit tests
    python run_tests.py --collect    # Collect tests without running them
"""

import sys
import argparse
import subprocess


def main():
    parser = argparse.ArgumentParser(
        description="Test runner for AxiomCore with dry-run support"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what tests would be run without executing them (dry mode)",
    )
    parser.add_argument(
        "--collect",
        action="store_true",
        help="Collect tests without running them",
    )
    parser.add_argument(
        "-m",
        "--marker",
        type=str,
        help="Run tests matching the given marker expression (e.g., 'unit', 'integration')",
    )
    parser.add_argument(
        "--cov",
        action="store_true",
        help="Run tests with coverage report",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Increase verbosity",
    )
    parser.add_argument(
        "pytest_args",
        nargs="*",
        help="Additional arguments to pass to pytest",
    )

    args = parser.parse_args()

    # Build pytest command
    cmd = ["pytest"]

    if args.dry_run or args.collect:
        # Dry run mode - collect tests only without executing them
        cmd.append("--collect-only")
        print("🔍 DRY RUN MODE: Collecting tests without execution\n")

    if args.marker:
        cmd.extend(["-m", args.marker])

    if args.cov:
        cmd.extend(["--cov=.", "--cov-report=term-missing"])

    if args.verbose:
        cmd.append("-vv")

    # Add any additional pytest arguments
    cmd.extend(args.pytest_args)

    print(f"Running command: {' '.join(cmd)}\n")

    try:
        result = subprocess.run(cmd, check=False)
        
        if args.dry_run or args.collect:
            print("\n✅ Dry run completed - tests collected successfully!")
            print("To run these tests, execute without --dry-run or --collect flag")
        
        return result.returncode
    except FileNotFoundError:
        print("Error: pytest not found. Please install dependencies:")
        print("  pip install -r requirements.txt")
        return 1
    except Exception as e:
        print(f"Error running tests: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
