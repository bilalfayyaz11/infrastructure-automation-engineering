#!/usr/bin/env bash

set -euo pipefail

BASE_URL="${BASE_URL:-http://127.0.0.1}"

echo "===== NGINX SERVICE ====="
systemctl is-active --quiet nginx
echo "PASS: Nginx is active"

echo "===== PORT 80 ====="
ss -lnt | grep -qE ':[8]0[[:space:]]'
echo "PASS: Port 80 is listening"

echo "===== APPLICATION HTTP STATUS ====="
HTTP_CODE=$(curl -fsS \
  -o /tmp/deployment-response.html \
  -w "%{http_code}" \
  "${BASE_URL}/")

test "$HTTP_CODE" = "200"
echo "PASS: Application returned HTTP 200"

echo "===== APPLICATION CONTENT ====="
grep -q "Application Deployed Successfully" \
  /tmp/deployment-response.html
echo "PASS: Expected content is present"

echo "===== DEPLOYMENT METADATA ====="
grep -q "Build Number:" /tmp/deployment-response.html
grep -q "Environment:" /tmp/deployment-response.html
grep -q "Application Version:" /tmp/deployment-response.html
echo "PASS: Deployment metadata is present"

echo "===== HEALTH ENDPOINT ====="
curl -fsS "${BASE_URL}/health" | grep -q "healthy"
echo "PASS: Health endpoint is healthy"

echo "===== ALL DEPLOYMENT TESTS PASSED ====="
