# Instalar la PoC en un iPhone real (sin Mac)

**Estado: sin verificar.** El workflow `ipa-sin-firmar` y los pasos de firma no se han ejecutado todavía. Las herramientas de firma
de abajo son candidatas que **no se han usado ni comprobado**.

## 1. Obtener el .ipa (sin firmar)
1. En GitHub: **Actions → ipa-sin-firmar → Run workflow**, rama `main`.
2. Opciones:
   - `configuration`: **Debug** (recomendado en la PoC: trae Diagnóstico y el simulador de capacidades; Release no los trae).
   - `keycloak_issuer`: `https://<host>/realms/<realm>` si quieres iniciar sesión; vacío = la app arranca como invitado.
     Solo HTTPS (ATS sin excepciones). El cliente `venuenexa-ios` debe tener registrada `com.venuenexa.pocios:/oauth2redirect`.
3. Al terminar, abre el run y baja el artefacto **ipa-sin-firmar** (zip con `VenueNexa-unsigned.ipa`). Se conserva 14 días.

## 2. Preparar el iPhone
- iOS 17 o superior (mínimo de la PoC).
- Activa el **Modo desarrollador**: Ajustes → Privacidad y seguridad → Modo desarrollador (pide reiniciar).
- Conéctalo por USB a tu ordenador y acepta «Confiar en este ordenador».

## 3. Firmar e instalar con tu Apple ID
Un `.ipa` sin firmar no se instala tal cual: una herramienta lo firma con tu Apple ID (cuenta gratuita sirve) y lo instala.
Candidatas, sin verificar: Sideloadly (Windows y macOS), AltStore con AltServer (Windows y macOS), y en Linux herramientas de la
comunidad como Plume Impactor o AltServer-Linux, o `xtool`. Elige una y sigue su guía.
- Estas herramientas piden la contraseña de tu Apple ID: valora usar un Apple ID secundario. Es decisión tuya.
- Tras instalar: Ajustes → General → VPN y gestión de dispositivos → confía en tu perfil de desarrollador.

## 4. Límites de la cuenta gratuita (de fuentes de terceros, sin verificar)
- La firma caduca a los 7 días (hay que volver a firmar) y hay un máximo de apps instaladas a la vez.
- App Attest, universal links (dominios asociados) y notificaciones push necesitan una cuenta de pago: esas pruebas (nivel C
  de `docs/nivel-c.md`) no funcionarán así.
- La herramienta puede cambiar el identificador de la app (`com.venuenexa.pocios`); el esquema de redirección de Keycloak no
  depende de él.

## 5. Qué probar primero
1. La app abre y muestra la bienvenida, luego Inicio con fotos (necesita internet).
2. Detalle de un espacio con vídeo (tour) y corazón de guardados.
3. Cuenta → Diagnóstico (solo en Debug): simulador de perfiles y evidencia de red.
4. Con emisor configurado: iniciar y cerrar sesión; cerrar sesión debe vaciar guardados, perfil y consentimiento.
5. Claro y oscuro, texto grande (Dynamic Type) y VoiceOver: anota lo que se vea mal.
