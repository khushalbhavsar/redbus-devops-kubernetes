#!/bin/bash
# Deploy Prometheus and Grafana Monitoring Stack to EKS
# Usage: ./deploy-monitoring.sh

set -e

echo "🚀 Deploying Prometheus & Grafana Monitoring Stack..."

# Apply all monitoring manifests
kubectl apply -f infra/kubernetes/monitoring/namespace.yml
kubectl apply -f infra/kubernetes/monitoring/prometheus-rbac.yml
kubectl apply -f infra/kubernetes/monitoring/prometheus-configmap.yml
kubectl apply -f infra/kubernetes/monitoring/prometheus-deployment.yml
kubectl apply -f infra/kubernetes/monitoring/grafana-configmap.yml
kubectl apply -f infra/kubernetes/monitoring/grafana-deployment.yml
kubectl apply -f infra/kubernetes/monitoring/node-exporter.yml

echo "⏳ Waiting for Prometheus to be ready..."
kubectl rollout status deployment/prometheus -n monitoring --timeout=120s

echo "⏳ Waiting for Grafana to be ready..."
kubectl rollout status deployment/grafana -n monitoring --timeout=120s

echo ""
echo "✅ Monitoring Stack Deployed Successfully!"
echo ""
echo "📊 Access URLs (replace <NODE_IP> with your EKS node IP):"
echo "   Prometheus: http://<NODE_IP>:30090"
echo "   Grafana:    http://<NODE_IP>:30030"
echo ""
echo "🔑 Grafana Credentials:"
echo "   Username: admin"
echo "   Password: admin123"
echo ""
echo "📝 To get Node IP:"
echo "   kubectl get nodes -o wide"
echo ""
echo "📝 To verify services:"
echo "   kubectl get svc -n monitoring"
