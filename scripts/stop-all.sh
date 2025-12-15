#!/bin/bash
echo "=============================="
echo "   DEVOPS FULL STOP"
echo "=============================="

echo "➡️  Kill port-forward processes"
pkill -f "kubectl -n devops port-forward" || true

echo "➡️  Stop Jenkins SYSTEM service"
sudo service jenkins stop || true

echo "➡️  Stop Minikube"
minikube stop || true

echo "➡️  NOTHING will stop Docker Jenkins, because you do NOT use Docker Jenkins anymore."

echo "=============================="
echo "   ✔ ALL STOPPED CLEANLY"
echo "=============================="
