#!/bin/bash
set -e

echo "=============================="
echo "   DEVOPS FULL START"
echo "=============================="

echo "➡️  STEP 0 — Make sure Docker Desktop is started manually"
echo ""

echo "➡️  STEP 1 — Start Minikube"
minikube start --driver=docker

echo "➡️  STEP 1b — Set kubectl context"
kubectl config use-context minikube

echo "➡️  STEP 2 — Create namespace 'devops' if missing"
kubectl get namespace devops || kubectl create namespace devops

echo "➡️  STEP 3 — Apply MySQL"
kubectl apply -n devops -f k8s/mysql-deployment.yaml

echo "➡️  STEP 4 — Apply Spring Backend"
kubectl apply -n devops -f k8s/spring-deployment.yaml

echo "➡️  STEP 5 — Apply Monitoring (Prometheus + Grafana)"
kubectl apply -n devops -f k8s/monitoring.yaml

echo "➡️  STEP 6 — SKIPPED — Jenkins is NOT deployed to Kubernetes"
echo "    ✔ Using SYSTEM Jenkins instead → http://localhost:8080"

echo "➡️  STEP 7 — Start Jenkins SYSTEM service"
sudo service jenkins start

echo "➡️  STEP 8 — Wait for pods to be ready"
kubectl -n devops rollout status deployment/mysql
kubectl -n devops rollout status deployment/student-management-deployment || true
kubectl -n devops rollout status deployment/grafana-deployment || true
kubectl -n devops rollout status deployment/prometheus-deployment || true

echo "➡️  STEP 9 — Start port-forwards (run in background)"
nohup kubectl -n devops port-forward svc/spring-service 8089:8089 >/dev/null 2>&1 &
nohup kubectl -n devops port-forward svc/grafana 3000:3000 >/dev/null 2>&1 &
nohup kubectl -n devops port-forward svc/prometheus 9090:9090 >/dev/null 2>&1 &

echo ""
echo "=============================="
echo "   ✔ ALL SERVICES STARTED"
echo "=============================="
echo "Spring Backend → http://localhost:8089/student/students/getAllStudents"
echo "Grafana → http://localhost:3000"
echo "Prometheus → http://localhost:9090"
echo "Jenkins (system) → http://localhost:8080"
echo "SonarQube (Windows) → http://localhost:9000"
