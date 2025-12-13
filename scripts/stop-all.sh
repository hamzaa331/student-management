#!/usr/bin/env bash
set -euo pipefail

NS="devops"
PROJECT_DIR="/mnt/c/Users/Hamza/Downloads/student-management"
K8S_DIR="$PROJECT_DIR/k8s"

echo "=============================="
echo " DEVOPS FULL STOP"
echo "=============================="

echo "==> 0) Stop port-forwards"
pkill -f "minikube kubectl -- -n $NS port-forward svc/sonarqube" 2>/dev/null || true
pkill -f "minikube kubectl -- -n $NS port-forward svc/prometheus" 2>/dev/null || true
pkill -f "minikube kubectl -- -n $NS port-forward svc/grafana" 2>/dev/null || true
pkill -f "minikube kubectl -- -n $NS port-forward svc/spring-service" 2>/dev/null || true

echo "==> 1) Start Minikube (needed to delete cleanly)"
minikube start --driver=docker >/dev/null 2>&1 || true

echo "==> 2) Delete Kubernetes resources"
minikube kubectl -- -n "$NS" delete -f "$K8S_DIR/monitoring.yaml" --ignore-not-found
minikube kubectl -- -n "$NS" delete -f "$K8S_DIR/sonarqube.yaml" --ignore-not-found
minikube kubectl -- -n "$NS" delete -f "$K8S_DIR/spring-deployment.yaml" --ignore-not-found
minikube kubectl -- -n "$NS" delete -f "$K8S_DIR/mysql-deployment.yaml" --ignore-not-found

echo "==> 3) Stop Minikube"
minikube stop >/dev/null 2>&1 || true

echo "==> 4) Stop LOCAL Jenkins (old) (optional)"
sudo service jenkins stop >/dev/null 2>&1 || true

echo ""
echo "✅ EVERYTHING STOPPED"
