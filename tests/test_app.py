import pytest
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'app'))
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_home_returns_200(client):
    assert client.get('/').status_code == 200

def test_home_returns_json(client):
    data = client.get('/').get_json()
    assert data['status'] == 'ok'

def test_health_endpoint(client):
    r = client.get('/health')
    assert r.status_code == 200
    assert r.get_json()['status'] == 'healthy'

def test_ready_endpoint(client):
    r = client.get('/ready')
    assert r.status_code == 200
    assert r.get_json()['status'] == 'ready'
