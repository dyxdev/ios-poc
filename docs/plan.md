# Plan de la PoC iOS de VenueNexa (PV1-T11)

Estado: **F0 a F4 escritas (F4 solo en parte), sin compilar ni probar** (2026-10-16). Decide Andy; lo no decidido consta como pendiente.

## Alcance (Andy, 2026-10-16)
Equivalente a la PoC de Android (Inicio, Detalle con vídeo, Cuenta, bienvenida, contextos y consentimiento), con los criterios
de los ADR de iOS, **más** los puntos críticos de los ADR-IOS: condiciones de ADR-IOS-0029 (0 peticiones a `*.litix.io`),
subida por bloques, SSE, App Attest, universal links, Keychain y limpieza al cerrar sesión. Lo que exige un dispositivo real
(App Attest real, Keychain con el teléfono bloqueado, push, subida en segundo plano) queda como lista de pruebas de nivel C.

## Decisiones de Andy (2026-10-16)
| Tema | Decisión |
|---|---|
| Dónde se compila y prueba | Runner de macOS de GitHub Actions **o** `xtool` en el Codespace, como el montaje de Android |
| Repo | Nuevo; lo crea Andy y después se configura el remoto |
| Alcance | El de arriba |
| Versión mínima de iOS | **17** (suelo de los ADR por Observation y SwiftData; ninguna dependencia aprobada choca) |
| Modo oscuro | Se soporta; paleta oscura **propuesta con contraste medido**, pendiente de su aprobación con capturas reales |
| Tipografía | Outfit propia con escalado de Dynamic Type |
| Idioma por defecto | El que dice el ADR de iOS: inglés (idioma del dispositivo) |
| Consentimiento | Paridad con ADR-AND-0033: de la persona, denegado por defecto, se retira al cerrar sesión; gobierna PostHog y Crashlytics |
| Keycloak | Cliente público `venuenexa-ios` en el Keycloak de pruebas del repo (se añade en F3) |
| Red en local | Todo por HTTPS, **sin** excepciones de ATS (ADR-IOS-0004) |

## Niveles de verificación
A Linux (Codespace): `swift test` de los paquetes de Swift puro. B macOS (runner o Mac): `swift test`, compilación para el
simulador de iOS, SwiftLint, capturas. C iPhone real.

## Fases
- **F0 Entorno y esqueleto (escrita):** repo, `.devcontainer` con Swift, CI con jobs de Linux y macOS, SwiftLint, scripts.
- **F1 Núcleo puro (escrita):** modelo y datos de ejemplo, filtros y formato, consentimiento, identidad (actor con renovación
  serializada), contextos y capacidades simuladas, limpieza de sesión, reintentos y `AppError`, parser SSE y cliente con
  reconexión, subida por bloques, política de App Attest, URL de vídeo firmada y evaluación de capturas de red, router de
  universal links, tokens de diseño. Pruebas con Swift Testing.
- **F2 App SwiftUI (escrita):** Inicio, Detalle con AVPlayer, Cuenta, bienvenida, hoja de perfiles, Propietario, Admin,
  Diagnóstico, claro y oscuro. **Pendiente:** capturas reales para aprobación (necesita macOS o `xtool`).
- **F3 Identidad real (escrita):** AppAuth, Keychain, cierre SSO y cliente `venuenexa-ios` en `tools/keycloak-test/`.
- **F4 Puntos críticos reales (en parte):** hecho el procedimiento de captura de red y la evaluación de hosts
  (`tools/capture-hosts.py`, Diagnóstico). **Sin pantalla de prueba:** SSE, subida por bloques y App Attest tienen adaptador y
  pruebas de lógica, pero ninguna pantalla los dispara (faltan endpoints y decisión de Andy).
- **F5 Informe y cruce con los ADR de iOS**, como en Android.

## Riesgos conocidos
- Nada se ha compilado: Swift 6 en modo estricto puede dar errores de concurrencia que solo se ven al compilar.
- `xtool`: no es una herramienta nuestra; exige un `Xcode.xip` de Apple y su licencia podría no permitir el SDK fuera de
  equipos Apple (opinión de usuarios, sin verificar); instalar en un iPhone exige un dispositivo conectado a la máquina que
  ejecuta `xtool`, que un Codespace no tiene. No sustituye al runner de macOS.
- `URLSession.AsyncBytes.lines` no entrega líneas vacías, imprescindibles en SSE: por eso hay un decodificador propio.
- Los nombres `CoreData`, `CoreMedia` y `CoreSecurity` chocaban con frameworks de Apple: los módulos se llaman
  `CoreVenues`, `CorePlayback` y `CoreAttest`.

## Keycloak de pruebas
`tools/keycloak-test/` es el del repo de Android con el cliente `venuenexa-ios` (público, PKCE S256, redirección
`com.venuenexa.pocios:/oauth2redirect`, que la app también usa como destino tras el cierre SSO). Mismo procedimiento: un
Codespace con el puerto 8080 público. No verificado desde iOS.

## Huecos decididos por el agente (a confirmar con Andy)
- `FreshInstallGuard`: se borra el Keychain en el primer arranque tras instalar (ningún ADR lo trata). Reversible.
- El Diagnóstico (simulador de capacidades y evidencia de red) solo existe en compilaciones de debug.
- La captura de red mide también con el consentimiento encendido, porque en iOS no hay Mux Data.
