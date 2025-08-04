#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CERT_DIR="${BASE_DIR}/certificates"
CONFIG_DIR="${BASE_DIR}/config"

CA_CERT="${CERT_DIR}/ca/ca.pem"
API_SERVER="https://prod-nlb-67a0be6d2bb46b87.elb.us-east-1.amazonaws.com:6443"

mkdir -p "$CONFIG_DIR"

generate_kubeconfig() {
  local name="$1"
  local user="$2"
  local cert="${CERT_DIR}/${name}/${name}.pem"
  local key="${CERT_DIR}/${name}/${name}-key.pem"
  local output="${CONFIG_DIR}/${name}.kubeconfig"

  echo "[+] Generating kubeconfig for ${name}"

  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority="$CA_CERT" \
    --embed-certs=true \
    --server="$API_SERVER" \
    --kubeconfig="$output"

  kubectl config set-credentials "$user" \
    --client-certificate="$cert" \
    --client-key="$key" \
    --embed-certs=true \
    --kubeconfig="$output"

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user="$user" \
    --kubeconfig="$output"

  kubectl config use-context default \
    --kubeconfig="$output"
}

generate_kubeconfig "admin" "admin"
generate_kubeconfig "kube-controller-manager" "system:kube-controller-manager"
generate_kubeconfig "kube-scheduler" "system:kube-scheduler"
generate_kubeconfig "kube-proxy" "system:kube-proxy"

echo "[✓] All kubeconfig files generated in: $CONFIG_DIR"
