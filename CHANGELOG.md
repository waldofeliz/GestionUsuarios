# Changelog

Todos los cambios notables de este proyecto se documentan en este archivo.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es/1.1.0/), y el versionado el de la app (`MARKETING_VERSION` 1.0).

## [Unreleased]

### Añadido

- Documentación de usuario y desarrollo: README raíz, índice `docs/`, runbook local.
- Capturas reales en `docs/capturas/` (`01-login.png`, `02-inicio-dashboard.png`, `03-usuarios-lista-detalle.png`, `04-nuevo-usuario.png`).

## [1.0.0] - 2026-09-20

Primera entrega publicada en `main` (`https://github.com/waldofeliz/GestionUsuarios.git`).

### Añadido

- App macOS SwiftUI **Gestión de usuarios** (bundle `com.devapp.GestionUsuarios`, sandbox con red).
- Inicio de sesión de demostración local (usuario `waldofeliz`; copy **Entorno de demostración**). La clave no viaja a JSONPlaceholder ni se muestra en la UI.
- Shell autenticado: destinos **Inicio** y **Usuarios** en un `NavigationSplitView`; logout por toolbar y menú **Cuenta**.
- Panel Inicio: KPI (usuarios, ciudades, empresas, altas de sesión) y dos gráficos Swift Charts (área por ciudad, barras por empresa) sobre el listado real.
- CRUD de usuarios contra JSONPlaceholder (`GET/POST/PUT /users`) con overlay de sesión en memoria (el remoto no persiste escrituras).
- Lista, detalle (contacto / dirección / empresa), búsqueda, alta en hoja y edición in-place; menú y atajos `⌘N` `⌘S` `⌘E` `⌘I` `⌘R` `⌘F`.
- Tests unitarios (`GestionUsuariosTests`) y UI (`GestionUsuariosUITests`).
- Contratos de arquitectura, UX y seguridad en `docs/` (ADR-001, ADR-002, ADR-003 y threat models).

### Seguridad

- Auth demo: comparador local (no plaintext en el target de app), sesión volátil, lockout de intentos, App Sandbox. Residual aceptado: no es un IdP de producción.

[Unreleased]: https://github.com/waldofeliz/GestionUsuarios/compare/1a24734...HEAD
[1.0.0]: https://github.com/waldofeliz/GestionUsuarios/commit/1a24734
