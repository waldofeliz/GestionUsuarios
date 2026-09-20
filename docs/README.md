# Documentación — Gestión de usuarios

Índice para quien desarrolla o opera la demo en macOS. El lector de producto cotidiano empieza por el [README de la raíz](../README.md).

**Stack:** Swift 5 / SwiftUI / macOS 27. **No** hay base de datos, CI ni linter en el repo.

## Usuario y operación

| Documento | Contenido |
|-----------|-----------|
| [README del proyecto](../README.md) | Qué es, requisitos, abrir/build/run, login demo, Inicio / Usuarios / logout, tests |
| [CHANGELOG.md](../CHANGELOG.md) | Keep a Changelog: Unreleased y 1.0.0 (2026-09-20) |
| [Runbook local](runbook-local.md) | Prerrequisitos, ejecución, tests, rollback (no hay producción) |
| [Capturas](capturas/README.md) | Nombres fijos de PNG y receta para generarlas |

## Decisiones de arquitectura (ADR)

No copies estos archivos al README: son la fuente de verdad de diseño.

| ADR | Decisión |
|-----|----------|
| [ADR-001 Clean Architecture y usuarios](adr/ADR-001-clean-architecture-usuarios.md) | Capas Domain / Data / Presentation; JSONPlaceholder; overlay de sesión; sandbox |
| [ADR-002 Auth demo y shell](adr/ADR-002-autenticacion-demo-y-shell.md) | Login local, sesión RAM, un `WindowGroup`, Inicio \| Usuarios, logout compuesto |
| [ADR-003 Dashboard y Swift Charts](adr/ADR-003-dashboard-graficos.md) | KPI y gráficos nativos en Inicio; agregación en Domain; enmienda del contrato de datos de ADR-002 |

## UX y accesibilidad

| Documento | Contenido |
|-----------|-----------|
| [Design system](ux/design-system-usuarios.md) | Tokens teal, contraste AA, qué está prohibido (web/MixPro) |
| [Navegación CRUD](ux/navegacion-usuarios.md) | IA lista/detalle, menú, atajos, identifiers `lista.*` / `form.*` |
| [Login, Inicio y logout](ux/login-home-logout.md) | Gate de sesión, shell, copy CRED-*, identifiers `login.*` |
| [Panel admin Inicio](ux/admin-dashboard.md) | KPI, Charts, sidebar; enmienda visual de Inicio |

G10 de accesibilidad en estas specs: `CONDITIONAL` hasta evidencia de Accessibility Inspector (`degraded: revisión manual WCAG`).

## Seguridad

| Documento | Contenido |
|-----------|-----------|
| [Threat model — usuarios / HTTP](security/threat-model-usuarios.md) | Superficie JSONPlaceholder, sandbox, overlay |
| [Threat model — auth demo](security/threat-model-auth-demo.md) | Login local, copy «Entorno de demostración», residual de demo |

No documentes aquí algoritmos ni constantes criptográficas del verificador.

## Producto (PM)

| Documento | Contenido |
|-----------|-----------|
| [Alcance admin dashboard](pm/alcance-admin-dashboard.md) | Epic, MoSCoW, stories y AC del rediseño Inicio + GitHub |

## Comandos rápidos

```bash
xcodebuild -scheme GestionUsuarios -destination 'platform=macOS' build
xcodebuild test -scheme GestionUsuarios -destination 'platform=macOS' -only-testing:GestionUsuariosTests
```

Detalle operativo: [runbook-local.md](runbook-local.md).
