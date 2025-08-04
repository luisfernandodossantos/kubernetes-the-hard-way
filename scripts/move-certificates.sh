#!/bin/bash
set -euo pipefail

CERT_DIR="$(cd "$(dirname "$0")/../certificates" && pwd)"

move_cert() {
  local name="$1"
  local target_dir="${CERT_DIR}/${name}"

  echo "[+] Moving files for: ${name}"

  mkdir -p "$target_dir"

  # CSR JSON
  if [[ -f "${CERT_DIR}/${name}-csr.json" ]]; then
    mv "${CERT_DIR}/${name}-csr.json" "${target_dir}/${name}-csr.json"
  fi

  # PEM
  if [[ -f "${CERT_DIR}/${name}.pem" ]]; then
    mv "${CERT_DIR}/${name}.pem" "${target_dir}/${name}.pem"
  fi

  # KEY
  if [[ -f "${CERT_DIR}/${name}-key.pem" ]]; then
    mv "${CERT_DIR}/${name}-key.pem" "${target_dir}/${name}-key.pem"
  fi

  # CSR gerado
  if [[ -f "${CERT_DIR}/${name}.csr" ]]; then
    mv "${CERT_DIR}/${name}.csr" "${target_dir}/${name}.csr"
  fi
}

# Move CA separadamente
echo "[+] Moving files for: ca"
mkdir -p "${CERT_DIR}/ca"
[[ -f "${CERT_DIR}/ca.pem" ]] && mv "${CERT_DIR}/ca.pem" "${CERT_DIR}/ca/"
[[ -f "${CERT_DIR}/ca-key.pem" ]] && mv "${CERT_DIR}/ca-key.pem" "${CERT_DIR}/ca/"
[[ -f "${CERT_DIR}/ca.csr" ]] && mv "${CERT_DIR}/ca.csr" "${CERT_DIR}/ca/"
[[ -f "${CERT_DIR}/ca-config.json" ]] && mv "${CERT_DIR}/ca-config.json" "${CERT_DIR}/ca/"
[[ -f "${CERT_DIR}/ca-csr.json" ]] && mv "${CERT_DIR}/ca-csr.json" "${CERT_DIR}/ca/"

# Lista dos certificados gerados
for component in \
  admin \
  kube-controller-manager \
  kube-scheduler \
  kube-proxy \
  apiserver-kubelet-client \
  service-account \
  kube-apiserver
do
  move_cert "$component"
done

echo "[✓] All files have been moved to their respective directories."
