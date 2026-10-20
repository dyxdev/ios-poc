# Probar la app en el simulador de iOS

**Estado: sin verificar en un Mac.** El CI sí compila, instala y lanza la app en el simulador de un runner de GitHub (job
`app-screenshots`, medido), pero `tools/run-in-simulator.sh` y estos pasos no se han ejecutado en un Mac.

El simulador de iOS solo existe en **macOS con Xcode**. En Linux o Windows no hay emulador de iOS (ver «Sin Mac»).

## Opción A: con la app que construye el CI (Mac con Apple Silicon)
1. En GitHub: Actions → el último run de `ci` → artefacto **`app-simulador`** (`VenueNexa-simulator.zip`, 14 días). O con la CLI de
   GitHub: `gh run download <id-del-run> -n app-simulador -R dyxdev/ios-poc`.
2. Clona el repo (el script usa `tools/pick-simulator.sh`) y ejecuta:
   ```bash
   bash tools/run-in-simulator.sh ~/Downloads/VenueNexa-simulator.zip
   ```
   Abre el simulador de un iPhone del iOS más nuevo instalado, instala la app y la lanza.
3. Con argumentos de lanzamiento (solo Debug), por ejemplo directo a una pantalla o en español:
   ```bash
   bash tools/run-in-simulator.sh VenueNexa-simulator.zip -VNScreen detail
   bash tools/run-in-simulator.sh VenueNexa-simulator.zip -AppleLanguages "(es)" -AppleLocale es_ES
   ```
   Pantallas: `welcome`, `home`, `detail`, `account`, `diagnostics`, `owner`, `admin`; con `-VNSignedIn 1` simula una sesión.
- **Límite:** el CI compila para `arm64`. Un Mac con **Intel** no lo ejecuta: usa la opción B.

## Opción B: compilar en tu Mac (Apple Silicon o Intel)
```bash
brew install xcodegen
xcodegen generate                      # crea VenueNexa.xcodeproj (no se guarda en el repo)
open VenueNexa.xcodeproj               # y Run en un simulador de iPhone
```
Por terminal, sin abrir Xcode:
```bash
UDID=$(bash tools/pick-simulator.sh)
xcodebuild build -project VenueNexa.xcodeproj -scheme VenueNexa -configuration Debug \
  -destination "id=$UDID" -derivedDataPath build CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES
bash tools/run-in-simulator.sh build/Build/Products/Debug-iphonesimulator/VenueNexa.app
```

## Opción C: en GitHub Actions (sin tocar un Mac)
El job `app-screenshots` ya compila, instala y lanza la app en un simulador de un Mac de GitHub, y sube las capturas
(artefacto `capturas`). **No es interactivo.** Para ver otra pantalla o idioma hay que añadirla a `tools/ci-screenshots.sh`.

## Sin Mac
- **Simulador en la nube** (por ejemplo Appetize.io o BrowserStack): subes `VenueNexa-simulator.zip` y la usas desde el navegador.
  Sin verificar: si aceptan este zip, límites y precio del nivel gratuito.
- **iPhone real:** workflow manual `ipa-sin-firmar` y `docs/instalar-en-iphone.md`.
