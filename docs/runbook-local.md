# Runbook: Gestión de usuarios (local)

## Resumen

Operación de la app **en el Mac de desarrollo**. No hay servidor propio, App Store, staging ni producción. El único “despliegue” es clonar y ejecutar el binario; el remoto GitHub es el archivo de código.

- **Servicio:** app macOS `GestionUsuarios` (scheme homónimo).
- **Datos:** `https://jsonplaceholder.typicode.com` (público) + overlay RAM.
- **Auth:** demo local. Copy de producto: **Entorno de demostración**.

## Prerrequisitos (accesos, tools)

| Ítem | Detalle |
|------|---------|
| macOS | 27.0 o superior (`MACOSX_DEPLOYMENT_TARGET = 27.0`) |
| Xcode | 27+ con herramientas de línea de comandos (`xcode-select -p` apunta al Xcode) |
| Red | Salida HTTPS al host JSONPlaceholder (el sandbox de la app incluye cliente de red) |
| Git | Origen `https://github.com/waldofeliz/GestionUsuarios.git` |
| Secretos | Ninguno. No hay `.env`. La contraseña demo solo se documenta en el README de desarrollo |

Comprobar herramientas:

```bash
sw_vers
xcodebuild -version
xcode-select -p
git remote -v
```

## Procedimiento paso a paso

### 1. Obtener el código

```bash
git clone https://github.com/waldofeliz/GestionUsuarios.git
cd GestionUsuarios
git checkout main
git pull
```

Si ya tienes el clone: `git status` limpio antes de construir, salvo que estés en un cambio local consciente.

### 2. Abrir en Xcode

```bash
open GestionUsuarios.xcodeproj
```

Scheme **GestionUsuarios**, destino **My Mac**. Product → Run (`⌘R`).

Si el scheme no aparece para `xcodebuild`, abre el proyecto una vez en el IDE.

### 3. Compilar por CLI

Desde la raíz del repositorio:

```bash
xcodebuild -scheme GestionUsuarios -destination 'platform=macOS' build
```

Éxito: `** BUILD SUCCEEDED **`. Fallo habitual: SDK/destino iOS, o Xcode no seleccionado (`sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` si aplica en tu máquina).

### 4. Usar la demo

1. Login: usuario `waldofeliz`, contraseña la documentada en el README raíz (**Entorno de demostración — no es producción**).
2. Inicio carga el listado (necesita red).
3. Usuarios: lista/detalle/CRUD de sesión.
4. Cuenta → Cerrar sesión, o el botón de toolbar.

No copies el `.app` de DerivedData a `/Applications` como si fuera un release; no hay canal de distribución.

## Verificación (health checks / comandos)

| Qué | Comando o comprobación |
|-----|------------------------|
| Compilación | `xcodebuild -scheme GestionUsuarios -destination 'platform=macOS' build` → `BUILD SUCCEEDED` |
| Tests de lógica | `xcodebuild test -scheme GestionUsuarios -destination 'platform=macOS' -only-testing:GestionUsuariosTests` → `TEST SUCCEEDED` |
| UI tests (opcional) | `xcodebuild test -scheme GestionUsuarios -destination 'platform=macOS' -only-testing:GestionUsuariosUITests` |
| Login | Arranque → **Entorno de demostración** visible → entra a Inicio |
| Red | Con Wi-Fi/Ethernet; un fallo muestra *No se pudo cargar* / KPI *No disponible*, no un crash |
| Lint | No hay linter en el repo — no hay comando |
| CI | No detectado — no hay pipeline que consultar |

Smoke funcional mínimo: login → KPI con números (o *No disponible* si el API cae) → Usuarios → una fila de detalle → Cerrar sesión → login otra vez.

## Rollback

**No hay producción que revertir.** No hay `kubectl`, App Store Connect ni flags remotos.

| Situación | Acción |
|-----------|--------|
| El `main` remoto rompe el build local | `git fetch origin` y `git log origin/main -5`. Revertir el commit malo en una rama o, en el clone local: `git revert <sha>` (crea un commit inverso; no uses `reset --hard` en `main` publicado salvo acuerdo explícito) |
| Quieres el árbol del primer 1.0.0 | `git checkout 1a24734` (detached HEAD; solo para inspeccionar). Volver: `git checkout main` |
| Cambios locales no commitados | `git status`; descartar archivos concretos con `git checkout -- <path>` si estás seguro. No borrar el repo |
| App en ejecución “rara” | Salir (`⌘Q`) y Run de nuevo. La sesión y el overlay mueren con el proceso |
| JSONPlaceholder caído | Esperar o trabajar contra tests unitarios (no pegan a red). No hay failover propio |

Tras un revert, vuelve a ejecutar el comando de **build** y el de **GestionUsuariosTests**.

## Alertas y escalamiento

No hay dashboards, on-call ni SLO.

| Síntoma | Qué hacer |
|---------|-----------|
| Login rechaza `waldofeliz` + clave demo | Confirmar copy **Entorno de demostración**; no pegar espacios en la contraseña; esperar el lockout si hubo muchos fallos |
| Lista vacía / error de red | Comprobar red y que el sandbox no se haya modificado; probar `curl -I https://jsonplaceholder.typicode.com/users` en Terminal |
| Charts planos (una barra por categoría) | Esperado con n≈10; no es una alerta |
| Duda de arquitectura | ADR en [README de docs](README.md); no inventar HTTP de login |

Escalado humano: dueño del repo GitHub `waldofeliz/GestionUsuarios`. No hay canal de incidentes.

## Referencias

- [README del proyecto](../README.md)
- [ADR-001](adr/ADR-001-clean-architecture-usuarios.md) · [ADR-002](adr/ADR-002-autenticacion-demo-y-shell.md) · [ADR-003](adr/ADR-003-dashboard-graficos.md)
- Threat models: [usuarios](security/threat-model-usuarios.md), [auth demo](security/threat-model-auth-demo.md)
