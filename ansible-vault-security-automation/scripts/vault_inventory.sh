#!/usr/bin/env bash
set -euo pipefail

VAULT_DIR="$HOME/ansible-vault-security/vault_files"
DEFAULT_PASS="$HOME/.vault_pass"
PRODUCTION_PASS="$HOME/.vault_pass_production"

echo "===== ANSIBLE VAULT INVENTORY ====="

for vault_file in "$VAULT_DIR"/*.yml; do
  [ -f "$vault_file" ] || continue

  filename="$(basename "$vault_file")"
  header="$(head -n 1 "$vault_file")"
  size="$(stat -c '%s' "$vault_file")"
  mode="$(stat -c '%a' "$vault_file")"

  if [[ "$header" == *";production" ]]; then
    password_args=(--vault-id "production@$PRODUCTION_PASS")
  else
    password_args=(--vault-password-file "$DEFAULT_PASS")
  fi

  variable_count="$(
    ansible-vault view "${password_args[@]}" "$vault_file" \
      | python3 -c '
import sys
import yaml

data = yaml.safe_load(sys.stdin) or {}
print(len(data) if isinstance(data, dict) else 0)
'
  )"

  echo "File: $filename"
  echo "Header: $header"
  echo "Mode: $mode"
  echo "Size: $size bytes"
  echo "Variables: $variable_count"
  echo
done
