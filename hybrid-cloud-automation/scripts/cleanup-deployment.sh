#!/usr/bin/env bash

set -u

echo "=== Remove Managed Hybrid Environment Resources ==="

managed_containers=(
  webservice-onprem-1
  webservice-cloud-1
  webservice-cloud-2
  cloud-loadbalancer
  cloud-monitoring
  cloud-database
  onprem-cache
  onprem-database
)

for container in "${managed_containers[@]}"; do
  if docker container inspect "$container" >/dev/null 2>&1; then
    echo "Removing container: ${container}"
    docker rm --force "$container"
  else
    echo "Container already absent: ${container}"
  fi
done

for network in onprem-network cloud-network; do
  if docker network inspect "$network" >/dev/null 2>&1; then
    echo "Removing network: ${network}"
    docker network rm "$network"
  else
    echo "Network already absent: ${network}"
  fi
done

echo "Persistent data directories were preserved:"
echo "  /opt/onprem-data"
echo "  /opt/cloud-data"
echo
echo "Cleanup status: COMPLETE"
