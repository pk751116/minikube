#!/usr/bin/env bash
set -euo pipefail

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Generating mTLS certs and secrets..."
./01-mtls-gen-certs.sh

echo
echo "Applying Kubernetes manifests..."
for f in \
  00-namespace.yaml \
  10-backend-deployment.yaml \
  11-backend-service.yaml \
  12-backend-networkpolicy.yaml \
  13-backend-mtls-configmap.yaml \
  20-frontend-configmap-nginx.yaml \
  21-frontend-configmap-html.yaml \
  22-frontend-deployment.yaml \
  23-frontend-service.yaml \
  30-ingress.yaml; do
  echo "  applying $f"
  kubectl apply -f "$f"
done

echo
echo "Done. Access via:"
echo "  minikube service frontend-svc -n demo"
echo "  or add \"demo.local\" to /etc/hosts pointing at the minikube IP, then browse http://demo.local/"
