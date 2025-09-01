import requests

def test_check_text_to_speech_api_authentication_enforcement():
    base_url = "http://localhost:5000"
    url = f"{base_url}/api/speak"
    headers = {
        "Content-Type": "application/json"
        # Intentionally no 'X-API-Key' header to test authentication enforcement
    }
    payload = {
        "text": "This is a test to verify authentication enforcement on the text to speech API."
    }

    try:
        response = requests.post(url, json=payload, headers=headers, timeout=30)
    except requests.RequestException as e:
        raise AssertionError(f"Request failed: {e}")

    assert response.status_code == 401, f"Expected status code 401, got {response.status_code}"
    # The error message might be in response body or empty
    content_type = response.headers.get("Content-Type", "")
    if "application/json" in content_type:
        try:
            resp_json = response.json()
            assert "error" in resp_json or "message" in resp_json, "Expected error or message in JSON response"
        except ValueError:
            # Response was not JSON-formatted despite header, pass as long as status 401 is received
            pass

test_check_text_to_speech_api_authentication_enforcement()