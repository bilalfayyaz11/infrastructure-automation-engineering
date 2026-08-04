#!/usr/bin/env python3

import argparse
import json
import re
import sys
from typing import Any

import requests


API_URL = "http://127.0.0.1:8080/instances"
REQUEST_TIMEOUT = 5


def normalize_group_name(value: str) -> str:
    normalized = re.sub(r"[^A-Za-z0-9_]", "_", value.strip().lower())
    return re.sub(r"_+", "_", normalized).strip("_")


def fetch_instances() -> list[dict[str, Any]]:
    try:
        response = requests.get(API_URL, timeout=REQUEST_TIMEOUT)
        response.raise_for_status()
        data = response.json()
    except requests.RequestException as exc:
        raise RuntimeError(f"API request failed: {exc}") from exc
    except ValueError as exc:
        raise RuntimeError("API returned invalid JSON") from exc

    if not isinstance(data, list):
        raise RuntimeError("API response must be a JSON list")

    return data


def build_inventory(
    instances: list[dict[str, Any]]
) -> dict[str, Any]:
    inventory: dict[str, Any] = {
        "_meta": {
            "hostvars": {}
        },
        "all": {
            "children": []
        }
    }

    for instance in instances:
        hostname = instance.get("name")
        private_ip = instance.get("private_ip")
        tags = instance.get("tags", {})

        if not hostname or not private_ip:
            raise RuntimeError(
                "Every instance requires name and private_ip"
            )

        if not isinstance(tags, dict):
            raise RuntimeError(
                f"Tags for {hostname} must be an object"
            )

        inventory["_meta"]["hostvars"][hostname] = {
            "ansible_host": private_ip,
            "instance_name": hostname,
            "instance_tags": tags,
            "ansible_user": "ubuntu",
            "ansible_python_interpreter": "/usr/bin/python3"
        }

        for tag_key, tag_value in tags.items():
            group_name = normalize_group_name(
                f"{tag_key}_{tag_value}"
            )

            inventory.setdefault(
                group_name,
                {"hosts": []}
            )

            inventory[group_name]["hosts"].append(hostname)

    named_groups = sorted(
        group
        for group in inventory
        if group not in {"_meta", "all"}
    )

    inventory["all"]["children"] = named_groups

    for group_name in named_groups:
        inventory[group_name]["hosts"].sort()

    return inventory


def host_details(
    inventory: dict[str, Any],
    hostname: str
) -> dict[str, Any]:
    return inventory.get("_meta", {}).get(
        "hostvars", {}
    ).get(hostname, {})


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="API-backed Ansible dynamic inventory"
    )

    mode = parser.add_mutually_exclusive_group(required=True)

    mode.add_argument(
        "--list",
        action="store_true",
        help="Return the complete inventory"
    )

    mode.add_argument(
        "--host",
        metavar="HOSTNAME",
        help="Return variables for one host"
    )

    return parser.parse_args()


def main() -> int:
    args = parse_arguments()

    try:
        inventory = build_inventory(fetch_instances())
    except RuntimeError as exc:
        print(
            json.dumps(
                {"error": str(exc)}
            ),
            file=sys.stderr
        )
        return 1

    if args.list:
        output = inventory
    else:
        output = host_details(inventory, args.host)

    print(json.dumps(output, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
