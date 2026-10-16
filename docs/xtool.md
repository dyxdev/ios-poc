# xtool (alternativa al runner de macOS) — SIN VERIFICAR

Andy dejó abierto (2026-10-16) verificar con el runner de macOS **o** con `xtool` «como se montó lo de Android». `xtool` es el
proyecto `xtool-org/xtool` (MIT; no es nuestro). **No se ha instalado ni probado** y no se ha escrito un script de instalación
porque no se pudo leer la guía oficial (el sitio xtool.sh no entrega su contenido sin navegador). Lo único comprobado el
2026-10-16 en el README del repo: es multiplataforma (Linux, WSL, macOS), sus subcomandos incluyen `setup`, `new`, `dev`,
`devices`, `install`, `uninstall` y `launch`, y las guías de instalación están en
`https://xtool.sh/documentation/xtooldocs/installation-linux`.

Lo que el repo ya trae para él (formato tomado de fuentes de terceros, no comprobado): `Package.swift` raíz con el producto
`.library` `VenueNexaApp`, `xtool.yml` (`version`, `bundleID`, `product`, `infoPath`) e `Info.plist`.

Riesgos ya conocidos (de fuentes de terceros, sin verificar): exige un `Xcode.xip` de Apple que hay que descargar con una
cuenta de desarrollador; su licencia podría no permitir usar el SDK fuera de equipos Apple; con cuenta gratuita hay límites
(pocas apps y perfiles de 7 días); instalar en un iPhone exige conectarlo por USB a la máquina que ejecuta `xtool`, y un
Codespace no tiene USB. Por eso no sustituye al runner de macOS para la verificación: sirve, como mucho, para compilar.

Antes de seguir por esta vía: leer la guía oficial en un navegador y decidir (Andy) si el coste compensa.
