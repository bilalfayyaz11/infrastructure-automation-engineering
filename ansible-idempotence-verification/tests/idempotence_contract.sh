#!/usr/bin/env bash
set -euo pipefail

assert_file_line_count() {
  local file="$1"
  local expected_max="$2"
  local actual

  if [ ! -f "$file" ]; then
    echo "FAIL: required file does not exist: $file"
    exit 1
  fi

  actual="$(wc -l < "$file")"

  [ "$actual" -le "$expected_max" ] || {
    echo "FAIL: $file has $actual lines, expected <= $expected_max"
    exit 1
  }

  echo "PASS: $file line count ($actual) within limit"
}

assert_dir_count() {
  local pattern="$1"
  local expected_max="$2"
  local actual

  actual="$(
    find /tmp \
      -maxdepth 1 \
      -name "$pattern" \
      -type d \
      2>/dev/null \
      | wc -l
  )"

  [ "$actual" -le "$expected_max" ] || {
    echo "FAIL: found $actual directories matching $pattern, expected <= $expected_max"
    exit 1
  }

  echo "PASS: directory count for $pattern ($actual) within limit"
}

assert_key_unique() {
  local file="$1"
  local key="$2"
  local count

  if [ ! -f "$file" ]; then
    echo "FAIL: required file does not exist: $file"
    exit 1
  fi

  count="$(
    grep -c "^${key}=" "$file" 2>/dev/null || true
  )"

  [ "$count" -le 1 ] || {
    echo "FAIL: key $key appears $count times in $file"
    exit 1
  }

  echo "PASS: key $key appears at most once in $file"
}

assert_file_line_count \
  /tmp/ansible-idempotent-demo/execution-history.log \
  1

assert_dir_count \
  idempotent-runtime \
  1

assert_key_unique \
  /tmp/ansible-idempotent-demo/application.conf \
  application_mode

echo "PASS: declarative filesystem contract is satisfied."
