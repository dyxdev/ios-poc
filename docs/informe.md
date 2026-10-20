# Informe de la PoC iOS (PV1-T11)

> Cada afirmación es un **hecho comprobado**, una **inferencia** marcada o **«no verificado»**. Estado a 2026-10-16.

## 1. Estado
- **Primer run del CI (2026-10-16, commit `9b7e7f2`, run 1; estado leído de la API pública de GitHub el 2026-10-19):**
  en macOS **pasaron** las pruebas de Core y DesignSystem (paso «Paquetes de Swift puro en macOS»: Swift 6 estricto compila esa
  parte y sus pruebas pasan). **Fallaron:** el job de Linux (`swift test`, salida 1) y las pruebas de AppleKit en el simulador
  (`xcodebuild`, salida 65; SwiftLint y la compilación de la app no llegaron a ejecutarse). Los logs exigen autenticación, así
  que el motivo **no se conoce todavía**; `tools/ci-summary.py` deja los errores como anotaciones públicas para el run 2.
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

- **No verificado:** `project.yml` (XcodeGen), su combinación con `Info.plist` (`GENERATE_INFOPLIST_FILE` junto a `INFOPLIST_FILE`), el
  job `app-screenshots`, `tools/pick-simulator.sh` (probado solo con datos de ejemplo: elige el iPhone del iOS más nuevo) y
  `tools/ci-screenshots.sh` (solo la sintaxis).

- **Segundo run del CI (2026-10-19, commit `4dd90f2`, run 2; anotaciones públicas):**
  - **Pasó `app-screenshots`:** el proyecto XcodeGen genera la app, compila para el simulador, se instala, se lanza y sale el
    artefacto `capturas` (~21 MB, 19 imágenes). El paso de capturas tarda unos 10 minutos. **Las capturas aún no se han
    revisado.**
  - **Falló Linux por un defecto real de portabilidad:** `Formatters.price` fijaba solo `maximumFractionDigits = 0`; en Linux
    (swift-corelibs) el estilo de moneda conserva 2 decimales mínimos y salía «1.450,00 €». Corregido fijando también el mínimo.
    Lo detectó la prueba `priceHasNoDecimalsAndTheEuroSign`; en macOS pasaba.
  - **Falló la compilación de las pruebas de AppleKit** (`FeatureTests`): `error: call can throw, but it is not marked with 'try'`
    dentro de la expansión de un `#expect` de `HomeAndDetailModelTests`. Causa no confirmada (sospecha: la línea con
    `allSatisfy(\.isFeatured)` o con `DemoVenues.all.count`); las líneas se reescribieron fuera del macro. **Los módulos de
    AppleKit (fuentes) sí compilaron:** el error es solo de la prueba.
  - **Falló SwiftLint (44 avisos):** coma final, nombres cortos, `String(decoding:)`, `class` en una clase final. Se corrigió con
    `swiftlint --fix` y a mano; con SwiftLint 0.65.1 (binario de Linux, sin SourceKit) ahora sale 0. **No verificado:** la regla
    propia `no_print_or_nslog` y otras que exigen SourceKit.

- **No verificado:** el workflow `ipa-sin-firmar` (compilación para dispositivo sin firmar y empaquetado del `.ipa`) y la
  instalación en un iPhone real (`docs/instalar-en-iphone.md`); ninguna herramienta de firma se ha probado.

- **Revisión de las 20 capturas del run 2 (2026-10-19, Andy las descargó):** Inicio, Detalle, Cuenta, Propietario, Admin y
  Diagnóstico se ven bien en claro y oscuro (la paleta oscura se ve coherente; **pendiente de su aprobación**), y el español
  funciona (textos y formato `1450 € / día`). **Defectos hallados y corregidos en el código (sin verificar en un run nuevo):**
  1. La bienvenida se salía de la pantalla por ambos lados: `scaledToFill` suelto ensanchaba el diseño. `VenueImage` va ahora
     en un `Color.clear` con `.clipped()`.
  2. Diagnóstico mostraba dos flechas de «volver» (la del sistema y la propia): se oculta la barra de navegación.
  3. En Detalle la barra de pestañas tapaba la barra de reservar: se oculta la barra de pestañas.
  4. El globo de aviso de perfiles salía recortado por arriba: mide ahora lo que necesita su texto.
  5. `-VNSignedIn 1` no dejaba la sesión (salía «Guest»). **Hipótesis, no comprobada:** compilar sin firma (`CODE_SIGNING_ALLOWED=NO`)
     quita los derechos de la app y el Keychain falla en el simulador; el job de capturas firma ahora ad hoc.
  6. La captura `owner-en-light` salió en blanco (pantalla de arranque) y `owner-en-dark` bien: parece un fallo puntual de
     tiempo de arranque, **sin explicación comprobada**. Si se repite, se subirá la espera (`SCREENSHOT_WAIT`).
  Observación (no es un defecto): la barra de pestañas flota sobre el contenido (estilo iOS nuevo) y cubre el final del scroll.

- **Tercer run del CI (2026-10-19, commit `8576552`):** **pasaron** `linux-tests` (la moneda en Linux quedó bien), `app-screenshots`
  (capturas nuevas) y SwiftLint 0.65.1 en macOS. **Las pruebas de AppleKit ya compilan y se ejecutan** en el simulador; fallan
  las de `OIDCBackend` (`.network` en todas) por un error de MI prueba: el servidor falso registraba el descubrimiento en
  `/.well-known/openid-configuration` y la app lo pide bajo `/realms/test/`. Corregido; **sin verificar en un run nuevo**. Pueden
  quedar fallos de otras pruebas de AppleKit que el resumen de anotaciones no mostró (se limita a 45 líneas).

- **Cuarto run del CI (2026-10-20, commit `bc0c5f9`): los 3 jobs pasan** (`linux-tests`, `macos-build` y `app-screenshots`).
  Medido: pruebas de Core y DesignSystem en Linux y macOS; pruebas de AppleKit en el simulador de iOS; SwiftLint 0.65.1; la app
  compila para el simulador, se instala y se lanza; artefacto `capturas` de ~22 MB. **Sigue sin verificar:** las capturas de este
  run (no revisadas), el workflow `ipa-sin-firmar` (manual, no ejecutado) y todo el nivel C (iPhone real).

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

## 4. Hallazgos para los ADR de iOS (materia prima: los ADR se escriben después, con Andy)
> Estado a 2026-10-16. «Decidido» = lo eligió Andy (con fecha); «medido» = salió de una medición o de la fuente citada;
> «inferencia» = lo dedujo el agente; «no verificado» = sin comprobar. Esta tabla no cambia ningún ADR: solo recoge qué hay que
> decidir o anotar en cada uno. Los detalles técnicos (archivos, versiones) irán a la bitácora, no al ADR.

| ADR de iOS | Hallazgo | Tipo | Qué falta |
|---|---|---|---|
| 0007 Autenticación | El Keychain sobrevive a la desinstalación. Decidido: en el primer arranque tras instalar se borra (`FreshInstallGuard`, opción A, Andy 2026-10-16). Ningún ADR lo trata | Decidido | Escribirlo en el ADR; probarlo en iPhone real (C3) |
| 0007 Autenticación | Emisor `http` por IP en la red local: en Android Andy lo aceptó solo en debug (2026-10-16). En iOS el ADR-IOS-0004 dice ATS sin excepciones | Pendiente | Andy decide si iOS lo admite y cómo (p. ej. `NSAllowsLocalNetworking`); no se comprobó cómo se comporta AppAuth-iOS con un emisor `http` |
| 0007 Autenticación | Cierre SSO: la app abre `end_session` en `ASWebAuthenticationSession` con `post_logout_redirect_uri` igual a la redirección de login; el cliente de Keycloak debe tenerla registrada también como URI de cierre | Inferencia | Verificar contra un Keycloak real |
| 0009 Subidas | Una SAS no se debe releer ni reescribir con `URLComponents.queryItems`: decodifica `%2B` y lo reescribe como `+`, que Azure lee como espacio (403). Se corrigió con `percentEncodedQueryItems` y una prueba | Medido en código; contra Azure **no verificado** | Anotar la regla en el ADR (también para Android y web) |
| 0009 Subidas | Con la app muerta y un bloque en vuelo, el resultado se pierde y el bloque se repite al reanudar; los registrados no se repiten | Inferencia (de la documentación de `URLSession`) | Probar en iPhone real (C4) |
| 0008 App Attest | La PoC solo firma aserciones; la **atestación** (el desafío del servidor) no existe: una aserción sin clave atestiguada la rechazaría un servidor real | Medido (por lo que hay en el código) | Definir con backend el desafío; el simulador no soporta App Attest |
| 0028 Tiempo real (SSE) | `URLSession.AsyncBytes.lines` no entrega las líneas vacías, que son el separador de eventos; hace falta un decodificador propio, que se prueba en nivel A | Inferencia (de lo conocido de `AsyncBytes.lines`); **no verificado** en ejecución | Anotarlo; probar con un servidor real |
| 0029 Mux | En iOS no hay Mux Data (el vídeo es AVPlayer con la URL HLS): el consentimiento no cambia lo enviado, así que la captura de red se hace con consentimiento apagado y encendido y debe dar 0 peticiones a `*.litix.io` en ambos casos | Decidido en el diseño; sin medir | Ejecutar `docs/procedimiento-capturas.md` |
| 0014 / 0026 Analítica | Consentimiento de la persona (paridad con ADR-AND-0033): denegado por defecto, se retira al cerrar sesión; gobierna PostHog y Crashlytics | Decidido (Andy 2026-10-16) | Reflejarlo en los ADR |
| 0012 Sistema de diseño | Modo oscuro soportado en todo y paleta oscura propuesta; contraste de texto 16,8:1 y 9,1:1 (oscuro) y 16,8:1 y 6,7:1 (claro). Los bordes (1,2:1 claro, 1,7:1 oscuro) no cumplen 3:1: los campos de entrada necesitan un borde más fuerte | Decidido (modo oscuro) y medido (contrastes) | Aprobar la paleta oscura con capturas reales |
| 0012 Sistema de diseño | Tipografía Outfit empaquetada (SIL OFL) con Dynamic Type por `relativeTo`; `Font.custom("Outfit")` con fuente variable | Decidido; el comportamiento **no verificado** | Probar en simulador y iPhone |
| 0011 i18n | Inglés por defecto y ES; catálogo único `Localizable.xcstrings` con script de paridad (`tools/check-strings.py`) | Decidido; el script se probó | Que el catálogo llegue al paquete: **no verificado** |
| 0001 / 0005 | iOS 17 como mínimo (decidido por Andy 2026-10-16). Swift 6.4.1 = Xcode 27.0 (swift.org, consultado 2026-10-16) | Decidido / medido | Compilación en Swift 6 estricto: **no verificado** |
| 0002 Arquitectura | Los módulos `CoreData`, `CoreMedia` y `CoreSecurity` chocaban con frameworks de Apple: se llaman `CoreVenues`, `CorePlayback` y `CoreAttest`. Las features de AppleKit llevan modelo (Swift puro) y vista en el mismo paquete | Decidido por el agente | Convención de nombres a recoger en el ADR |
| 0016 Convenciones | La regla `file_name` de SwiftLint exige que el nombre del archivo coincida con un tipo, más que «un tipo principal por archivo»; se quitó y se revisa a mano. El force unwrap se permite en pruebas (ADR) con un `.swiftlint.yml` por carpeta `Tests` | Decidido por el agente; SwiftLint **no verificado** | Decidir si hace falta una regla que haga cumplir «un tipo principal por archivo» |
| 0003 Navegación | Universal links: se ignoran los prefijos `/en` y `/es` y los IDs se validan; faltan `apple-app-site-association` y dominios asociados | Medido (lógica de nivel A) | Probar en iPhone (C6) |
| 0015 / 0021 Pruebas y árbitros | Verificación por niveles: A Linux (`swift test` de Swift puro), B macOS (simulador y SwiftLint), C iPhone real (`docs/nivel-c.md`); Linux no puede compilar SwiftUI ni el SDK de Apple | Medido (límite de plataforma) | Registrar el reparto en los ADR; falta ejecutar A y B |
| 0025 Build y distribución | `xtool` (xtool-org/xtool) como alternativa al runner de macOS: no se pudo leer su guía; exige un `Xcode.xip` y su licencia es dudosa fuera de Apple (opinión de terceros); un Codespace no tiene USB para instalar en un iPhone | No verificado | Andy decide runner o xtool; leer la guía oficial en un navegador |
