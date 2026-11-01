#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/common.sh

{
say "1. Deployment, Pods and Service"
run kubectl get deployment inventory client
run kubectl get pods -o wide
run kubectl get service inventory
endpoints

say "2. Client resolves the Service name through cluster DNS"
run kubectl exec deployment/client -- python -c "import socket; print('inventory ->', socket.gethostbyname('inventory')); print('inventory.default.svc.cluster.local ->', socket.gethostbyname('inventory.default.svc.cluster.local'))"
run kubectl get deployment client -o jsonpath='{.spec.template.spec.containers[0].env[0]}'
echo; echo

say "3. Client requests over 20 seconds are spread across both replicas"
client_window 20

say "4. Each replica's own log shows it served requests"
for p in $(inventory_pods); do
  run kubectl logs "$p" --tail=5
done
} 2>&1 | tee evidence/1_discovery_and_load_balancing.txt
