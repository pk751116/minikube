@echo off
setlocal enabledelayedexpansion

set "NAMESPACE=demo"
set "CERT_DIR=%~dp0mtls-certs"

if not exist "%CERT_DIR%" mkdir "%CERT_DIR%"
pushd "%CERT_DIR%"

echo Generating CA...
openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -keyout ca.key -out ca.crt -subj "/CN=demo-mtls-ca"
if errorlevel 1 goto :error

echo Generating server cert...
openssl req -newkey rsa:2048 -nodes -keyout server.key -out server.csr -subj "/CN=backend-svc.demo.svc.cluster.local"
if errorlevel 1 goto :error

> server-ext.cnf echo subjectAltName=DNS:backend-svc,DNS:backend-svc.demo.svc.cluster.local
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 3650 -extfile server-ext.cnf
if errorlevel 1 goto :error

echo Generating client cert...
openssl req -newkey rsa:2048 -nodes -keyout client.key -out client.csr -subj "/CN=frontend"
if errorlevel 1 goto :error

openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt -days 3650
if errorlevel 1 goto :error

echo Creating namespace and secrets...
kubectl create namespace %NAMESPACE% --dry-run=client -o yaml | kubectl apply -f -
if errorlevel 1 goto :error

kubectl -n %NAMESPACE% create secret generic mtls-ca --from-file=ca.crt=ca.crt --dry-run=client -o yaml | kubectl apply -f -
if errorlevel 1 goto :error

kubectl -n %NAMESPACE% create secret tls backend-server-tls --cert=server.crt --key=server.key --dry-run=client -o yaml | kubectl apply -f -
if errorlevel 1 goto :error

kubectl -n %NAMESPACE% create secret tls frontend-client-tls --cert=client.crt --key=client.key --dry-run=client -o yaml | kubectl apply -f -
if errorlevel 1 goto :error

popd
echo mTLS certs written to %CERT_DIR% and secrets created in namespace %NAMESPACE%
endlocal
exit /b 0

:error
popd
echo Failed generating mTLS certs/secrets.
endlocal
exit /b 1
