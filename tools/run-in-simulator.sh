#!/usr/bin/env bash
# Instala y lanza la app en el simulador de iOS de un Mac. Solo macOS con Xcode.
# Uso: bash tools/run-in-simulator.sh <VenueNexa-simulator.zip | ruta/a/VenueNexa.app> [argumentos de lanzamiento...]
# Ejemplos de argumentos (solo en la compilación Debug, ver LaunchOverrides.swift):
#   -VNScreen detail            abre directamente el detalle de un espacio
#   -VNScreen owner             perfil de propietario (con sesión falsa)
#   -AppleLanguages "(es)" -AppleLocale es_ES     la app en español
# Sin verificar: este script no se ha ejecutado en un Mac todavía.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
source_path="${1:?Falta la ruta al .zip o al .app}"
shift || true
bundle="com.venuenexa.pocios"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
case "$source_path" in
  *.zip) ditto -x -k "$source_path" "$work"; app="$work/VenueNexa.app" ;;
  *.app) app="$source_path" ;;
  *) echo "Se espera un .zip o un .app" >&2; exit 1 ;;
esac
[ -d "$app" ] || { echo "No encuentro VenueNexa.app dentro de $source_path" >&2; exit 1; }

udid="$(bash "$here/pick-simulator.sh")"
xcrun simctl boot "$udid" 2>/dev/null || true
open -a Simulator --args -CurrentDeviceUDID "$udid"
xcrun simctl bootstatus "$udid" -b
xcrun simctl install "$udid" "$app"
xcrun simctl launch --terminate-running-process "$udid" "$bundle" "$@"
echo "Lanzada en el simulador $udid. Para ver el registro: xcrun simctl spawn $udid log stream --predicate 'process == \"VenueNexa\"'"
