# Procedimiento: captura de red con mitmproxy en un iPhone (lo ejecuta Andy)

PoC: `poc-ios`. Condición de ADR-IOS-0029: **0 peticiones a `*.litix.io`** y ningún host fuera de los aprobados. **Aviso (2026-10-20):**
esta guía se escribió con la regla del 2026-10-13 (iOS siempre con AVPlayer propio, sin Mux Data). El 2026-10-19 Andy decidió que iOS usa
**Mux Player si hay consentimiento y AVPlayer propio si no** (ADR-IOS-0029). La PoC solo implementa AVPlayer propio: **hoy solo vale el
caso A**; los casos B y C esperan envíos a Mux Data con la regla nueva y no se pueden medir en la PoC hasta que implemente el Mux Player.

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
| B · consentimiento encendido | Igual con «Analítica» encendida | **Con la regla del 2026-10-19: deben verse envíos a Mux Data.** La PoC no los genera (solo AVPlayer propio): no medible hoy |
| C · cambio en caliente | Retirar el consentimiento a mitad de reproducción | Aviso, parada, AVPlayer propio y 0 peticiones a `*.litix.io` desde ese momento (ADR-IOS-0029). No medible en la PoC hoy |
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
