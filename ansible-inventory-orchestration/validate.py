#!/usr/bin/env python3

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate one or more Ansible inventory sources"
    )

    parser.add_argument(
        "inventories",
        nargs="+",
        help="Inventory file or executable paths"
    )

    return parser.parse_args()


def load_inventory(path: str) -> dict[str, Any]:
    completed = subprocess.run(
        [
            "ansible-inventory",
            "-i",
            path,
            "--list",
        ],
        capture_output=True,
        text=True,
        check=False,
    )

    if completed.returncode != 0:
        stderr = completed.stderr.strip() or "ansible-inventory failed"
        raise RuntimeError(stderr)

    try:
        data = json.loads(completed.stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError(
            f"invalid JSON output: {exc}"
        ) from exc

    if not isinstance(data, dict):
        raise RuntimeError("inventory output is not a JSON object")

    return data


def inventory_summary(
    inventory: dict[str, Any]
) -> tuple[int, int]:
    groups = {
        group_name
        for group_name, group_data in inventory.items()
        if group_name not in {"_meta", "all"}
        and isinstance(group_data, dict)
    }

    hosts = set(
        inventory.get("_meta", {})
        .get("hostvars", {})
        .keys()
    )

    if not hosts:
        for group_name, group_data in inventory.items():
            if group_name in {"_meta", "all"}:
                continue

            if not isinstance(group_data, dict):
                continue

            hosts.update(group_data.get("hosts", []))

    return len(groups), len(hosts)


def validate_inventory(path: str) -> tuple[bool, str]:
    inventory_path = Path(path)

    if not inventory_path.exists():
        return False, "path does not exist"

    try:
        inventory = load_inventory(path)
        group_count, host_count = inventory_summary(inventory)
    except RuntimeError as exc:
        return False, str(exc)

    if group_count == 0:
        return False, "inventory contains zero groups"

    if host_count == 0:
        return False, "inventory contains zero hosts"

    return (
        True,
        f"{group_count} groups, {host_count} hosts",
    )


def main() -> int:
    args = parse_arguments()
    failures = 0

    for path in args.inventories:
        passed, message = validate_inventory(path)

        if passed:
            print(f"PASS {path}: {message}")
        else:
            print(f"FAIL {path}: {message}")
            failures += 1

    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
