"""Deliberately small demo service — orca-poc-target. Its only job is to be a real,
buildable, testable thing that uses the vulnerable `requests` pin, so Act 3's fix has a real
CI run behind it instead of a decorative one.
"""

from __future__ import annotations

import requests

USER_AGENT = "orca-poc-target/1.0"


def build_headers(extra: dict | None = None) -> dict:
    headers = {"User-Agent": USER_AGENT}
    if extra:
        headers.update(extra)
    return headers


def fetch_json(url: str, timeout: float = 5.0) -> dict:
    response = requests.get(url, headers=build_headers(), timeout=timeout)
    response.raise_for_status()
    return response.json()


def summarize_status(url: str, timeout: float = 5.0) -> str:
    response = requests.get(url, headers=build_headers(), timeout=timeout)
    return f"{url} -> {response.status_code}"


if __name__ == "__main__":
    print(summarize_status("https://example.com"))
