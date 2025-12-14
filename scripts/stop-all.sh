#!/bin/bash
echo "=============================="
echo " DEVOPS FULL STOP"
echo "=============================="

echo "==> Killing ALL port-forward processes..."
pkill -f "kubectl port-forward" || true

echo "==> Stopping Minikube..."
minikube stop

echo "==> DevOps environment stopped successfully!"
echo "=============================="
