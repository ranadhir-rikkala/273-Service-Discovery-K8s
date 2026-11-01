#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/common.sh

POD="$(inventory_pods | head -1)"

{
say "Before deletion"
run kubectl get pods -l app=inventory -o wide
run kubectl get service inventory
endpoints

say "Delete $POD"
run kubectl delete pod "$POD"
run kubectl get pods -l app=inventory -o wide
run kubectl rollout status deployment/inventory --timeout=120s
sleep 3

say "After: ReplicaSet created a replacement Pod with a new name and IP"
run kubectl get pods -l app=inventory -o wide
RS="$(kubectl get rs -l app=inventory -o jsonpath='{.items[0].metadata.name}')"
echo "\$ kubectl get events --field-selector involvedObject.name=$RS,reason=SuccessfulCreate"
kubectl get events --field-selector "involvedObject.name=$RS,reason=SuccessfulCreate" | tail -3
echo

say "Service name and ClusterIP are unchanged; endpoints now point at the new Pod"
run kubectl get service inventory
endpoints

say "Client keeps using http://inventory:8080 and now reaches the new Pod (15 s)"
client_window 15

say "Client was never restarted and had no failed requests across the deletion (last 40 s)"
run kubectl get pods -l app=client
echo "\$ kubectl logs deployment/client --since=40s | grep -c FAILED"
kubectl logs deployment/client --since=40s | grep -c FAILED || true
} 2>&1 | tee evidence/3_pod_deletion_and_replacement.txt
