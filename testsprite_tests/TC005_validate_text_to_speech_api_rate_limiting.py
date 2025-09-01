import requests

BASE_URL = "http://localhost:5000"
API_KEY = "test-api-key"  # Replace with a valid API key

def validate_text_to_speech_api_rate_limiting():
    url = f"{BASE_URL}/api/speak"
    headers = {
        "X-API-Key": API_KEY,
        "Content-Type": "application/json"
    }
    payload = {
        "text": "Hello, this is a test to check the rate limiting of the ODIADEV Edge-TTS API. " 
                "We are sending multiple requests rapidly to trigger the rate limiting mechanism."
    }

    # We will send 20 requests rapidly to exceed typical rate limits
    rate_limit_exceeded = False
    for i in range(20):
        try:
            response = requests.post(url, json=payload, headers=headers, timeout=30)
        except requests.RequestException as e:
            raise AssertionError(f"Request failed at iteration {i+1}: {e}")

        if response.status_code == 429:
            rate_limit_exceeded = True
            break
        elif response.status_code == 401:
            raise AssertionError("Authentication failed with provided API key.")
        elif response.status_code != 200:
            raise AssertionError(f"Unexpected status code {response.status_code} at iteration {i+1}.")

    assert rate_limit_exceeded, "Rate limiting was not enforced; did not receive 429 status code."

validate_text_to_speech_api_rate_limiting()