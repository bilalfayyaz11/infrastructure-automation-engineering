#!/usr/bin/env bash

set -u

echo "=== Cross-Environment Communication Validation ==="
echo

failures=0

echo "=== Data Service Connectivity ==="

if docker exec onprem-database \
  pg_isready -U admin -d onprem_db; then
  echo "PASS: PostgreSQL connectivity"
else
  echo "FAIL: PostgreSQL connectivity"
  failures=$((failures + 1))
fi

if docker exec onprem-cache redis-cli ping | grep -qx "PONG"; then
  echo "PASS: Redis connectivity"
else
  echo "FAIL: Redis connectivity"
  failures=$((failures + 1))
fi

if docker exec cloud-database \
  mysqladmin ping \
  --host=127.0.0.1 \
  --user=clouduser \
  --password=cloudpass123 \
  --silent; then
  echo "PASS: MySQL connectivity"
else
  echo "FAIL: MySQL connectivity"
  failures=$((failures + 1))
fi

echo
echo "=== Load Balancer Backend DNS ==="

for backend in \
  webservice-onprem-1 \
  webservice-cloud-1 \
  webservice-cloud-2
do
  if docker exec cloud-loadbalancer getent hosts "$backend" >/dev/null; then
    echo "PASS: ${backend} resolves inside load balancer"
  else
    echo "FAIL: ${backend} does not resolve inside load balancer"
    failures=$((failures + 1))
  fi
done

echo
echo "=== Direct Instance Access ==="

for port in 5000 5001 5002; do
  printf 'Port %s: ' "$port"

  response="$(
    curl --fail --silent --show-error \
      "http://127.0.0.1:${port}/info"
  )"

  if [ -z "$response" ]; then
    echo "FAILED"
    failures=$((failures + 1))
    continue
  fi

  printf '%s' "$response" |
    python3 -c \
      'import json,sys; d=json.load(sys.stdin); print("{} | {}".format(d["environment"], d["instance_id"]))'
done

echo
echo "=== Load Balancer Distribution ==="

declare -A observed_instances=()

for request in 1 2 3 4 5 6 7 8 9; do
  response="$(
    curl --fail --silent --show-error \
      http://127.0.0.1:8080/info
  )"

  if [ -z "$response" ]; then
    echo "Request ${request}: FAILED"
    failures=$((failures + 1))
    continue
  fi

  result="$(
    printf '%s' "$response" |
      python3 -c \
        'import json,sys; d=json.load(sys.stdin); print("{}|{}".format(d["environment"], d["instance_id"]))'
  )"

  environment="${result%%|*}"
  instance="${result#*|}"
  observed_instances["$instance"]=1

  echo "Request ${request}: ${environment} | ${instance}"
done

echo
echo "Unique backends observed: ${#observed_instances[@]}"

if [ "${#observed_instances[@]}" -lt 3 ]; then
  echo "FAIL: Load balancer did not reach all three backend instances."
  failures=$((failures + 1))
else
  echo "PASS: Load balancer reached all three backend instances."
fi

echo
echo "=== Communication Summary ==="

if [ "$failures" -eq 0 ]; then
  echo "Cross-environment communication: VERIFIED"
  exit 0
fi

echo "Cross-environment communication: FAILED (${failures} checks)"
exit 1
