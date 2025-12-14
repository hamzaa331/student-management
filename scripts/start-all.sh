#!/bin/bash
set -e

echo "=============================="
echo " DEVOPS FULL START (Kubernetes)"
echo "=============================="

##############################################
# 0) START LOCAL SERVICES (DOCKER + SONARQUBE ON WINDOWS)
##############################################
echo "==> STEP 0: Start Docker Desktop (manually if not already)"
echo "==> SonarQube will run from Windows on: http://localhost:9000"

##############################################
# 1) START MINIKUBE
##############################################
echo "==> STEP 1: Starting Minikube..."
minikube start --driver=docker

# Set kubectl context
echo "==> STEP 1b: Setting kubectl context"
kubectl config use-context minikube

##############################################
# 2) CREATE NAMESPACE
##############################################
echo "==> STEP 2: Ensuring namespace 'devops' exists..."
kubectl get ns devops || kubectl create namespace devops

##############################################
# 3) APPLY K8S YAMLs
##############################################
echo "==> STEP 3: Deploying Kubernetes resources..."

kubectl apply -n devops -f k8s/mysql-deployment.yaml
kubectl apply -n devops -f k8s/student-management-deployment.yaml
kubectl apply -n devops -f k8s/nexus-deployment.yaml
kubectl apply -n devops -f k8s/jenkins-deployment.yaml
kubectl apply -n devops -f k8s/sonarqube-np.yaml        # NodePort only (NOT LOCAL SERVER)
kubectl apply -n devops -f k8s/prometheus-deployment.yaml
kubectl apply -n devops -f k8s/grafana-deployment.yaml

##############################################
# 4) WAIT FOR DEPLOYMENTS
##############################################
echo "==> STEP 4: Waiting for all deployments to be ready..."

kubectl rollout status deployment/mysql -n devops
kubectl rollout status deployment/student-app -n devops
kubectl rollout status deployment/nexus -n devops
kubectl rollout status deployment/jenkins -n devops
kubectl rollout status deployment/sonarqube -n devops
kubectl rollout status deployment/prometheus -n devops
kubectl rollout status deployment/grafana -n devops

##############################################
# 5) PORT FORWARDING FOR DASHBOARDS
##############################################
echo "==> STEP 5: Port forwarding (background mode)..."

# Jenkins UI
kubectl port-forward -n devops svc/jenkins 8088:8080 >/dev/null 2>&1 &

# Nexus UI
kubectl port-forward -n devops svc/nexus 8081:8081 >/dev/null 2>&1 &

# Spring Boot App
kubectl port-forward -n devops svc/spring-service 8089:8080 >/dev/null 2>&1 &

# Prometheus UI
kubectl port-forward -n devops svc/prometheus 9090:9090 >/dev/null 2>&1 &

# Grafana UI
kubectl port-forward -n devops svc/grafana 3000:3000 >/dev/null 2>&1 &

echo "=============================="
echo " SERVICES READY!"
echo "=============================="
echo "Jenkins:       http://localhost:8088"
echo "Nexus:         http://localhost:8081"
echo "Spring App:    http://localhost:8089/student/students/getAllStudents"
echo "Prometheus:    http://localhost:9090"
echo "Grafana:       http://localhost:3000"
echo "SonarQube:     http://localhost:9000  (LOCAL WINDOWS VERSION)"
echo "=============================="
