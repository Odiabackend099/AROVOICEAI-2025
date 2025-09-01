import requests

BASE_URL = "http://localhost:5000"
TIMEOUT = 30

def verify_web_documentation_interface_loads_successfully():
    url = f"{BASE_URL}/docs"
    try:
        response = requests.get(url, timeout=TIMEOUT)
        assert response.status_code == 200, f"Expected status 200, got {response.status_code}"
        content_type = response.headers.get("Content-Type", "")
        assert "text/html" in content_type, f"Expected 'text/html' in Content-Type, got {content_type}"
        html_content = response.text
        assert "<html" in html_content.lower() and "</html>" in html_content.lower(), "Response does not contain valid HTML content"
    except requests.RequestException as e:
        assert False, f"Request to {url} failed: {e}"

verify_web_documentation_interface_loads_successfully()