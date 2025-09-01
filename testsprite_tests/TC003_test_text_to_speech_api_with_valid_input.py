import requests

BASE_URL = "http://localhost:5000"
API_KEY = "your_api_key_here"  # Replace with a valid API key for authentication
TIMEOUT = 30


def test_text_to_speech_api_with_valid_input():
    # Prepare headers with authentication
    headers = {
        "X-API-Key": API_KEY,
        "Content-Type": "application/json"
    }

    # Sample text between 20 and 120 words (approx. 85 words)
    text = (
        "This is a sample text used to test the text to speech API endpoint. "
        "The text contains enough words to validate the API's ability to process a valid input "
        "and generate an audio file accordingly. Testing with different parameters such as voice, "
        "format, rate, volume, and pitch ensures we cover functional capabilities and verify correct "
        "handling of optional inputs by the service."
    )

    # Optional parameters for TTS
    payload = {
        "text": text,
        "voice": "en-NG-EzinneNeural",
        "format": "mp3_48k",
        "rate": "+10%",
        "volume": "+5%",
        "pitch": "+2Hz"
    }

    url = f"{BASE_URL}/api/speak"

    try:
        response = requests.post(url, headers=headers, json=payload, timeout=TIMEOUT)
    except requests.RequestException as e:
        assert False, f"Request to /api/speak failed with exception: {e}"

    # Assert response status code 200
    assert response.status_code == 200, f"Expected status code 200 but got {response.status_code}"

    # Assert Content-Type header indicates audio format (mp3)
    content_type = response.headers.get("Content-Type", "")
    assert content_type in ["audio/mpeg", "audio/mp3"], f"Unexpected Content-Type: {content_type}"

    # Assert response content length is greater than 100KB
    content_length = len(response.content)
    assert content_length > 100 * 1024, f"Audio file size is less than 100KB: {content_length} bytes"


test_text_to_speech_api_with_valid_input()