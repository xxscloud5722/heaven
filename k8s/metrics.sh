#!/usr/bin/env bash
set -e

function metrics() {
  mapfile -t pods < <(kubectl get pods --namespace="${1}" -o custom-columns=NAME:.metadata.name --no-headers)
  for pod in "${pods[@]}"; do
    kubectl top pod "$pod" -n "${1}"
  done
}


if [ -z "${1}" ]; then
  namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')
  for namespace in $namespaces; do
    echo " =========================== ${namespace} ==========================="
    metrics "$namespace"
    echo " ==================================================================="
    echo ""
    echo ""
  done
else
  metrics "$1"
fi

