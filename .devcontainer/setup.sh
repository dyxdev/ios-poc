#!/usr/bin/env bash
# Prepara el Codespace: herramientas básicas y comprobación del compilador. Los paquetes de Swift puro se prueban
# aquí con `swift test`. La app (SwiftUI) y el SDK de Apple NO se pueden compilar en Linux: ver docs/plan.md.
set -euo pipefail
apt-get update -qq
apt-get install -y -qq git curl ca-certificates unzip jq python3 >/dev/null
swift --version
echo "Listo. Prueba el núcleo con: bash tools/test-all.sh"
