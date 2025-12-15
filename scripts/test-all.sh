#!/bin/bash
set -euo pipefail

NS="devops"

SPRING_LOCAL="http://127.0.0.1:8089"
SPRING_CTX="/student"
GRAFANA_LOCAL="http://127.0.0.1:3000"
PROM_LOCAL="http://127.0.0.1:9090"
JENKINS_LOCAL="http://127.0.0.1:8080"
NEXUS_LOCAL="http://127.0.0.1:8081"

SONAR_URL="${SONAR_URL:-http://127.0.0.1:9001}"
SONAR_PROJECT_KEY="${SONAR_PROJECT_KEY:-tn.esprit:student-management}"

ok()   { echo -e "✅ $*"; }
warn() { echo -e "⚠️  $*"; }
bad()  { echo -e "❌ $*"; }
hr()   { echo "------------------------------------------------------------"; }

require_cmd() { command -v "$1" >/dev/null 2>&1 || { bad "Missing command: $1"; exit 1; }; }

http_code() {
  local url="$1"
  curl -s -o /dev/null -m 4 -w "%{http_code}" "$url" || echo "000"
}

echo "=============================="
echo "   DEVOPS FULL TEST (CHECK ALL)"
echo "=============================="

require_cmd kubectl
require_cmd minikube
require_cmd curl
require_cmd grep
require_cmd awk

hr
echo "1) Check Minikube status"
minikube status >/dev/null 2>&1 && ok "minikube is running" || { bad "minikube NOT running"; exit 1; }

hr
echo "2) Check kubectl context"
CTX="$(kubectl config current-context || true)"
[[ "$CTX" == "minikube" ]] && ok "kubectl context = minikube" || warn "kubectl context is '$CTX' (expected minikube)"

hr
echo "3) Check namespace '$NS'"
kubectl get ns "$NS" >/dev/null 2>&1 && ok "namespace '$NS' exists" || { bad "namespace '$NS' missing"; exit 1; }

hr
echo "4) Pods"
kubectl get pods -n "$NS" -o wide || true
BAD_PODS="$(kubectl get pods -n "$NS" --no-headers 2>/dev/null | awk '$3!="Running" && $3!="Completed"{print $1 " -> " $3}' || true)"
[[ -z "$BAD_PODS" ]] && ok "All pods are Running/Completed" || { warn "Some pods not Running:"; echo "$BAD_PODS"; }

hr
echo "5) Services"
kubectl get svc -n "$NS" -o wide || true

hr
echo "6) Local endpoints"
echo "Spring:     $SPRING_LOCAL"
echo "Grafana:    $GRAFANA_LOCAL"
echo "Prometheus: $PROM_LOCAL"
echo "Jenkins:    $JENKINS_LOCAL"
echo "Nexus:      $NEXUS_LOCAL"
echo "SonarQube:  $SONAR_URL"

hr
echo "7) Spring Boot (API + Actuator)"
PING_CODE="$(http_code "$SPRING_LOCAL${SPRING_CTX}/students/ping")"
[[ "$PING_CODE" == "200" || "$PING_CODE" == "302" ]] && ok "Spring ping OK (HTTP $PING_CODE)" || warn "Spring ping FAIL (HTTP $PING_CODE)"

LIST_CODE="$(http_code "$SPRING_LOCAL/student/students/getAllStudents")"
[[ "$LIST_CODE" == "200" ]] && ok "getAllStudents OK" || warn "getAllStudents FAIL (HTTP $LIST_CODE)"

ACT_CODE="$(http_code "$SPRING_LOCAL${SPRING_CTX}/actuator/health")"
[[ "$ACT_CODE" == "200" || "$ACT_CODE" == "401" ]] && ok "Actuator health OK (HTTP $ACT_CODE)" || warn "Actuator health FAIL (HTTP $ACT_CODE)"

MET_CODE="$(http_code "$SPRING_LOCAL${SPRING_CTX}/actuator/prometheus")"
[[ "$MET_CODE" == "200" ]] && ok "Prometheus metrics OK" || warn "Prometheus metrics FAIL (HTTP $MET_CODE)"

hr
echo "8) Prometheus"
P_READY="$(http_code "$PROM_LOCAL/-/ready")"
[[ "$P_READY" == "200" ]] && ok "Prometheus ready OK" || warn "Prometheus NOT ready (HTTP $P_READY)"

# Check spring target is UP
SPRING_TARGET_HEALTH="$(curl -s "$PROM_LOCAL/api/v1/targets" | grep -o '"job":"spring-boot"[^}]*"health":"[^"]*"' | head -n 1 || true)"
if echo "$SPRING_TARGET_HEALTH" | grep -qi '"health":"up"'; then
  ok "Prometheus target spring-boot = UP"
else
  warn "Prometheus spring-boot target not UP (check prometheus.yml / service DNS)"
fi

hr
echo "9) Grafana"
G_CODE="$(http_code "$GRAFANA_LOCAL/login")"
[[ "$G_CODE" == "200" ]] && ok "Grafana login OK" || warn "Grafana not reachable (HTTP $G_CODE)"

hr
echo "10) Nexus"
N_CODE="$(http_code "$NEXUS_LOCAL/")"
[[ "$N_CODE" == "200" || "$N_CODE" == "401" || "$N_CODE" == "302" ]] && ok "Nexus reachable (HTTP $N_CODE)" || warn "Nexus not reachable (HTTP $N_CODE)"

hr
echo "11) Jenkins (UI only)"
J_CODE="$(http_code "$JENKINS_LOCAL/login")"
[[ "$J_CODE" == "200" || "$J_CODE" == "403" ]] && ok "Jenkins reachable (HTTP $J_CODE)" || warn "Jenkins not reachable (HTTP $J_CODE)"

hr
echo "12) SonarQube"
S_CODE="$(http_code "$SONAR_URL/api/system/status")"
[[ "$S_CODE" == "200" || "$S_CODE" == "401" ]] && ok "SonarQube API reachable (HTTP $S_CODE)" || warn "SonarQube not reachable (HTTP $S_CODE)"

if [[ -n "${SONAR_TOKEN:-}" ]]; then
  PJSON="$(curl -s -u "$SONAR_TOKEN:" "$SONAR_URL/api/projects/search?projects=$SONAR_PROJECT_KEY" || true)"
  echo "$PJSON" | grep -q "\"key\":\"$SONAR_PROJECT_KEY\"" && ok "Sonar project exists: $SONAR_PROJECT_KEY" || warn "Sonar project not found: $SONAR_PROJECT_KEY"
else
  warn "SONAR_TOKEN not set (skipping Sonar project check)."
fi

hr
echo "✅ FINAL LINKS"
echo "Spring API:      $SPRING_LOCAL${SPRING_CTX}/students/getAllStudents"
echo "Actuator health: $SPRING_LOCAL${SPRING_CTX}/actuator/health"
echo "Metrics:         $SPRING_LOCAL${SPRING_CTX}/actuator/prometheus"
echo "Prometheus:      $PROM_LOCAL"
echo "Grafana:         $GRAFANA_LOCAL"
echo "Jenkins:         $JENKINS_LOCAL"
echo "Nexus:           $NEXUS_LOCAL"
echo "SonarQube:       $SONAR_URL"
echo "=============================="
echo "   ✔ TEST COMPLETED"
echo "=============================="
