#!/usr/bin/env bash
# Ejecuta `swift test` en cada paquete local. Salida completa en build.log (que se pega al revisor).
# En Linux se omiten los paquetes SOLO PARA APPLE (usan SwiftUI, Keychain, AppAuth…): los prueba el job de macOS.
set -uo pipefail
cd "$(dirname "$0")/.."
apple_only="Packages/AppleKit/"
status=0
{
  for package in Packages/*/; do
    if [ "$(uname -s)" = "Linux" ] && [ "$package" = "$apple_only" ]; then
      echo "=== $package (omitido en Linux: solo Apple)"
      continue
    fi
    echo "=== $package"
    if ! (cd "$package" && swift test 2>&1); then
      echo "FALLA: $package"
      status=1
    fi
  done
  python3 tools/check-strings.py || status=1
  echo "estado final: $status"
} 2>&1 | tee build.log
exit "$(tail -n 1 build.log | sed 's/estado final: //')"
