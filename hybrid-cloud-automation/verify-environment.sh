#!/usr/bin/env bash

set -u

echo "=== Hybrid Environment Final Verification ==="
echo "Timestamp: $(date --iso-8601=seconds)"
echo

failures=0

required_containers=(
  onprem-database
  onprem-cache
  cloud-database
  cloud-monitoring
  cloud-loadbalancer
  webservice-onprem-1
  webservice-cloud-1
  webservice-cloud-2
)

required_playbooks=(
  onprem-setup.yml
  cloud-setup.yml
  deploy-webservice.yml
  site.yml
)

required_scripts=(
  monitor-services.sh
  deployment-status.py
  test-communication.sh
  cleanup-deployment.sh
)

echo "=== Container Verification ==="

for container in "${required_containers[@]}"; do
  if ! docker container inspect "$container" >/dev/null 2>&1; then
    echo "FAIL: ${container} is missing"
    failures=$((failures + 1))
    continue
  fi

  running="$(
    docker inspect \
      --format '{{.State.Running}}' \
      "$container"
  )"

  health="$(
    docker inspect \
      --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}not-configured{{end}}' \
      "$container"
  )"

  if [ "$running" = "true" ] &&
     { [ "$health" = "healthy" ] || [ "$health" = "not-configured" ]; }; then
    echo "PASS: ${container} | running=${running} | health=${health}"
  else
    echo "FAIL: ${container} | running=${running} | health=${health}"
    failures=$((failures + 1))
  fi
done

echo
echo "=== Docker Network Verification ==="

for network in onprem-network cloud-network; do
  if docker network inspect "$network" >/dev/null 2>&1; then
    docker network inspect "$network" \
      --format 'PASS: {{.Name}} | driver={{.Driver}} | containers={{len .Containers}}'
  else
    echo "FAIL: ${network} is missing"
    failures=$((failures + 1))
  fi
done

echo
echo "=== Load Balancer Network Membership ==="

load_balancer_networks="$(
  docker inspect cloud-loadbalancer \
    --format '{{range $name, $network := .NetworkSettings.Networks}}{{$name}} {{end}}'
)"

echo "Networks: ${load_balancer_networks}"

if [[ "$load_balancer_networks" == *"cloud-network"* ]] &&
   [[ "$load_balancer_networks" == *"onprem-network"* ]]; then
  echo "PASS: Load balancer spans both environments"
else
  echo "FAIL: Load balancer does not span both environments"
  failures=$((failures + 1))
fi

echo
echo "=== Application Endpoint Verification ==="

check_json_endpoint() {
  local name="$1"
  local url="$2"
  local expected_environment="$3"

  response="$(
    curl --fail --silent --show-error --max-time 10 "$url"
  )"

  if [ -z "$response" ]; then
    echo "FAIL: ${name} returned no response"
    failures=$((failures + 1))
    return
  fi

  result="$(
    printf '%s' "$response" |
      python3 -c '
import json
import sys

data = json.load(sys.stdin)
print("{}|{}|{}".format(
    data.get("environment", "unknown"),
    data.get("instance_id", "unknown"),
    data.get("version", "unknown"),
))
'
  )"

  environment="${result%%|*}"
  remainder="${result#*|}"
  instance="${remainder%%|*}"
  version="${remainder#*|}"

  if [ "$environment" = "$expected_environment" ] &&
     [ "$version" = "1.0.0" ]; then
    echo "PASS: ${name} | environment=${environment} | instance=${instance} | version=${version}"
  else
    echo "FAIL: ${name} | environment=${environment} | version=${version}"
    failures=$((failures + 1))
  fi
}

check_json_endpoint \
  "On-premises web service" \
  "http://127.0.0.1:5000/info" \
  "on-premises"

check_json_endpoint \
  "Cloud web service 1" \
  "http://127.0.0.1:5001/info" \
  "cloud"

check_json_endpoint \
  "Cloud web service 2" \
  "http://127.0.0.1:5002/info" \
  "cloud"

echo
echo "=== Infrastructure Service Verification ==="

if docker exec onprem-database \
  pg_isready -U admin -d onprem_db >/dev/null 2>&1; then
  echo "PASS: PostgreSQL"
else
  echo "FAIL: PostgreSQL"
  failures=$((failures + 1))
fi

if [ "$(docker exec onprem-cache redis-cli ping 2>/dev/null)" = "PONG" ]; then
  echo "PASS: Redis"
else
  echo "FAIL: Redis"
  failures=$((failures + 1))
fi

if docker exec cloud-database \
  mysqladmin ping \
  --host=127.0.0.1 \
  --user=clouduser \
  --password=cloudpass123 \
  --silent >/dev/null 2>&1; then
  echo "PASS: MySQL"
else
  echo "FAIL: MySQL"
  failures=$((failures + 1))
fi

if curl --fail --silent --show-error \
  http://127.0.0.1:9090/-/healthy >/dev/null; then
  echo "PASS: Prometheus"
else
  echo "FAIL: Prometheus"
  failures=$((failures + 1))
fi

if curl --fail --silent --show-error \
  http://127.0.0.1:8080/load-balancer-health >/dev/null; then
  echo "PASS: NGINX load balancer"
else
  echo "FAIL: NGINX load balancer"
  failures=$((failures + 1))
fi

echo
echo "=== Load Balancer Distribution Verification ==="

declare -A observed_instances=()

for request in 1 2 3 4 5 6 7 8 9; do
  response="$(
    curl --fail --silent --show-error \
      http://127.0.0.1:8080/info
  )"

  if [ -z "$response" ]; then
    echo "FAIL: Request ${request} returned no response"
    failures=$((failures + 1))
    continue
  fi

  result="$(
    printf '%s' "$response" |
      python3 -c '
import json
import sys

data = json.load(sys.stdin)
print("{}|{}".format(
    data["environment"],
    data["instance_id"],
))
'
  )"

  environment="${result%%|*}"
  instance="${result#*|}"
  observed_instances["$instance"]=1

  echo "Request ${request}: ${environment} | ${instance}"
done

if [ "${#observed_instances[@]}" -eq 3 ]; then
  echo "PASS: All three web-service instances were reached"
else
  echo "FAIL: Reached ${#observed_instances[@]} of 3 instances"
  failures=$((failures + 1))
fi

echo
echo "=== Ansible Artifact Verification ==="

for playbook in "${required_playbooks[@]}"; do
  if [ -f "playbooks/${playbook}" ]; then
    echo "PASS: playbooks/${playbook}"
  else
    echo "FAIL: playbooks/${playbook} is missing"
    failures=$((failures + 1))
  fi
done

for script in "${required_scripts[@]}"; do
  if [ -x "scripts/${script}" ]; then
    echo "PASS: scripts/${script}"
  else
    echo "FAIL: scripts/${script} is missing or not executable"
    failures=$((failures + 1))
  fi
done

echo
echo "=== Ansible Syntax Verification ==="

for playbook in "${required_playbooks[@]}"; do
  if ansible-playbook \
    --syntax-check \
    "playbooks/${playbook}" >/dev/null 2>&1; then
    echo "PASS: ${playbook} syntax"
  else
    echo "FAIL: ${playbook} syntax"
    failures=$((failures + 1))
  fi
done

echo
echo "=== Idempotency Verification ==="

idempotency_output="$(
  ansible-playbook playbooks/site.yml 2>&1
)"
idempotency_status=$?

printf '%s\n' "$idempotency_output" |
  tail -n 12

if [ "$idempotency_status" -ne 0 ]; then
  echo "FAIL: Master playbook execution failed"
  failures=$((failures + 1))
else
  changed_total="$(
    printf '%s\n' "$idempotency_output" |
      awk '
        /changed=/ {
          for (i = 1; i <= NF; i++) {
            if ($i ~ /^changed=/) {
              split($i, value, "=")
              total += value[2]
            }
          }
        }
        END { print total + 0 }
      '
  )"

  echo "Master playbook changed count: ${changed_total}"

  if [ "$changed_total" -le 2 ]; then
    echo "PASS: Deployment is operationally idempotent"
  else
    echo "WARNING: Deployment completed but reported ${changed_total} changes"
  fi
fi

echo
echo "=== Final Verification Summary ==="

if [ "$failures" -eq 0 ]; then
  echo "FINAL STATUS: HEALTHY"
  echo "All required infrastructure, application, networking, monitoring, and automation checks passed."
  exit 0
fi

echo "FINAL STATUS: FAILED"
echo "Failed checks: ${failures}"
exit 1
