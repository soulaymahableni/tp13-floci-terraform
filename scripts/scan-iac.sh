#!/usr/bin/env bash
# Partie 5 : scan IaC. Code retour != 0 si un problème est trouvé (bloquant en CI).
# Usage : scripts/scan-iac.sh [dossier]   (par défaut : terraform/)
set -uo pipefail
DIR=$(cd "${1:-$(dirname "$0")/../terraform}" && pwd)
rc=0

echo "===== Checkov ====="
docker run --rm -v "$DIR:/tf" bridgecrew/checkov -d /tf --framework terraform --quiet --compact || rc=1

echo "===== Trivy ====="
docker run --rm -v "$DIR:/tf" aquasec/trivy:latest config --exit-code 1 \
  --severity HIGH,CRITICAL /tf || rc=1

if [ "$rc" -ne 0 ]; then echo "SCAN IaC : ÉCHEC"; else echo "SCAN IaC : OK"; fi
exit $rc
