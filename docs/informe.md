# Informe de la PoC iOS (PV1-T11)

> Cada afirmación es un **hecho comprobado**, una **inferencia** marcada o **«no verificado»**. Estado a 2026-10-16.

## 1. Estado
- **No verificado:** que algún código de este repo compile. No hay Swift, Xcode ni macOS en la máquina de desarrollo.
- **No verificado:** que pasen las pruebas de `Packages/Core` y `Packages/DesignSystem`; se ejecutan con `bash tools/test-all.sh`
  en el Codespace y en el job `linux-tests` del CI.
- **No verificado:** nada de `Packages/AppleKit` ni de la app raíz (SwiftUI, AppAuth, Keychain, Nuke, AVPlayer): ni compila ni
  se probó. Sus pruebas (`FeatureTests`, `CoreAppleTests`) corren en el simulador de iOS en el job `macos-build`.
- **No verificado:** SwiftLint, los nombres de esquema (`AppleKit-Package`, `VenueNexaApp`), el simulador elegido por el CI y
  que `xtool` acepte el formato de `Package.swift` y `xtool.yml`.
- **Verificado en esta máquina (Python):** `tools/check-strings.py` (paridad EN/ES, marcadores y claves usadas; falla cuando
  debe, probado con una clave inexistente) y `tools/capture-hosts.py` (probado con capturas de ejemplo: pasa sin `litix.io` y
  falla con `litix.io` y con un host no aprobado).
- **Revisión estática propia:** ningún `import` sin su dependencia declarada y ninguna línea de más de 120 caracteres
  (script puntual, no sustituye al compilador ni a SwiftLint).

## 1b. Defecto encontrado al escribir las pruebas
`BackgroundBlockTransport.blockURL` releía la SAS con `queryItems`, que decodifica `%2B` y lo reescribe como `+`; Azure lee `+`
como espacio y la firma fallaría (403). Corregido con `percentEncodedQueryItems` y con prueba. **No verificado contra Azure.**
Conviene comprobar si la subida de Android tiene el mismo problema.

## 1c. Piezas escritas sin pantalla de prueba
SSE (`SSEClient` + `SSEURLSessionTransport`), subida por bloques (`BackgroundBlockTransport`) y App Attest
(`AppAttestService`): lógica con pruebas de nivel A, adaptadores sin ejercitar. Faltan endpoints y que Andy decida el disparador.

## 2. Hechos medidos
- Contraste de la paleta (WCAG, calculado a partir de los valores hexadecimales): en modo claro, texto principal 16,8:1 y
  atenuado 6,7:1; en modo oscuro propuesto, 16,8:1 y 9,1:1. Todos los pares de texto de ambos modos pasan 4,5:1. Los bordes
  (1,2:1 claro y 1,7:1 oscuro) son decorativos y no cumplen 3:1: los campos de entrada necesitarán un borde más fuerte.
- Versión de Swift consultada en swift.org el 2026-10-16: 6.4.1 (Xcode 27.0), usada en el Codespace y en el job de Linux.

## 3. Puntos críticos (ADR-IOS) y dónde se prueban
Ver `docs/plan.md`. Cada condición tiene su prueba de nivel A, B o C; los resultados se anotan aquí al ejecutarlas.
