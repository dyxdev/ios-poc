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
