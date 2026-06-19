from fastapi.testclient import TestClient
from src.main import app

client = TestClient(app)

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"

def test_process():
    r = client.post("/api/v1/process", json={"input_data": {"key": "value"}, "priority": 2})
    assert r.status_code == 200
    assert r.json()["status"] == "processed"

