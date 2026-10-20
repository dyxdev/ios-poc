# Informe de la PoC iOS (PV1-T11)

> Estado a **2026-10-20**. Cada afirmación es un **hecho comprobado** (con su fuente), una **inferencia** marcada o **«no verificado»**.
> Repo: `dyxdev/ios-poc` (rama `main`). Plan y decisiones: `docs/plan.md`.

## 1. Resumen
**Qué es:** una PoC de iOS equivalente a la de Android (`poc-android-mux`) con los criterios de los ADR de iOS: Inicio, Detalle con vídeo,
Cuenta, bienvenida, cambio de contexto (cliente, propietario, administración), consentimiento por persona, login con Keycloak
(AppAuth), Keychain, limpieza al cerrar sesión, claro y oscuro, EN/ES; más las piezas críticas de los ADR de iOS (SSE, subida por
bloques, App Attest, universal links, evaluación de capturas de red).

**Qué se comprobó de verdad (fuente: 4 runs del CI de GitHub Actions y revisión de capturas):**
- El núcleo de Swift puro (Core y DesignSystem, ~100 pruebas) compila y pasa en **Linux y en macOS**.
- Las pruebas de AppleKit (modelos de las features, adaptador OIDC con servidor falso, subida por bloques) compilan y pasan en el **simulador de iOS**.
- La app completa **compila para el simulador, se instala, se lanza** y sus pantallas se ven en claro, oscuro y español (capturas).
- SwiftLint 0.65.1 sale limpio (no se comprobó la regla propia que exige SourceKit).
- En un **Mac de Andy con Xcode 27.0**, los paquetes del proyecto generado se resuelven por terminal (Nuke 13.2.0, AppAuth 3.0.0).

**Qué NO se comprobó:** nada en un iPhone real (nivel C); el login contra Keycloak; SSE, subida por bloques y App Attest contra servicios
reales; la captura de red del vídeo; el workflow `ipa-sin-firmar`; `xtool`; y las capturas de los runs 3 y 4 (no revisadas).

**Cambio de regla posterior al diseño:** el 2026-10-19 Andy decidió (PV1-T74) que iOS usa **Mux Player si hay consentimiento y AVPlayer
propio si no** (ADR-IOS-0029). **La PoC implementa solo la regla anterior** (siempre AVPlayer propio): ver §7, fila 0029.

## 2. Qué se construyó
- `Packages/Core` (Swift puro, 11 módulos con pruebas con Swift Testing): modelo y datos de ejemplo, consentimiento, identidad (actor con
  renovación serializada), contextos y capacidades simuladas, limpieza de sesión en un solo punto, reintentos, SSE con reconexión,
  subida por bloques, política de App Attest, URL de vídeo y evaluación de hosts, universal links.
- `Packages/DesignSystem`: tokens de diseño (paleta clara y oscura con el contraste medido).
- `Packages/AppleKit` (solo Apple): SwiftUI de cada pantalla con su modelo, adaptadores del SDK (Keychain, AppAuth, URLSession en
  segundo plano, App Attest, SSE, Nuke) y el catálogo de textos EN/ES.
- App raíz (`Sources/VenueNexaApp`, `project.yml` de XcodeGen): solo compone lo anterior.
- Herramientas: `tools/test-all.sh`, `check-strings.py`, `capture-hosts.py`, `ci-summary.py`, Keycloak de pruebas, scripts de simulador.
- CI: `linux-tests` (nivel A), `macos-build` (nivel B), `app-screenshots` (capturas y `app-simulador`), y el workflow manual `ipa-sin-firmar`.

## 3. Resultados verificados
### 3.1 Los runs del CI
| Run | Fecha · commit | Resultado | Causa y arreglo |
|---|---|---|---|
| 1 | 2026-10-16 · `9b7e7f2` | Linux ✘ · macOS: Core y DesignSystem ✔, AppleKit ✘ | Sin logs (exigen autenticación): se añadió `ci-summary.py` |
| 2 | 2026-10-19 · `4dd90f2` | `app-screenshots` ✔ · Linux ✘ · AppleKit ✘ · SwiftLint ✘ | Moneda en Linux (2 decimales mínimos por defecto en swift-corelibs); un `#expect` de mi prueba; 44 avisos de SwiftLint |
| 3 | 2026-10-19 · `8576552` | Linux ✔ · SwiftLint ✔ · `app-screenshots` ✔ · pruebas de `OIDCBackend` ✘ | Error de mi prueba: el servidor falso registraba el descubrimiento en la ruta equivocada |
| 4 | 2026-10-20 · `bc0c5f9` | **Los 3 jobs ✔** | — |

### 3.2 Xcode en el Mac de Andy (2026-10-20)
Al abrir `VenueNexa.xcodeproj` salió «Missing package product» en los 16 productos. Por terminal, `xcodebuild -resolvePackageDependencies`
resolvió los 5 paquetes sin error (Xcode 27.0, build 27A266a), así que era un estado atrasado de Xcode, no un fallo del proyecto. Falta
que Andy confirme cómo se ve la app corriendo en el simulador de su Mac.

### 3.3 Capturas del run 2 (20, revisadas por el agente el 2026-10-19)
Inicio, Detalle, Cuenta, Propietario, Admin y Diagnóstico se ven bien en claro y oscuro; el español y el formato de moneda son correctos.
**Defectos hallados y corregidos en el código** (comprobar en las capturas de los runs 3 y 4):
1. La bienvenida se salía de la pantalla por ambos lados: `scaledToFill` suelto ensanchaba el diseño (ahora `Color.clear` + `.clipped()`).
2. Diagnóstico mostraba dos flechas de «volver»: se oculta la barra de navegación.
3. En Detalle la barra de pestañas tapaba la de reservar: se oculta en esa pantalla.
4. El globo de aviso de perfiles salía recortado: mide lo que necesita su texto.
5. `-VNSignedIn 1` no dejaba sesión. **Hipótesis, no comprobada:** compilar sin firma quita los derechos y el Keychain falla en el simulador;
   el job de capturas firma ahora ad hoc.
6. `owner-en-light` salió en blanco y `owner-en-dark` bien: parece un fallo puntual de arranque, **sin explicación comprobada**.
Observación (no es defecto): la barra de pestañas flota sobre el contenido (estilo iOS nuevo).

### 3.4 Hechos medidos
- Contraste (WCAG, calculado de los hexadecimales): modo claro, texto 16,8:1 y atenuado 6,7:1; oscuro propuesto, 16,8:1 y 9,1:1. Todos los
  pares de texto pasan 4,5:1. Los bordes (1,2:1 claro y 1,7:1 oscuro) no cumplen 3:1: los campos de entrada necesitarán un borde más fuerte.
- Swift 6.4.1 = Xcode 27.0 (swift.org, consultado el 2026-10-16). Nuke 13.2.0 y AppAuth-iOS 3.0.0 resuelven (Mac de Andy y CI).
- Herramientas Python probadas aquí: `check-strings.py` (falla cuando debe) y `capture-hosts.py` (pasa sin `litix.io`, falla con él).

## 4. Defectos que la PoC encontró (y que valen para los ADR)
- **SAS reescrita:** `BackgroundBlockTransport.blockURL` releía la SAS con `queryItems`, que decodifica `%2B` y lo reescribe como `+`; Azure lo lee
  como espacio (403). Corregido con `percentEncodedQueryItems` y prueba. **No verificado contra Azure.** Android no tiene subida en su PoC.
- **Moneda en Linux:** el formateador de moneda de swift-corelibs conserva 2 decimales mínimos si solo se limita el máximo. Pasa en macOS.
- **SwiftLint:** la regla `file_name` pide más que «un tipo principal por archivo»; se quitó. Reglas por defecto como `trailing_comma` obligan a elegir estilo.
- **Keychain sin firma:** en el simulador, una app sin firma puede no tener derechos de Keychain (hipótesis de §3.3).

## 5. No verificado / pendiente
- Todo el **nivel C** (iPhone real): `docs/nivel-c.md`. Login real, Keychain con el teléfono bloqueado, App Attest, push, universal links.
- SSE, subida por bloques y App Attest: lógica probada en nivel A, **adaptadores sin ejercitar**; ninguna pantalla los dispara.
- Captura de red del vídeo (`docs/procedimiento-capturas.md`): su caso B («consentimiento encendido») cambió con la regla del 2026-10-19.
- `ipa-sin-firmar` y la firma e instalación en un iPhone; `xtool`; `tools/run-in-simulator.sh` en un Mac.
- Capturas de los runs 3 y 4; aprobación de la paleta oscura por Andy.

## 6. Decisiones de Andy (2026-10-16 salvo indicación)
iOS 17 mínimo · modo oscuro soportado en todo (paleta propuesta, pendiente de su aprobación) · Outfit con Dynamic Type · inglés por defecto ·
consentimiento por persona que se retira al cerrar sesión (paridad con ADR-AND-0033) · cliente Keycloak `venuenexa-ios` · ATS sin excepciones ·
`FreshInstallGuard` opción A (se borra el Keychain tras instalar) · verificación con el runner de macOS (xtool queda abierto) ·
2026-10-19: reproductor de iOS según el consentimiento (Mux Player con consentimiento, AVPlayer propio sin él).

## 7. Cruce con los ADR de iOS (materia prima de la propuesta de ADR)
> «Decidido» = lo eligió Andy; «medido» = salió de una medición o fuente citada; «inferencia» = lo dedujo el agente; «no verificado» = sin comprobar.
> Los detalles técnicos (archivos, versiones) van a la bitácora, no al ADR.

| ADR de iOS | Hallazgo | Tipo | Qué falta |
|---|---|---|---|
| 0007 Autenticación | El Keychain sobrevive a la desinstalación. Decidido: en el primer arranque tras instalar se borra (`FreshInstallGuard`, opción A, Andy 2026-10-16). Ningún ADR lo trata | Decidido | Escribirlo en el ADR; probarlo en iPhone real (C3) |
| 0007 Autenticación | Emisor `http` por IP: **Decidido por Andy (2026-10-20, aceptando la recomendación del agente): iOS no lo admite por ahora** (Android sí, solo en debug); ATS sin excepciones y pruebas contra un Keycloak por HTTPS | Decidido | Reabrir si hace falta |
| 0007 Autenticación | Redirección de login con esquema propio (`com.venuenexa.pocios:/oauth2redirect`): según la revisión INT-08 del 2026-10-16, ADR-VN-0007 v1.5 no admite esquemas propios y pediría un universal link; hueco compartido con Android | Inferencia (sin releer el ADR-VN) | Confirmar contra ADR-VN-0007 v1.5 |
| 0007 Autenticación | Cierre SSO: la app abre `end_session` en `ASWebAuthenticationSession` con `post_logout_redirect_uri` igual a la redirección de login; el cliente de Keycloak debe tenerla registrada también como URI de cierre | Inferencia | Verificar contra un Keycloak real |
| 0009 Subidas | Una SAS no se debe releer ni reescribir con `URLComponents.queryItems`: decodifica `%2B` y lo reescribe como `+`, que Azure lee como espacio (403). Se corrigió con `percentEncodedQueryItems` y una prueba | Medido en código; contra Azure **no verificado** | Anotar la regla en el ADR (también para Android y web) |
| 0009 Subidas | Con la app muerta y un bloque en vuelo, el resultado se pierde y el bloque se repite al reanudar; los registrados no se repiten | Inferencia (de la documentación de `URLSession`) | Probar en iPhone real (C4) |
| 0008 App Attest | La PoC solo firma aserciones; la **atestación** (el desafío del servidor) no existe: una aserción sin clave atestiguada la rechazaría un servidor real | Medido (por lo que hay en el código) | Definir con backend el desafío; el simulador no soporta App Attest |
| 0028 Tiempo real (SSE) | `URLSession.AsyncBytes.lines` no entrega las líneas vacías, que son el separador de eventos; hace falta un decodificador propio, que se prueba en nivel A | Inferencia (de lo conocido de `AsyncBytes.lines`); **no verificado** en ejecución | Anotarlo; probar con un servidor real |
| 0029 Mux | **Corrección (2026-10-20):** el 2026-10-19 Andy decidió que iOS usa Mux Player si hay consentimiento y AVPlayer propio si no, con aviso, parada y reinicio desde cero al retirarlo. **La PoC solo implementa AVPlayer propio** (la regla del 2026-10-13): no hay Mux Player ni Mux Data en ella. Por tanto la PoC prueba el camino «sin consentimiento» (debe dar 0 peticiones a `*.litix.io`); el camino «con consentimiento» (debe enviar a Mux Data) y el cambio en caliente **no están probados** | Decidido (Andy 2026-10-19) / PoC sin implementar | Implementar el Mux Player condicionado en la PoC o probarlo en la app real; ejecutar `docs/procedimiento-capturas.md` |
| 0014 / 0026 Analítica | Consentimiento de la persona (paridad con ADR-AND-0033): denegado por defecto, se retira al cerrar sesión; gobierna PostHog y Crashlytics | Decidido (Andy 2026-10-16) | Reflejarlo en los ADR |
| 0012 Sistema de diseño | Modo oscuro soportado en todo y paleta oscura propuesta; contraste de texto 16,8:1 y 9,1:1 (oscuro) y 16,8:1 y 6,7:1 (claro). Los bordes (1,2:1 claro, 1,7:1 oscuro) no cumplen 3:1: los campos de entrada necesitan un borde más fuerte | Decidido (modo oscuro) y medido (contrastes) | Aprobar la paleta oscura con capturas reales |
| 0012 Sistema de diseño | Tipografía Outfit empaquetada (SIL OFL) con Dynamic Type por `relativeTo`; `Font.custom("Outfit")` con fuente variable | Decidido; el comportamiento **no verificado** | Probar en simulador y iPhone |
| 0011 i18n | Inglés por defecto y ES; catálogo único `Localizable.xcstrings` con script de paridad (`tools/check-strings.py`) | Decidido; el script se probó | Que el catálogo llegue al paquete: **no verificado** |
| 0001 / 0005 | iOS 17 como mínimo (decidido por Andy 2026-10-16). Swift 6.4.1 = Xcode 27.0 (swift.org, consultado 2026-10-16) | Decidido / medido | Compilación en Swift 6 estricto: **no verificado** |
| 0002 Arquitectura | Los módulos `CoreData`, `CoreMedia` y `CoreSecurity` chocaban con frameworks de Apple: se llaman `CoreVenues`, `CorePlayback` y `CoreAttest`. Las features de AppleKit llevan modelo (Swift puro) y vista en el mismo paquete | Decidido por el agente | Convención de nombres a recoger en el ADR |
| 0016 Convenciones | SwiftLint estricto sale limpio en la PoC. La regla `file_name` exige más que «un tipo principal por archivo» y se quitó; el force unwrap se permite solo en pruebas con una configuración por carpeta. **Decidido por Andy (2026-10-20, aceptando la recomendación del agente):** se sigue la configuración por defecto de SwiftLint (sin coma final). **No verificado:** la regla propia contra `print`/`NSLog`, que exige SourceKit | Decidido / no verificado | Decidir si «un tipo principal por archivo» necesita una regla propia |
| 0003 Navegación | Universal links: se ignoran los prefijos `/en` y `/es` y los IDs se validan; faltan `apple-app-site-association` y dominios asociados | Medido (lógica de nivel A) | Probar en iPhone (C6) |
| 0015 / 0021 Pruebas y árbitros | Verificación por niveles: A Linux (`swift test` de Swift puro), B macOS (simulador y SwiftLint), C iPhone real (`docs/nivel-c.md`); Linux no puede compilar SwiftUI ni el SDK de Apple | Medido (límite de plataforma) | Registrar el reparto en los ADR; falta ejecutar A y B |
| 0025 Build y distribución | `xtool` (xtool-org/xtool) como alternativa al runner de macOS: no se pudo leer su guía; exige un `Xcode.xip` y su licencia es dudosa fuera de Apple (opinión de terceros); un Codespace no tiene USB para instalar en un iPhone | No verificado | Andy decide runner o xtool; leer la guía oficial en un navegador |
