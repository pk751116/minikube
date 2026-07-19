#!/usr/bin/env bash
set -euo pipefail

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Deleting Kubernetes manifests..."
for f in \
  30-ingress.yaml \
  23-frontend-service.yaml \
  22-frontend-deployment.yaml \
  21-frontend-configmap-html.yaml \
  20-frontend-configmap-nginx.yaml \
  13-backend-mtls-configmap.yaml \
  12-backend-networkpolicy.yaml \
  11-backend-service.yaml \
  10-backend-deployment.yaml \
  00-namespace.yaml; do
  echo "  deleting $f"
  kubectl delete -f "$f" --ignore-not-found
done

echo
echo "Done. The demo namespace (and everything in it, including the mTLS secrets) is gone."
echo "Locally generated certs in ./mtls-certs/ were left in place; remove that directory yourself if you want a full reset."
