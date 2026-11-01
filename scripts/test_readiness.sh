#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/common.sh

POD="$(inventory_pods | head -1)"

{
say "Before: both Pods ready"
run kubectl get pods -l app=inventory -o wide
endpoints

say "Make $POD fail readiness (create /tmp/unready so /ready returns 503)"
run kubectl exec "$POD" -- touch /tmp/unready
run kubectl exec "$POD" -- python -c "import urllib.request as u
try: u.urlopen('http://localhost:8080/ready')
except Exception as e: print('GET /ready ->', e)"
sleep 6

say "Pod is still Running (0 restarts) but READY is 0/1"
run kubectl get pods -l app=inventory -o wide
endpoints
echo "\$ kubectl get events --field-selector involvedObject.name=$POD,reason=Unhealthy"
kubectl get events --field-selector "involvedObject.name=$POD,reason=Unhealthy" | tail -3
echo

say "Client traffic while $POD is unready (20 s): only the ready Pod answers"
client_window 20
echo "\$ kubectl logs $POD --since=20s | grep -c served"
kubectl logs "$POD" --since=20s | grep -c served || true
echo

say "Restore readiness (remove /tmp/unready)"
run kubectl exec "$POD" -- rm /tmp/unready
sleep 6
run kubectl get pods -l app=inventory -o wide
endpoints

say "Client traffic after recovery (20 s): both Pods answer again"
client_window 20
} 2>&1 | tee evidence/2_readiness_failure_and_recovery.txt
