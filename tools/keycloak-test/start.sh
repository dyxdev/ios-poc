#!/bin/bash
# Keycloak de PRUEBAS para el PoC de iOS, dentro de un Codespace y con el puerto 8080 público
# para que el móvil llegue a él. Solo datos de prueba. Ver docs/plan.md (apartado Keycloak de pruebas).
# Binarios, datos y credenciales quedan fuera del repo (por defecto en ~/keycloak-test).
#
# Google (opcional): si GOOGLE_CLIENT_ID y GOOGLE_CLIENT_SECRET están definidos (secretos del
# Codespace), se crea el proveedor «google» en el realm. Se puede repetir el script con el
# servidor ya en marcha para aplicarlo después.
set -euo pipefail

# Consultado el 2026-10-15. Keycloak 26.8.1 exige JDK 25 (keycloak.org/getting-started/getting-started-zip);
# el Codespace trae JDK 17 para Gradle, así que Keycloak usa su propio JDK 25 sin tocar el de Gradle.
KEYCLOAK_VERSION="26.8.1"
JDK_URL="https://github.com/adoptium/temurin25-binaries/releases/download/jdk-25.0.4.1%2B1/OpenJDK25U-jdk_x64_linux_hotspot_25.0.4.1_1.tar.gz"
JDK_SHA256="dbb698396d478e7fa2b1e50f4103324b2a99b90569ee27c33f2261f9215cf41e"
REALM="venuenexa"
CLIENT_ID="venuenexa-ios"
PORT=8080

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="${KEYCLOAK_TEST_HOME:-$HOME/keycloak-test}"
KC="$WORK/keycloak-$KEYCLOAK_VERSION"
JDK="$WORK/jdk25"
CREDS="$WORK/credentials.txt"
PIDFILE="$WORK/keycloak.pid"
LOG="$WORK/keycloak.log"
KCADM_CONFIG="$WORK/kcadm.config"

if [ -z "${CODESPACE_NAME:-}" ] || [ -z "${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-}" ]; then
  echo "Esto solo funciona dentro de un Codespace (faltan CODESPACE_NAME y GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN)." >&2
  exit 1
fi
PUBLIC_URL="https://${CODESPACE_NAME}-${PORT}.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
GOOGLE_REDIRECT_URI="$PUBLIC_URL/realms/$REALM/broker/google/endpoint"
google_configured=0

kcadm() {
  JAVA_HOME="$JDK" "$KC/bin/kcadm.sh" "$@" --config "$KCADM_CONFIG"
}

kcadm_login() {
  kcadm config credentials --server "http://localhost:$PORT" --realm master \
    --user "$ADMIN_USER" --password "$ADMIN_PASSWORD" > /dev/null 2>&1
}

# Crea o actualiza el proveedor de Google. El secreto va en un archivo temporal (600), no en la línea de comandos.
configure_google() {
  local file="$WORK/google-idp.json"
  (
    umask 077
    printf '{"alias":"google","providerId":"google","enabled":true,"config":{"clientId":"%s","clientSecret":"%s","useJwksUrl":"true"}}\n' \
      "$GOOGLE_CLIENT_ID" "$GOOGLE_CLIENT_SECRET" > "$file"
  )
  local ok=0
  if kcadm get identity-provider/instances/google -r "$REALM" > /dev/null 2>&1; then
    kcadm update identity-provider/instances/google -r "$REALM" -f "$file" > /dev/null 2>&1 && ok=1
  else
    kcadm create identity-provider/instances -r "$REALM" -f "$file" > /dev/null 2>&1 && ok=1
  fi
  rm -f "$file"
  if [ "$ok" -eq 1 ]; then
    google_configured=1
    echo "Proveedor de Google configurado en el realm."
  else
    echo "AVISO: no se pudo configurar Google. Hazlo en /admin: Identity providers > Google." >&2
  fi
}

apply_google_if_set() {
  if [ -n "${GOOGLE_CLIENT_ID:-}" ] && [ -n "${GOOGLE_CLIENT_SECRET:-}" ]; then
    configure_google
  fi
}

summary() {
  echo
  echo "Keycloak de pruebas en marcha."
  echo "  Emisor:   $PUBLIC_URL/realms/$REALM"
  echo "  Cliente:  $CLIENT_ID (público, PKCE S256)"
  echo "  Usuario de pruebas: demo; las contraseñas (demo y admin) están en $CREDS"
  echo "  Consola de administración: $PUBLIC_URL/admin"
  if [ "$google_configured" -eq 1 ]; then
    echo "  Google:   configurado. URI de redirección registrada en Google Cloud: $GOOGLE_REDIRECT_URI"
  else
    echo "  Google:   sin configurar. Define los secretos GOOGLE_CLIENT_ID y GOOGLE_CLIENT_SECRET del Codespace,"
    echo "            registra en Google Cloud esta URI de redirección y repite este script:"
    echo "            $GOOGLE_REDIRECT_URI"
  fi
  echo
  echo "Apunta la app a él (en la raíz del repo; no subas ese cambio de Info.plist):"
  echo "  bash tools/set-issuer.sh $PUBLIC_URL/realms/$REALM"
  echo "Con Xcode también vale la variable de entorno VN_KEYCLOAK_ISSUER en el esquema de ejecución."
  echo "Para pararlo: bash tools/keycloak-test/stop.sh"
}

if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  echo "Ya hay un Keycloak de pruebas en marcha (pid $(cat "$PIDFILE"))."
  # shellcheck disable=SC1090
  . "$CREDS"
  if kcadm_login; then
    apply_google_if_set
  else
    echo "AVISO: no se pudo iniciar sesión en la administración; no se aplica Google." >&2
  fi
  summary
  exit 0
fi

if ss -ltn 2>/dev/null | grep -q ":$PORT "; then
  echo "El puerto $PORT ya está ocupado y no hay un Keycloak de pruebas registrado (¿un arranque anterior sin parar?)." >&2
  echo "  Mira quién escucha: ss -ltnp | grep :$PORT   y páralo con: bash tools/keycloak-test/stop.sh" >&2
  exit 1
fi

mkdir -p "$WORK"
cd "$WORK"

if [ ! -x "$JDK/bin/java" ]; then
  echo "Descargando JDK 25 (Temurin)..."
  curl -fsSL -o jdk25.tar.gz "$JDK_URL"
  echo "$JDK_SHA256  jdk25.tar.gz" | sha256sum -c -
  mkdir -p "$JDK"
  tar -xzf jdk25.tar.gz -C "$JDK" --strip-components=1
  rm jdk25.tar.gz
fi

if [ ! -d "$KC" ]; then
  echo "Descargando Keycloak $KEYCLOAK_VERSION..."
  base="https://github.com/keycloak/keycloak/releases/download/$KEYCLOAK_VERSION"
  curl -fsSL -o keycloak.zip "$base/keycloak-$KEYCLOAK_VERSION.zip"
  expected="$(curl -fsSL "$base/keycloak-$KEYCLOAK_VERSION.zip.sha1" | cut -d' ' -f1)"
  echo "$expected  keycloak.zip" | sha1sum -c -
  unzip -q keycloak.zip
  rm keycloak.zip
fi

# Contraseñas aleatorias, solo en este archivo (permisos 600), nunca en el repo.
if [ ! -f "$CREDS" ]; then
  random() { head -c "$1" /dev/urandom | od -An -tx1 | tr -d ' \n'; }
  (
    umask 077
    {
      echo "ADMIN_USER=admin"
      echo "ADMIN_PASSWORD=$(random 18)"
      echo "DEMO_USER=demo"
      echo "DEMO_PASSWORD=$(random 12)"
    } > "$CREDS"
  )
fi
# shellcheck disable=SC1090
. "$CREDS"

mkdir -p "$KC/data/import"
cp "$HERE/realm-venuenexa.json" "$KC/data/import/"

# --http-host=0.0.0.0: en modo desarrollo Keycloak escucha solo en 127.0.0.1. Se añadió por hipótesis ante el 502 del
# 2026-10-15, pero lo que lo resolvió fue poner el puerto en protocolo HTTP y en Public (ver docs/plan.md (apartado Keycloak de pruebas));
# no se comprobó que haga falta. Dentro del Codespace solo se llega por su reenvío.
echo "Arrancando Keycloak (la primera vez tarda un par de minutos)..."
KC_BOOTSTRAP_ADMIN_USERNAME="$ADMIN_USER" KC_BOOTSTRAP_ADMIN_PASSWORD="$ADMIN_PASSWORD" JAVA_HOME="$JDK" \
  nohup "$KC/bin/kc.sh" start-dev \
  --http-port="$PORT" \
  --http-host=0.0.0.0 \
  --hostname="$PUBLIC_URL" \
  --proxy-headers=xforwarded \
  --import-realm \
  > "$LOG" 2>&1 &
echo $! > "$PIDFILE"

ready=0
for _ in $(seq 1 90); do
  if curl -fs "http://localhost:$PORT/realms/$REALM/.well-known/openid-configuration" > /dev/null; then
    ready=1
    break
  fi
  if ! kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    echo "Keycloak se detuvo al arrancar. Últimas líneas de $LOG:" >&2
    tail -n 20 "$LOG" >&2
    exit 1
  fi
  sleep 2
done
if [ "$ready" -ne 1 ]; then
  echo "Keycloak no respondió en 3 minutos. Revisa $LOG" >&2
  exit 1
fi

if kcadm_login; then
  # La contraseña del usuario de pruebas se pone aquí y no en el JSON, para no dejarla en el repo.
  if kcadm set-password -r "$REALM" --username "$DEMO_USER" --new-password "$DEMO_PASSWORD" > /dev/null 2>&1; then
    echo "Contraseña del usuario demo establecida."
  else
    echo "AVISO: no se pudo poner la contraseña de demo. En /admin: Users > demo > Credentials > Set password (sin Temporary)." >&2
  fi
  apply_google_if_set
else
  echo "AVISO: no se pudo iniciar sesión en la administración con kcadm; ni la contraseña de demo ni Google se aplicaron." >&2
  echo "  Hazlo en /admin con las credenciales de $CREDS." >&2
fi

if command -v gh > /dev/null 2>&1 && gh codespace ports visibility "$PORT:public" -c "$CODESPACE_NAME" > /dev/null 2>&1; then
  echo "Puerto $PORT puesto en público."
else
  echo "AVISO: el script no pudo poner el puerto $PORT en público (suele pasar si Codespaces aún no lo reenvía). A mano:" >&2
  echo "  1. Panel inferior > pestaña PORTS (Ctrl+Shift+P > «Ports: Focus on Ports View»)." >&2
  echo "  2. Si no aparece el $PORT: «Forward a Port» > $PORT." >&2
  echo "  3. Clic derecho en $PORT > Port Visibility > Public." >&2
  echo "  4. Clic derecho en $PORT > Change Port Protocol > HTTP (Keycloak sirve HTTP; la URL pública sigue siendo https)." >&2
fi

summary
