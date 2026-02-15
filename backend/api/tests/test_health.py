def test_health_returns_build_metadata(client):
    response = client.get("/v1/health")

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert body["service"] == "offload-backend-api"
    assert body["version"] == "test-build"
    assert body["environment"] == "development"
