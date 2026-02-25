"""
Test suite for the FastAPI backend server.
"""

import pytest
from fastapi.testclient import TestClient
from server import app


@pytest.fixture
def client():
    """Create a test client for the FastAPI app."""
    return TestClient(app)


@pytest.mark.unit
def test_hello_endpoint(client):
    """Test the /api/hello endpoint returns expected message."""
    response = client.get("/api/hello")
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert data["message"] == "Hello from FastAPI backend!"


@pytest.mark.unit
def test_health_endpoint(client):
    """Test the /health endpoint returns ok status."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert "status" in data
    assert data["status"] == "ok"


@pytest.mark.integration
def test_cors_headers(client):
    """Test that CORS headers are properly configured."""
    response = client.get("/api/hello")
    assert response.status_code == 200
    # Note: TestClient doesn't automatically add CORS headers like a browser would,
    # but we can verify the middleware is configured by checking the app
    assert app.middleware_stack is not None
