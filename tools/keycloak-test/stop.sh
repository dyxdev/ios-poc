#!/bin/bash
# Para el Keycloak de pruebas y vuelve a poner el puerto en privado.
set -euo pipefail

PORT=8080
WORK="${KEYCLOAK_TEST_HOME:-$HOME/keycloak-test}"
PIDFILE="$WORK/keycloak.pid"

# El pidfile guarda el proceso lanzador (kc.sh); el java de Keycloak puede ser otro proceso (medido el
# 2026-10-15: quedó escuchando tras un stop). Se para el lanzador, sus hijos y cualquier java de Keycloak de este directorio.
stopped=0
if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  pkill -TERM -P "$(cat "$PIDFILE")" 2>/dev/null || true
  kill "$(cat "$PIDFILE")" 2>/dev/null || true
  stopped=1
fi
if pkill -TERM -f "$WORK/keycloak-.*/lib/quarkus-run.jar" 2>/dev/null; then
  stopped=1
fi
rm -f "$PIDFILE"

if [ "$stopped" -eq 1 ]; then
  for _ in $(seq 1 15); do
    ss -ltn 2>/dev/null | grep -q ":$PORT " || break
    sleep 1
  done
  if ss -ltn 2>/dev/null | grep -q ":$PORT "; then
    echo "AVISO: el puerto $PORT sigue ocupado; mira quién escucha con: ss -ltnp | grep :$PORT" >&2
  else
    echo "Keycloak parado."
  fi
else
  echo "No había un Keycloak de pruebas en marcha."
fi

if [ -n "${CODESPACE_NAME:-}" ] && command -v gh > /dev/null 2>&1 &&
  gh codespace ports visibility "$PORT:private" -c "$CODESPACE_NAME" > /dev/null 2>&1; then
  echo "Puerto $PORT vuelto a privado."
else
  echo "Comprueba en la pestaña PORTS que el puerto $PORT esté en privado." >&2
fi
