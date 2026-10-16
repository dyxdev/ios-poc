# Pruebas de nivel C (iPhone real) — lista para Andy

Lo que ningún simulador ni CI demuestra. Cada fila se marca con fecha, dispositivo e iOS al ejecutarla.

| # | Prueba | Cómo | Condición | ADR |
|---|---|---|---|---|
| C1 | App Attest | `AppAttestService` existe y se prueba la política en nivel A, pero ninguna pantalla lo invoca aún: falta decidir con Andy el disparador | Genera aserción; en simulador `isSupported` es falso y la cabecera se omite | IOS-0008 |
| C2 | Keychain con teléfono bloqueado | Iniciar sesión, bloquear, esperar una renovación en segundo plano | Lee el token tras el primer desbloqueo; sin sesión perdida | IOS-0007 |
| C3 | Reinstalar | Iniciar sesión, borrar la app, reinstalar | No queda sesión (`FreshInstallGuard`; decisión del agente a confirmar) | IOS-0007 |
| C4 | Subida en segundo plano | Subir un archivo grande y pasar la app a segundo plano | Los bloques siguen; los registrados no se repiten | IOS-0009 |
| C5 | Cierre SSO | Cerrar sesión desde Cuenta | Se abre el navegador del sistema, vuelve a la app y Keycloak pide credenciales al volver a entrar | IOS-0007 |
| C6 | Universal links | Abrir `https://<dominio>/venues/<id>` desde Notas | Abre el detalle (necesita `apple-app-site-association` y dominios asociados, aún no hechos) | IOS-0003 |
| C7 | Dynamic Type y VoiceOver | Mayor tamaño de texto; VoiceOver en Inicio, Detalle y Cuenta | Sin recortes; orden y etiquetas correctos | IOS-0012 |
| C8 | Modo oscuro | Claro y oscuro en todas las pantallas | Capturas para aprobar la paleta oscura | IOS-0012 |
| C9 | Push | Registro y baja del token al cerrar sesión | Pendiente: no hay servicio de push en la PoC | IOS-0010 |

Estado a 2026-10-16: **ninguna ejecutada**. C1, C4, C6 y C9 necesitan además piezas que la PoC aún no tiene (marcado en
`informe.md`).
