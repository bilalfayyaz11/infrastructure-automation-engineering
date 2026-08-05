#!/usr/bin/env bash

set +e
set +u
set +o pipefail 2>/dev/null || true

ROOT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROLE_DIRECTORY="$ROOT_DIRECTORY/webserver"
REPORT_DIRECTORY="$ROOT_DIRECTORY/reports"
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
REPORT_FILE="$REPORT_DIRECTORY/molecule-validation-$TIMESTAMP.md"
OUTPUT_DIRECTORY="$REPORT_DIRECTORY/output-$TIMESTAMP"

mkdir -p "$OUTPUT_DIRECTORY"

DEFAULT_STATUS=NOT_RUN
UBUNTU2204_STATUS=NOT_RUN
FINAL_STATUS=PASSED

run_scenario() {
  local scenario_name="$1"
  local output_file="$2"
  local status_variable="$3"

  set +e

  (
    cd "$ROLE_DIRECTORY" || exit 1
    molecule test -s "$scenario_name"
  ) > "$output_file" 2>&1

  local scenario_status=$?

  set -e

  if [ "$scenario_status" -eq 0 ]; then
    printf -v "$status_variable" '%s' "PASSED"
  else
    printf -v "$status_variable" '%s' "FAILED"
    FINAL_STATUS=FAILED
  fi
}

set -e

run_scenario \
  default \
  "$OUTPUT_DIRECTORY/default.log" \
  DEFAULT_STATUS

run_scenario \
  ubuntu2204 \
  "$OUTPUT_DIRECTORY/ubuntu2204.log" \
  UBUNTU2204_STATUS

DEFAULT_IDEMPOTENCE=$(grep -c \
  'Idempotence completed successfully' \
  "$OUTPUT_DIRECTORY/default.log" \
  || true)

UBUNTU2204_IDEMPOTENCE=$(grep -c \
  'Idempotence completed successfully' \
  "$OUTPUT_DIRECTORY/ubuntu2204.log" \
  || true)

DEFAULT_VERIFY=$(grep -c \
  'Apache returned the expected HTTP response' \
  "$OUTPUT_DIRECTORY/default.log" \
  || true)

UBUNTU2204_VERIFY=$(grep -c \
  'Apache returned the expected HTTP response' \
  "$OUTPUT_DIRECTORY/ubuntu2204.log" \
  || true)

cat > "$REPORT_FILE" << REPORT_EOF
# Molecule Validation Report

## Execution Details

- Timestamp: $TIMESTAMP
- Ansible version: $(ansible --version | head -n1)
- Molecule version: $(molecule --version | head -n1)
- Docker version: $(docker --version)
- Host kernel: $(uname -r)
- Overall status: $FINAL_STATUS

## Scenario Results

| Scenario | Operating System | Result | Idempotence Marker | HTTP Verification Marker |
|---|---|---:|---:|---:|
| default | Ubuntu 24.04 | $DEFAULT_STATUS | $DEFAULT_IDEMPOTENCE | $DEFAULT_VERIFY |
| ubuntu2204 | Ubuntu 22.04 | $UBUNTU2204_STATUS | $UBUNTU2204_IDEMPOTENCE | $UBUNTU2204_VERIFY |

## Result

$FINAL_STATUS
REPORT_EOF

printf '%s\n' "$REPORT_FILE"

if [ "$FINAL_STATUS" != "PASSED" ]; then
  exit 1
fi
