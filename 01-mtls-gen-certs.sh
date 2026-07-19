#!/usr/bin/env bash
# Generates a demo CA + server/client cert pair for mTLS between frontend and backend,
# and loads them into Secrets in the demo namespace. Run before applying the other manifests.
set -euo pipefail

NAMESPACE=demo
CERT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/mtls-certs"

mkdir -p "$CERT_DIR"
cd "$CERT_DIR"

openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
  -keyout ca.key -out ca.crt -subj "/CN=demo-mtls-ca"

openssl req -newkey rsa:2048 -nodes \
  -keyout server.key -out server.csr -subj "/CN=backend-svc.demo.svc.cluster.local"
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out server.crt -days 3650 \
  -extfile <(printf "subjectAltName=DNS:backend-svc,DNS:backend-svc.demo.svc.cluster.local")

openssl req -newkey rsa:2048 -nodes \
  -keyout client.key -out client.csr -subj "/CN=frontend"
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out client.crt -days 3650

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "$NAMESPACE" create secret generic mtls-ca \
  --from-file=ca.crt=ca.crt --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "$NAMESPACE" create secret tls backend-server-tls \
  --cert=server.crt --key=server.key --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "$NAMESPACE" create secret tls frontend-client-tls \
  --cert=client.crt --key=client.key --dry-run=client -o yaml | kubectl apply -f -

echo "mTLS certs written to $CERT_DIR and secrets created in namespace $NAMESPACE"
