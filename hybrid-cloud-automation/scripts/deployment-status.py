#!/usr/bin/env python3

from __future__ import annotations

import sys
from datetime import datetime, timezone
from typing import Any

import requests


JSON_SERVICES = [
    ("On-premises web service", "http://127.0.0.1:5000/health"),
    ("Cloud web service 1", "http://127.0.0.1:5001/health"),
    ("Cloud web service 2", "http://127.0.0.1:5002/health"),
    ("Load-balanced web service", "http://127.0.0.1:8080/info"),
]

TEXT_SERVICES = [
    ("NGINX load balancer", "http://127.0.0.1:8080/load-balancer-health"),
    ("Prometheus", "http://127.0.0.1:9090/-/healthy"),
]


def check_json_service(name: str, url: str) -> bool:
    try:
        response = requests.get(url, timeout=5)
        response.raise_for_status()
        data: dict[str, Any] = response.json()

        environment = data.get("environment", "unknown")
        instance = data.get("instance_id", "unknown")
        status = data.get("status", "available")

        print(
            f"PASS: {name} | status={status} "
            f"| environment={environment} | instance={instance}"
        )
        return True

    except (requests.RequestException, ValueError) as exc:
        print(f"FAIL: {name} | {exc}")
        return False


def check_text_service(name: str, url: str) -> bool:
    try:
        response = requests.get(url, timeout=5)
        response.raise_for_status()

        content = response.text.strip() or "HTTP 200"
        print(f"PASS: {name} | response={content}")
        return True

    except requests.RequestException as exc:
        print(f"FAIL: {name} | {exc}")
        return False


def main() -> int:
    print("=== Hybrid Environment Deployment Status ===")
    print(f"Check time: {datetime.now(timezone.utc).isoformat()}")
    print()

    results = [
        check_json_service(name, url)
        for name, url in JSON_SERVICES
    ]

    results.extend(
        check_text_service(name, url)
        for name, url in TEXT_SERVICES
    )

    healthy = sum(results)
    total = len(results)

    print()
    print(f"Overall status: {healthy}/{total} endpoints healthy")

    if healthy == total:
        print("Deployment status: HEALTHY")
        return 0

    print("Deployment status: DEGRADED")
    return 1


if __name__ == "__main__":
    sys.exit(main())
