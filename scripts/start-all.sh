#!/usr/bin/env bash
set -euo pipefail

NS="devops"
PROJECT_DIR="/mnt/c/Users/Hamza/Downloads/student-management"
K8S_DIR="$PROJECT_DIR/k8s"

echo "==> 0) Start LOCAL services (Docker + Jenkins old local)"
sudo service docker start >/dev/null 2>&1 || true
sudo service jenkins start >/dev/null 2>&1 || true

echo "==> 1) Start Minikube (docker driver) + context"
minikube start --driver=docker >/dev/null
minikube update-context >/dev/null 2>&1 || true

echo "==> 2) Ensure namespace exists"
minikube kubectl -- get ns "$NS" >/dev/null 2>&1 || minikube kubectl -- create ns "$NS"

echo "==> 3) Apply Kubernetes YAMLs"
minikube kubectl -- -n "$NS" apply -f "$K8S_DIR/mysql-deployment.yaml"
minikube kubectl -- -n "$NS" apply -f "$K8S_DIR/spring-deployment.yaml"
minikube kubectl -- -n "$NS" apply -f "$K8S_DIR/sonarqube.yaml"
minikube kubectl -- -n "$NS" apply -f "$K8S_DIR/monitoring.yaml"

echo "==> 4) Wait for deployments"
minikube kubectl -- -n "$NS" rollout status deploy/mysql-deployment --timeout=240s || true
minikube kubectl -- -n "$NS" rollout status deploy/student-management-deployment --timeout=240s || true
minikube kubectl -- -n "$NS" rollout status deploy/sonarqube --timeout=240s || true
minikube kubectl -- -n "$NS" rollout status deploy/prometheus --timeout=240s || true
minikube kubectl -- -n "$NS" rollout status deploy/grafana --timeout=240s || true

echo "==> 5) Background port-forwards (keep this terminal open is NOT required because of nohup)"
# kill old port-forwards (safe)
pkill -f "minikube kubectl -- -n $NS port-forward svc/sonarqube" 2>/dev/null || true
pkill -f "minikube kubectl -- -n $NS port-forward svc/prometheus" 2>/dev/null || true
pkill -f "minikube kubectl -- -n $NS port-forward svc/grafana" 2>/dev/null || true
pkill -f "minikube kubectl -- -n $NS port-forward svc/spring-service" 2>/dev/null || true

nohup minikube kubectl -- -n "$NS" port-forward svc/sonarqube 9000:9000 --address 127.0.0.1 >/tmp/pf-sonarqube.log 2>&1 &
nohup minikube kubectl -- -n "$NS" port-forward svc/prometheus 9090:9090 --address 127.0.0.1 >/tmp/pf-prometheus.log 2>&1 &
nohup minikube kubectl -- -n "$NS" port-forward svc/grafana 3000:3000 --address 127.0.0.1 >/tmp/pf-grafana.log 2>&1 &
nohup minikube kubectl -- -n "$NS" port-forward svc/spring-service 8089:8089 --address 127.0.0.1 >/tmp/pf-spring.log 2>&1 &

echo "==> 6) Status"
minikube kubectl -- -n "$NS" get pods -o wide
echo "----"
minikube kubectl -- -n "$NS" get svc -o wide

echo ""
echo "✅ OPEN:"
echo "Jenkins (LOCAL old):   http://localhost:8080"
echo "Spring Boot (K8S PF):  http://127.0.0.1:8089"
echo "SonarQube (K8S PF):    http://127.0.0.1:9000"
echo "Prometheus (K8S PF):   http://127.0.0.1:9090"
echo "Grafana (K8S PF):      http://127.0.0.1:3000"
echo ""
echo "Logs:"
echo "tail -n 80 /tmp/pf-sonarqube.log"
echo "tail -n 80 /tmp/pf-prometheus.log"
echo "tail -n 80 /tmp/pf-grafana.log"
echo "tail -n 80 /tmp/pf-spring.log"
