import requests

BASE_URL = "http://localhost:5000"
TIMEOUT = 30

def validate_root_api_information_response():
    try:
        response = requests.get(f"{BASE_URL}/", timeout=TIMEOUT)
        assert response.status_code == 200, f"Expected status code 200, got {response.status_code}"
        data = response.json()
        assert isinstance(data, dict), "Response is not a JSON object"
        # Check required keys and their types
        assert "ok" in data and isinstance(data["ok"], bool), "'ok' key missing or not a boolean"
        assert "message" in data and isinstance(data["message"], str), "'message' key missing or not a string"
        assert "docs" in data and isinstance(data["docs"], str), "'docs' key missing or not a string"
        assert "health" in data and isinstance(data["health"], str), "'health' key missing or not a string"
    except requests.exceptions.RequestException as e:
        assert False, f"Request to root API failed: {e}"

validate_root_api_information_response()