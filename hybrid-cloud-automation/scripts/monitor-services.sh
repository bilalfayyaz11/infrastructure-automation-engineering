#!/usr/bin/env bash

set -u

echo "=== Hybrid Environment Service Monitor ==="
echo "Timestamp: $(date --iso-8601=seconds)"
echo

echo "=== Managed Container Status ==="
docker ps \
  --filter "label=environment=onpremises" \
  --filter "label=environment=cloud" \
  --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}\t{{.Networks}}"

echo
echo "=== Docker Network Status ==="
for network in onprem-network cloud-network; do
  if docker network inspect "$network" >/dev/null 2>&1; then
    docker network inspect "$network" \
      --format 'Network={{.Name}} Driver={{.Driver}} Containers={{len .Containers}}'
  else
    echo "Network ${network}: MISSING"
  fi
done

echo
echo "=== HTTP Health Checks ==="

check_endpoint() {
  local name="$1"
  local url="$2"

  if curl --fail --silent --show-error --max-time 5 "$url" >/dev/null 2>&1; then
    echo "PASS: ${name} - ${url}"
    return 0
  fi

  echo "FAIL: ${name} - ${url}"
  return 1
}

failures=0

check_endpoint "On-premises web service" \
  "http://127.0.0.1:5000/health" || failures=$((failures + 1))

check_endpoint "Cloud web service 1" \
  "http://127.0.0.1:5001/health" || failures=$((failures + 1))

check_endpoint "Cloud web service 2" \
  "http://127.0.0.1:5002/health" || failures=$((failures + 1))

check_endpoint "NGINX load balancer" \
  "http://127.0.0.1:8080/load-balancer-health" || failures=$((failures + 1))

check_endpoint "Prometheus" \
  "http://127.0.0.1:9090/-/healthy" || failures=$((failures + 1))

echo
echo "=== Database and Cache Checks ==="

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

echo
echo "=== Container Resource Usage ==="
docker stats \
  --no-stream \
  --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"

echo
echo "=== Monitor Summary ==="

if [ "$failures" -eq 0 ]; then
  echo "Overall status: HEALTHY"
  exit 0
fi

echo "Overall status: DEGRADED (${failures} failed checks)"
exit 1
