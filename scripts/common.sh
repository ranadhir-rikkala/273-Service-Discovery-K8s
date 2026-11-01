run() {
  echo "\$ $*"
  "$@"
  echo
}

say() {
  echo "### $*"
  echo
}

inventory_pods() {
  kubectl get pods -l app=inventory -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
}

endpoints() {
  echo "\$ kubectl get endpointslices -l kubernetes.io/service-name=inventory -o jsonpath=..."
  kubectl get endpointslices -l kubernetes.io/service-name=inventory \
    -o jsonpath='{range .items[*].endpoints[*]}{.targetRef.name}{"  ip="}{.addresses[0]}{"  ready="}{.conditions.ready}{"\n"}{end}'
  echo
}

client_window() {
  sleep "$1"
  run kubectl logs deployment/client --since="${1}s"
}
