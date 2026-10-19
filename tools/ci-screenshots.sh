#!/usr/bin/env bash
# Instala la app en el simulador y saca una captura de cada pantalla, en claro y oscuro (y en español algunas).
# Uso: bash tools/ci-screenshots.sh <UDID> <ruta/a/VenueNexa.app> <carpeta-de-salida>
# Solo macOS. Usa los argumentos de lanzamiento de debug (-VNScreen, -VNSignedIn; ver LaunchOverrides.swift).
# Sin verificar: espera fija de carga (las fotos vienen de internet) y que `simctl io screenshot` funcione en el runner.
set -euo pipefail
udid="$1"; app="$2"; out="$3"
bundle="com.venuenexa.pocios"
wait_seconds="${SCREENSHOT_WAIT:-9}"
mkdir -p "$out"

xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" -b
xcrun simctl install "$udid" "$app"

shot() { # nombre idioma apariencia argumentos...
  local name="$1" lang="$2" appearance="$3"; shift 3
  xcrun simctl ui "$udid" appearance "$appearance"
  xcrun simctl launch --terminate-running-process "$udid" "$bundle" \
    -AppleLanguages "($lang)" -AppleLocale "${lang}_$( [ "$lang" = es ] && echo ES || echo US )" "$@" > /dev/null
  sleep "$wait_seconds"
  xcrun simctl io "$udid" screenshot "$out/$name-$lang-$appearance.png" > /dev/null
  echo "captura: $name-$lang-$appearance"
}

for appearance in light dark; do
  shot welcome     en "$appearance" -VNScreen welcome
  shot home        en "$appearance" -VNScreen home
  shot detail      en "$appearance" -VNScreen detail
  shot account     en "$appearance" -VNScreen account
  shot account-in  en "$appearance" -VNScreen account -VNSignedIn 1
  shot owner       en "$appearance" -VNScreen owner
  shot admin       en "$appearance" -VNScreen admin
  shot diagnostics en "$appearance" -VNScreen diagnostics
done
for screen in welcome home detail account; do
  shot "$screen" es light -VNScreen "$screen"
done
xcrun simctl terminate "$udid" "$bundle" 2>/dev/null || true
ls -1 "$out"
