import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).parent.resolve()


def setup_environment():
    print("Installing backend dependencies...")
    requirements = ROOT / "requirements.txt"
    if requirements.exists():
        subprocess.run([sys.executable, "-m", "pip", "install", "-r", str(requirements)], check=True)
    else:
        print("No requirements.txt found, skipping backend dependency install.")

    frontend_dir = ROOT / "frontend"
    if (frontend_dir / "package.json").exists():
        print("Installing frontend dependencies...")
        subprocess.run(["npm", "install"], cwd=frontend_dir, check=True)
    else:
        print("No frontend package.json found, skipping npm install.")


def launch_project():
    print("Launching backend (FastAPI on http://localhost:8000)...")
    backend_proc = subprocess.Popen([sys.executable, str(ROOT / "server.py")])
    print(f"Backend PID: {backend_proc.pid}")

    frontend_dir = ROOT / "frontend"
    if (frontend_dir / "package.json").exists():
        print("Launching frontend (Vite defaults to http://localhost:5173, may choose another open port)...")
        frontend_proc = subprocess.Popen(["npm", "run", "dev"], cwd=frontend_dir)
        print(f"Frontend PID: {frontend_proc.pid}")
    else:
        print("Frontend not initialized; skipping dev server start.")


if __name__ == "__main__":
    setup_environment()
    launch_project()
