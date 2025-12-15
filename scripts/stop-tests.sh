#!/bin/bash
set -euo pipefail

echo "=============================="
echo "   STOP DEVOPS TEST (SAFE)"
echo "=============================="

stop_pf() {
  local PORT="$1"
  local NAME="$2"

  local PIDS=""
  if command -v lsof >/dev/null 2>&1; then
    PIDS="$(lsof -t -iTCP:${PORT} -sTCP:LISTEN 2>/dev/null || true)"
  else
    # best-effort fallback (might be empty depending on ss output)
    PIDS="$(ss -ltnp "( sport = :$PORT )" 2>/dev/null | awk -F'pid=' 'NF>1{print $2}' | awk -F',' '{print $1}' | head -n 1 || true)"
  fi

  if [[ -z "${PIDS}" ]]; then
    echo "ℹ️  ${NAME}: no port-forward running on port ${PORT}"
  else
    echo "🛑 Stopping ${NAME} port-forward on port ${PORT} (PID: ${PIDS})"
    kill ${PIDS} >/dev/null 2>&1 || true
    echo "✅ ${NAME} port-forward stopped"
  fi
}

stop_pf 9001 "SonarQube"
stop_pf 9090 "Prometheus"
stop_pf 3000 "Grafana"
stop_pf 8089 "Spring Boot"

echo "------------------------------------------------------------"
echo "✔ All port-forwards closed"
echo "✔ Kubernetes resources preserved"
echo "✔ SonarQube / Jenkins data untouched"
echo "=============================="
