# PoC iOS de VenueNexa (PV1-T11)

Equivalente de `poc-android-mux`, con los criterios de los ADR de iOS (`VenueNexa-ios/docs/adr/`, todos Propuestos).
**Nada de este código se ha compilado todavía**: no hay Swift, Xcode ni macOS en la máquina de desarrollo. Lo verifican el
Codespace (Linux, Swift puro) y el runner de macOS de GitHub Actions. Ver `docs/informe.md` para el estado exacto.

## Qué hay
- `Packages/Core`: lógica de Swift puro (modelo, datos de ejemplo, consentimiento, identidad, contextos y limpieza de sesión,
  red y SSE, subida por bloques, App Attest, URL de vídeo firmada, universal links) y sus pruebas con Swift Testing.
- `Packages/DesignSystem`: tokens de diseño (claro y oscuro con el contraste medido, espaciado, formas).
- `Packages/AppleKit` (**solo Apple**, no compila en Linux): SwiftUI (Inicio, Detalle con AVPlayer, Cuenta, bienvenida, hoja de
  perfiles, Propietario, Admin, Diagnóstico), adaptadores del SDK de Apple (Keychain, AppAuth, URLSession en segundo plano,
  App Attest, SSE, Nuke) y el catálogo de textos EN/ES (`AppStrings`).
- Raíz (`Package.swift`, `Sources/VenueNexaApp`, `Info.plist`, `xtool.yml`, `project.yml`): la app, que solo compone lo anterior.
  `project.yml` es la definición de XcodeGen (se genera `VenueNexa.xcodeproj`, que no se guarda) para obtener un `.app`.
- `tools/`: `test-all.sh` (pruebas + claves de texto), `check-strings.py`, `capture-hosts.py` (evidencia de red),
  `keycloak-test/` (Keycloak de pruebas en un Codespace, cliente `venuenexa-ios`), `set-issuer.sh`.
- `docs/`: `plan.md` (decisiones), `informe.md` (hechos y lo no verificado), `procedimiento-capturas.md`, `nivel-c.md`, `xtool.md`.

## Cómo se prueba
| Nivel | Dónde | Qué |
|---|---|---|
| A | Codespace (Linux) | `bash tools/test-all.sh` → `swift test` de Core y DesignSystem + claves de texto (AppleKit se omite) |
| B | GitHub Actions macOS | Job `macos-build`: `swift test` de Core y DesignSystem, pruebas de AppleKit en el simulador de iOS y SwiftLint. Job `app-screenshots`: compila la `.app`, la instala en el simulador y sube capturas de cada pantalla (claro, oscuro y algunas en español) como artefacto `capturas` |
| C | iPhone real | Ver `docs/nivel-c.md` |

## Identidad real (Keycloak de pruebas)
`bash tools/keycloak-test/start.sh` (en un Codespace) y después `bash tools/set-issuer.sh <emisor que imprime>`. Sin emisor la
app funciona como invitado y el login responde «no configurado». Todo va por HTTPS (ATS sin excepciones).

## Probar en el simulador
El CI sube la app del simulador (artefacto `app-simulador`). En un Mac: `bash tools/run-in-simulator.sh VenueNexa-simulator.zip`.
Todas las opciones (Mac, Actions, sin Mac) en `docs/probar-en-simulador.md` (sin verificar en un Mac).

## Instalar en un iPhone (sin Mac)
El workflow manual `ipa-sin-firmar` (Actions → Run workflow) genera un `.ipa` sin firmar como artefacto; se firma e instala con tu
Apple ID. Pasos y límites en `docs/instalar-en-iphone.md` (sin verificar).

## Capturas de pantalla (sin Mac)
Cada push ejecuta el job `app-screenshots`. Las capturas salen del artefacto `capturas` del run (pestaña Actions). Usan
argumentos de lanzamiento solo de debug (`-VNScreen`, `-VNSignedIn`; `Sources/VenueNexaApp/LaunchOverrides.swift`) y una sesión
**falsa** sin servidor; no existen en release. En un Mac: `xcodegen generate`, abrir `VenueNexa.xcodeproj` y ejecutar.

## Cómo usarla como referencia
Decisión de Andy (2026-10-20): lo que quede aquí se usa como referencia en la implementación del proyecto real. Contenido y estado de
cada parte en `docs/informe.md` (§3 a §5) y su cruce con los ADR en `docs/informe.md` (§7).
- **Reutilizable como referencia (probado en el CI):** `Packages/Core` (Swift puro, ~100 pruebas en Linux y macOS), `DesignSystem`,
  los adaptadores de `AppleKit` (Keychain, OIDC, subida por bloques con la regla de la SAS y SSE; Keychain y OIDC solo probados en
  simulador), la estructura de CI por niveles A, B y C y el script de paridad EN/ES.
- **Solo de PoC, no copiar a la app real:** las capacidades simuladas, `LaunchOverrides` y la sesión falsa, los datos de ejemplo, la
  pantalla de Diagnóstico y las pantallas de ejemplo de Propietario y Administración.
- **No verificado (no darlo por probado):** todo el nivel C (iPhone real, login con Keycloak, App Attest, push, subida en segundo
  plano, vídeo real); el reproductor según el consentimiento del 2026-10-19 (la PoC solo implementa la regla anterior).
