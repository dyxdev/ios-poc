#!/usr/bin/env bash
# Escribe el emisor de Keycloak en Info.plist (clave VNKeycloakIssuer) para compilar contra un Keycloak de pruebas.
# El emisor no es un secreto, pero es de TU Codespace: no subas este cambio (`git checkout Info.plist` lo deshace).
set -euo pipefail
cd "$(dirname "$0")/.."
issuer="${1:-}"
case "$issuer" in
  https://*) ;;
  *) echo "Uso: bash tools/set-issuer.sh https://<host>/realms/<realm>  (solo HTTPS: ATS no tiene excepciones)" >&2; exit 1 ;;
esac
python3 - "$issuer" <<'PY'
import plistlib, sys
with open("Info.plist", "rb") as f:
    data = plistlib.load(f)
data["VNKeycloakIssuer"] = sys.argv[1]
with open("Info.plist", "wb") as f:
    plistlib.dump(data, f)
PY
echo "Info.plist: VNKeycloakIssuer = $issuer"
