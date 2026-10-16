# Procedimiento: captura de red con mitmproxy en un iPhone (lo ejecuta Andy)

PoC: `poc-ios`. Condición de ADR-IOS-0029: **0 peticiones a `*.litix.io`** y ningún host fuera de los aprobados. En iOS no
hay Mux Data (el vídeo es AVPlayer con la URL HLS de Mux), así que el consentimiento no cambia lo que se envía: se mide
con el consentimiento apagado **y** encendido para comprobar que da igual.

## 1. Preparar
1. En tu máquina: `mitmweb --listen-port 8080` o `mitmdump -w captura-<caso>.flows`.
2. iPhone: Wi-Fi → proxy manual → IP de tu máquina, puerto 8080. Abre `http://mitm.it` y descarga el perfil de la CA.
3. Instala el perfil (Ajustes → General → VPN y gestión de dispositivos) y **actívalo** en Ajustes → General → Información →
   Ajustes de confianza de certificados. Sin este último paso el tráfico HTTPS falla.
4. No verificado: aislamiento de clientes del router, VPN activas y que AVPlayer respete el proxy del sistema.

## 2. Casos
| Caso | Pasos | Condición |
|---|---|---|
| A · consentimiento apagado | Cuenta → «Analítica» apagada (por defecto). Detalle de un espacio con tour → reproducir ≥ 30 s, pausa, seek, repetir | 0 peticiones a `*.litix.io`; solo hosts aprobados |
| B · consentimiento encendido | Igual con «Analítica» encendida | Igual que A (en iOS no hay Mux Data) |
| C · cambio en caliente | Encender y apagar a mitad de reproducción | Sigue en 0 |
| D · ciclo de vida | Segundo plano y volver; cerrar y reabrir | Sigue en 0 |
| E · cierre de sesión | Con sesión iniciada: cerrar sesión; mirar el tráfico del cierre SSO y comprobar que no queda ninguna petición con el token | Solo el host de Keycloak, sin tokens en la URL salvo `id_token_hint` del cierre |

## 3. Resumir y evaluar
```bash
mitmdump -nr captura-A.flows --flow-detail 1 | python3 tools/capture-hosts.py --approve <host-de-keycloak>
```
Imprime host y número de peticiones, marca con `NO` los no permitidos y devuelve distinto de 0 si hay alguno. Solo lee métodos
y hosts: no guarda rutas ni cuerpos. También se puede pegar la lista de hosts en Cuenta → Diagnóstico → «Evidencia de red»
(solo en compilaciones de desarrollo): usa la misma lógica (`NetworkEvidence`, con pruebas de nivel A).

Anota en `docs/informe.md` el resultado de cada caso con la fecha, sin cuerpos ni tokens.
