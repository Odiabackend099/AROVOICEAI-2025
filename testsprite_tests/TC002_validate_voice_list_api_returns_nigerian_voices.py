import requests

API_KEY = "your_api_key_here"
BASE_URL = "http://localhost:5000"
TIMEOUT = 30

def test_validate_voice_list_api_returns_nigerian_voices():
    url = f"{BASE_URL}/voices"
    headers = {
        "X-API-Key": API_KEY
    }
    try:
        response = requests.get(url, headers=headers, timeout=TIMEOUT)
    except requests.RequestException as e:
        assert False, f"Request to /voices failed: {e}"

    assert response.status_code == 200, f"Expected status code 200, got {response.status_code}"

    try:
        data = response.json()
    except ValueError:
        assert False, "Response is not valid JSON"

    assert isinstance(data, dict), "Response JSON should be an object"
    assert data.get("ok") is True, "'ok' field should be True"
    voices = data.get("voices")
    assert isinstance(voices, list), "'voices' should be a list"
    assert len(voices) > 0, "Voices list should contain at least one voice"

    # At least one voice should have ShortName and Locale properties
    voice_with_props = False
    for voice in voices:
        if isinstance(voice, dict) and "ShortName" in voice and "Locale" in voice:
            if isinstance(voice["ShortName"], str) and isinstance(voice["Locale"], str):
                voice_with_props = True
                break

    assert voice_with_props, "No voice in the list has both 'ShortName' and 'Locale' string properties"

test_validate_voice_list_api_returns_nigerian_voices()