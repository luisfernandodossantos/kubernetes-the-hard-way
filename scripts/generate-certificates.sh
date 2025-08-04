#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CERT_DIR="${BASE_DIR}/certificates"
CA_DIR="${CERT_DIR}/ca"

# CA config
CA_CSR="${CA_DIR}/ca-csr.json"
CA_CONFIG="${CA_DIR}/ca-config.json"
CA_PEM="${CA_DIR}/ca.pem"
CA_KEY="${CA_DIR}/ca-key.pem"

echo "[+] Generating CA (if not already present)..."
if [[ ! -f "$CA_PEM" || ! -f "$CA_KEY" ]]; then
  cfssl gencert -initca "$CA_CSR" | cfssljson -bare "${CA_DIR}/ca"
else
  echo "  • CA already exists, skipping."
fi

generate_cert() {
  local name="$1"
  local cn="$2"
  local org="$3"
  local hosts="$4"

  local target_dir="${CERT_DIR}/${name}"
  local csr_file="${target_dir}/${name}-csr.json"

  mkdir -p "$target_dir"

  echo "[+] Generating certificate: ${name}"

  cat > "$csr_file" <<EOF
{
  "CN": "${cn}",
  "hosts": [${hosts}],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [{
    "C": "US",
    "ST": "Florida",
    "L": "Tampa",
    "O": "${org}",
    "OU": "Kubernetes"
  }]
}
EOF

  cfssl gencert \
    -ca="$CA_PEM" \
    -ca-key="$CA_KEY" \
    -config="$CA_CONFIG" \
    -profile=kubernetes \
    "$csr_file" | cfssljson -bare "${target_dir}/${name}"
}

# Generate certificates
generate_cert "admin" "admin" "system:masters" ""

generate_cert "kube-controller-manager" "system:kube-controller-manager" "system:kube-controller-manager" ""

generate_cert "kube-scheduler" "system:kube-scheduler" "system:kube-scheduler" ""

generate_cert "kube-proxy" "system:kube-proxy" "system:node-proxier" "\"127.0.0.1\", \"kube-proxy\""

generate_cert "apiserver-kubelet-client" "kube-apiserver-kubelet-client" "system:masters" ""

generate_cert "service-account" "service-accounts" "Kubernetes" ""

generate_cert "kube-apiserver" "kubernetes" "Kubernetes" \
"\"127.0.0.1\", \"10.32.0.1\", \"kubernetes\", \"kubernetes.default\", \"kubernetes.default.svc\", \"kubernetes.default.svc.cluster\", \"kubernetes.svc.cluster.local\", \"server.kubernetes.local\", \"api-server.kubernetes.local\""

echo "[✓] All certificates have been generated in their respective directories."
