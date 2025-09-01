import requests

BASE_URL = "http://localhost:5000"
API_KEY = "test-api-key"  # Replace with valid API key if required
TIMEOUT = 30

def verify_health_check_api_response():
    url = f"{BASE_URL}/health"
    headers = {
        "X-API-Key": API_KEY
    }
    try:
        response = requests.get(url, headers=headers, timeout=TIMEOUT)
    except requests.RequestException as e:
        assert False, f"Request to {url} failed: {str(e)}"
    assert response.status_code == 200, f"Expected status code 200 but got {response.status_code}"
    try:
        json_data = response.json()
    except ValueError:
        assert False, "Response is not valid JSON"

    # Validate JSON structure and types
    assert isinstance(json_data, dict), "Response JSON is not an object"
    assert "ok" in json_data and isinstance(json_data["ok"], bool), "'ok' field missing or not boolean"
    assert "voices" in json_data and isinstance(json_data["voices"], int), "'voices' field missing or not integer"
    assert "ng_voices" in json_data and isinstance(json_data["ng_voices"], int), "'ng_voices' field missing or not integer"
    assert "hash" in json_data and isinstance(json_data["hash"], str), "'hash' field missing or not string"

verify_health_check_api_response()