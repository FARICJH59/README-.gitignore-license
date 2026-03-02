import sys
from pathlib import Path

from fastapi.testclient import TestClient

PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from backend import main


client = TestClient(main.app)


def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_ping_endpoint():
    response = client.get("/api/ping")
    assert response.status_code == 200
    assert response.json()["message"] == "pong"


def test_root_without_frontend_build_returns_hint():
    response = client.get("/")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert "Frontend build not found" in body["message"]


def test_spa_handler_missing_asset_returns_404():
    response = client.get("/non-existent-path")
    assert response.status_code == 404
    assert response.json()["detail"] == "Not Found"
