#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
CLUSTER="${CLUSTER:-module6}"

kind get clusters | grep -qx "$CLUSTER" || kind create cluster --name "$CLUSTER"
docker build -t inventory-service:1.0 inventory
docker build -t inventory-client:1.0 client
kind load docker-image inventory-service:1.0 inventory-client:1.0 --name "$CLUSTER"
kubectl apply -f k8s/inventory.yaml
kubectl rollout status deployment/inventory --timeout=120s
kubectl apply -f k8s/client.yaml
kubectl rollout status deployment/client --timeout=120s
kubectl get pods -o wide
