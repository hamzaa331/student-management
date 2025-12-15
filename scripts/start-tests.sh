#!/bin/bash
set -euo pipefail

NS="devops"

echo "=============================="
echo "   START DEVOPS TEST (SAFE)"
echo "=============================="

port_in_use() {
  local PORT="$1"
  if command -v lsof >/dev/null 2>&1; then
    lsof -iTCP:${PORT} -sTCP:LISTEN >/dev/null 2>&1
  else
    ss -ltn "( sport = :$PORT )" | grep -q LISTEN
  fi
}

start_pf () {
  local NAME="$1"
  local TARGET="$2"
  local LOCAL_PORT="$3"
  local REMOTE_PORT="$4"

  if port_in_use "$LOCAL_PORT"; then
    echo "ℹ️  ${NAME} already exposed on port ${LOCAL_PORT}"
  else
    echo "🚀 Starting ${NAME} port-forward ${LOCAL_PORT} -> ${REMOTE_PORT}"
    kubectl port-forward -n "${NS}" "${TARGET}" "${LOCAL_PORT}:${REMOTE_PORT}" --address 0.0.0.0 >/dev/null 2>&1 &
    sleep 1
    echo "✅ ${NAME} available on http://127.0.0.1:${LOCAL_PORT}"
  fi
}

start_pf "Spring Boot" "svc/spring-service" 8089 8089
start_pf "Grafana"    "svc/grafana"       3000 3000
start_pf "Prometheus" "svc/prometheus"    9090 9090
start_pf "SonarQube"  "svc/sonarqube"     9001 9000

echo "------------------------------------------------------------"
echo "✔ Port-forwards started"
echo "✔ No resources created or deleted"
echo "=============================="
