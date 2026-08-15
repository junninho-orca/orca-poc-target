"""Real tests for the demo app — no live network calls (requests.get is mocked throughout)."""

from __future__ import annotations

from unittest.mock import MagicMock, patch

import pytest
import requests

from app import USER_AGENT, build_headers, fetch_json, summarize_status


def _mock_response(status_code=200, json_data=None, raise_error=None):
    response = MagicMock(spec=requests.Response)
    response.status_code = status_code
    response.json.return_value = json_data or {}
    if raise_error:
        response.raise_for_status.side_effect = raise_error
    else:
        response.raise_for_status.return_value = None
    return response


def test_build_headers_includes_user_agent():
    headers = build_headers()
    assert headers["User-Agent"] == USER_AGENT


def test_build_headers_merges_extra_headers():
    headers = build_headers({"Accept": "application/json"})
    assert headers["User-Agent"] == USER_AGENT
    assert headers["Accept"] == "application/json"


@patch("app.requests.get")
def test_fetch_json_returns_parsed_json(mock_get):
    mock_get.return_value = _mock_response(json_data={"ok": True})
    result = fetch_json("https://example.com/api")
    assert result == {"ok": True}
    mock_get.assert_called_once()


@patch("app.requests.get")
def test_fetch_json_raises_on_http_error(mock_get):
    mock_get.return_value = _mock_response(
        status_code=500, raise_error=requests.HTTPError("server error")
    )
    with pytest.raises(requests.HTTPError):
        fetch_json("https://example.com/api")


@patch("app.requests.get")
def test_fetch_json_passes_timeout_through(mock_get):
    mock_get.return_value = _mock_response(json_data={})
    fetch_json("https://example.com/api", timeout=1.5)
    _, kwargs = mock_get.call_args
    assert kwargs["timeout"] == 1.5


@patch("app.requests.get")
def test_summarize_status_formats_url_and_code(mock_get):
    mock_get.return_value = _mock_response(status_code=201)
    result = summarize_status("https://example.com/health")
    assert result == "https://example.com/health -> 201"


def test_requests_stays_within_the_2x_line_this_app_was_validated_against():
    """This is the test that must fail on an *incorrect* upgrade (§6): it passes both on the
    vulnerable baseline (2.25.0) and after the correct fix (2.31.0), because both are on the
    validated 2.x line, but it fails if an automated bump ever lands outside that line —
    e.g. a typo'd version or a hypothetical breaking 3.x release — so "tests pass" carries
    real information about this specific dependency instead of being decoration.
    """
    major, minor = (int(p) for p in requests.__version__.split(".")[:2])
    assert (major, minor) >= (2, 20), f"requests {requests.__version__} predates this app's baseline"
    assert major < 3, f"requests {requests.__version__} is outside the validated 2.x line"
