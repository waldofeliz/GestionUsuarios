# ADR-003: Dashboard nativo (KPI + Swift Charts) en Inicio

## Status
Accepted

## Date
2026-09-19

## Context

`GestionUsuarios` ya implementa ADR-001 (Clean Architecture, CRUD JSONPlaceholder) y ADR-002 (auth demo + shell `Inicio` | `Usuarios` en un único `NavigationSplitView`). Post-login, `InicioVista` muestra un saludo, el **conteo** `usuarios.count` derivado en Presentation, y dos atajos. El listado llega por `ListarUsuariosCasoUso` (mismo overlay de sesión; n≈10 + altas RAM).

El producto pide ahora un **dashboard tipo admin**: KPIs y gráficos, dentro de la app macOS SwiftUI existente.

Restricciones duras (handoff EE-ARCH-20260919-4):

- Swift 5 / SwiftUI / macOS 27. Framework nativo **Swift Charts** (`import Charts`). **No** Bootstrap, **no** Chart.js, **no** WebView con plantilla MixPro.
- Métricas **reales** derivadas de `[Usuario]`. **Prohibido** métricas fake (crecimiento semanal, “usuarios activos”, series temporales inventadas, números aleatorios).
- Dataset: JSONPlaceholder + overlay de sesión. No hay timestamps de actividad, no hay eventos, no hay DBA.
- ADR-001: Domain sin SwiftUI ni HTTP; Presentation sin DTOs; Composition Root único; `nonisolated` + `Sendable` para datos que cruzan hilos.
- ADR-002: un `WindowGroup`; raíz condicional login/shell; **un** `NavigationSplitView` (no anidar, **no** `TabView`); Inicio **no** duplica cliente HTTP; logout compuesto intacto; gate `UsuarioRepositorioAutorizado` intacto.
- Design system / UX vigentes (`docs/ux/design-system-usuarios.md` §2, `docs/ux/login-home-logout.md`): prohíben **dashboard web** (grid 12 columnas, cards SaaS, MixPro). Eso **no** prohíbe Charts nativos ni tres KPIs derivados del dominio. Este ADR **enmienda** el contrato de datos de Inicio (conteo-en-Presentation y “no gráficos”); **no** tira el norte Mail/Contactos ni el split.
- Este ADR **no** prescribe Views/ViewModels de producción (igual que ADR-001/002).

Hoy el conteo vive en Presentation (`InicioVista` → `modelo.usuarios.usuarios.count`). Agrupar por ciudad/empresa en un ViewModel repetiría lógica no testeable sin SwiftUI y rompería el espíritu de ADR-001.

## Decision Drivers

- Agregaciones **testeables** en Domain (Swift Testing), sin red y sin `Charts`.
- Cero HTTP extra: ni endpoint nuevo, ni segundo cliente, ni DTO paralelo.
- Datos del gráfico `Sendable` para respetar MainActor por defecto (ADR-001).
- El split de ADR-002 sigue siendo el anfitrión; el “look admin” no puede copiar MixPro (sidebar negra fija) ni romper Dark Mode / Increase Contrast / `listStyle(.sidebar)`.
- KPIs honestos con n pequeño: tres números + dos distribuciones. No teatro de analytics.
- Incremental: no nuevo bounded context, no SPM, no DBA, no TabView.

## Considered Options

### A — Dónde viven las agregaciones

1. **Domain puro: value objects + caso de uso `ResumenUsuarios` sobre `[Usuario]`**. Cero repositorio, cero HTTP. Presentation sigue obteniendo la lista por `ListarUsuariosCasoUso` (ya cargada en el shell) y pide el resumen.
2. **Presentation (ViewModel) agrupa y cuenta.** Rápido; lógica de agrupación no se testea sin UI; contradice ADR-001 (“reglas en Domain”).
3. **`ResumenUsuariosCasoUso.ejecutar() async throws` que vuelve a `listar()`**. Encapsula bien, pero **duplica GET** `/users` respecto al `UsuariosVistaModelo` que el shell ya dispara en `.task`. ADR-002 ya toleró dos GET Inicio+Usuarios; un tercer listar es innecesario.

### B — Tecnología de gráficos

1. **Swift Charts** en Presentation (`BarMark` / `SectorMark`) sobre `PuntoGrafico`. SDK macOS 27; accesible; sin JS.
2. **`WKWebView` + plantilla MixPro / Chart.js.** Prohibido por producto y por superficie (HTML/JS, CSP, mix de design system web).
3. **Solo `Text` / barras CSS-like (`Rectangle` fraction).** Sin dependencia Charts; peor lectura de distribución y no cumple el pedido de charts.

### C — Shell / sidebar “admin”

1. **Conservar `NavigationSplitView` + sidebar nativa** (`List` `.sidebar`, material de sistema, `SeccionApp.inicio | .usuarios`). El dashboard **es el detalle de Inicio**.
2. **Sidebar oscura custom estilo admin** (fondo negro fijo, iconos tipo MixPro, marca “Admin”). Lucha con `colorScheme`, Increase Contrast y el design system teal; pinta chrome web en AppKit.
3. **`TabView` de secciones** o **tercer `SeccionApp.dashboard`**. TabView está prohibido (NAV / DS). Un tercer ítem duplica Inicio.

### D — Qué KPIs existen (honestidad del dataset)

1. **Solo derivados de `[Usuario]`**: total, ciudades distintas, empresas distintas, series por ciudad y por empresa.
2. **Inventar series temporales / “activos” / % crecimiento.** Mentira: la API no tiene fechas de uso.
3. **KPI “remotos vs sintéticos” (id ≥ 10_000).** Filtra un detalle de Data (overlay) en Domain; ADR-001 oculta el quirk en el decorator.

## Decision

**A1 + B1 + C1 + D1.**

| Tema | Elegido | Por qué | Descartado |
|------|---------|---------|------------|
| Agregación | **Domain `ResumenUsuarios` + `ResumenDashboard` / `PuntoGrafico`** | Testeable; sin HTTP extra; Presentation solo pinta | Agrupar en ViewModel; caso de uso que re-lista |
| Gráficos | **Swift Charts en Presentation** | Framework nativo; datos Sendable | WebView/Chart.js; barras ad hoc como único chart |
| Shell | **Mismo `NavigationSplitView`; Inicio = dashboard** | ADR-002 intacto; no TabView | Sidebar MixPro oscura; `SeccionApp` extra |
| KPIs | **Total + #ciudades + #empresas + 2 distribuciones** | Lo que el agregado `Usuario` sí tiene | Métricas fake; KPI de overlay |

No hay microservicios, no hay módulo SPM, no hay DBA, no hay Surface HTTP nueva.

**Enmienda a ADR-002 (Inicio — contrato de datos):**

- Sigue siendo obligatorio: Inicio consume la lista vía `ListarUsuariosCasoUso` (misma instancia del contenedor / mismo `UsuariosVistaModelo` ya cargado). **No** nuevo `ClienteHTTP`.
- Deja de ser válido: derivar el único KPI con `usuarios.count` **en Presentation** como regla de negocio. El total (y el resto) salen de `ResumenDashboard`.
- Deja de aplicar a Inicio la frase UX “No gráficos”. Los gráficos nativos son alcance de este ADR. Sigue prohibido el dashboard **web**.

ADR-002 permanece **Accepted** en auth, gate, logout, un solo split y raíz condicional.

### Bounded context

Sigue habiendo **un** BC de datos de negocio (`Usuarios`) y el BC `Autenticacion` de ADR-002. El dashboard **no** es un contexto nuevo: es una **proyección** de `[Usuario]`.

```
ListarUsuariosCasoUso.ejecutar()  →  [Usuario]     (HTTP + overlay + gate; ya existe)
ResumenUsuariosCasoUso.ejecutar(_:) → ResumenDashboard  (puro, sync, sin I/O)
Presentation (Charts)  ←  ResumenDashboard (Sendable)
```

Reglas de frontera:

- Domain **no** importa `SwiftUI` ni `Charts`.
- Data **no** cambia: cero DTO de “stats”, cero URL `/stats`.
- Autenticacion **no** participa (el GET ya exige sesión por el decorator).
- Presentation **no** recalcula agrupaciones; solo formatea copy y elige marcas de Chart.

### Capas

| Capa | Qué hace para el dashboard | Qué no hace |
|------|----------------------------|-------------|
| **Domain** | `PuntoGrafico`, `ResumenDashboard`, `ResumenUsuariosCasoUso` / `ResumenUsuariosServicio`; agrupación y conteos | Strings de UI; colores; `Chart`; HTTP |
| **Data** | Nada | Endpoints, caché, SQL |
| **Presentation** | Swift Charts + KPIs nativos en el **detalle de Inicio**; empty/error/loading reutilizando `ErrorUsuario` | Lógica de agrupación; WebView |
| **App** | Expone `resumenUsuarios` en `ContenedorDependencias`; misma construcción de repositorio | Service locator |

Dependencias: `Presentation → Domain ← Data`; `App → todas`. Igual ADR-001.

### Modelo de dominio (proyección)

Los tipos son **value objects inmutables**, `nonisolated`, `Sendable`. No son entidades con identidad de negocio; `PuntoGrafico.id` existe solo para `Identifiable` (Swift Charts / `ForEach`), no para persistencia.

| Tipo | Rol |
|------|-----|
| `ClaveAgrupacion` | Ciudad o empresa: `.valor(String)` tras trim, o `.ausente` si el campo queda vacío. Domain **no** pone copy (“Sin ciudad”) |
| `PuntoGrafico` | Una barra/sector: clave + `valor: Int` (≥ 0) |
| `ResumenDashboard` | Snapshot: totales + dos series |

Definiciones (normativas):

| Campo | Significado | Honestidad |
|-------|-------------|------------|
| `totalUsuarios` | `usuarios.count` | Incluye overlay de sesión (misma lista que el CRUD) |
| `ciudadesDistintas` | Número de `.valor` **distintos** en `direccion.ciudad` (trim, case-sensitive tal cual llega). **No** cuenta `.ausente` | No es “ciudades en el mundo”; es cardinalidad del dataset |
| `empresasDistintas` | Igual sobre `empresa.nombre` | Igual |
| `usuariosSinCiudad` / `usuariosSinEmpresa` | Conteos de `.ausente` | KPI auxiliar; 0 si todos tienen valor |
| `usuariosPorCiudad` / `usuariosPorEmpresa` | Un `PuntoGrafico` por clave observada, **incluida** `.ausente` solo si su conteo > 0 | Suma de `valor` = `totalUsuarios` |

**Prohibido en Domain (métricas fake):**

- Porcentaje de crecimiento, MAU/DAU, “activos”, “sesiones”, sparklines temporales.
- Fechas inventadas (`Date()` como eje X de actividad).
- Media de coordenadas / “mapa de calor” (geo existe pero no es KPI pedido; dejar fuera de este ciclo).
- Distinción id sintético vs 1…10 (eso es Data).

Lista vacía: `ResumenDashboard.vacio` (ceros, series vacías). No lanza.

### Contratos (protocols) — nombres Swift

Todos `nonisolated`, `Sendable`. No heredar el MainActor por defecto.

```swift
nonisolated enum ClaveAgrupacion: Sendable, Hashable, Equatable {
    case valor(String)
    case ausente
}

nonisolated struct PuntoGrafico: Identifiable, Sendable, Equatable {
    let id: ClaveAgrupacion
    let clave: ClaveAgrupacion
    let valor: Int

    init(clave: ClaveAgrupacion, valor: Int) {
        self.id = clave
        self.clave = clave
        self.valor = valor
    }
}

nonisolated struct ResumenDashboard: Sendable, Equatable {
    let totalUsuarios: Int
    let ciudadesDistintas: Int
    let empresasDistintas: Int
    let usuariosSinCiudad: Int
    let usuariosSinEmpresa: Int
    let usuariosPorCiudad: [PuntoGrafico]
    let usuariosPorEmpresa: [PuntoGrafico]

    static let vacio = ResumenDashboard(
        totalUsuarios: 0,
        ciudadesDistintas: 0,
        empresasDistintas: 0,
        usuariosSinCiudad: 0,
        usuariosSinEmpresa: 0,
        usuariosPorCiudad: [],
        usuariosPorEmpresa: []
    )
}

nonisolated protocol ResumenUsuariosCasoUso: Sendable {
    func ejecutar(_ usuarios: [Usuario]) -> ResumenDashboard
}
```

Implementación Domain (struct, `nonisolated`):

```swift
nonisolated struct ResumenUsuariosServicio: ResumenUsuariosCasoUso {
    func ejecutar(_ usuarios: [Usuario]) -> ResumenDashboard { /* puro */ }
}
```

Algoritmo (normativo para tests):

1. `totalUsuarios = usuarios.count`.
2. Normalizar ciudad: `direccion.ciudad.trimmingCharacters(in: .whitespacesAndNewlines)`; vacío → `.ausente`; si no → `.valor(texto)`.
3. Normalizar empresa: igual con `empresa.nombre`.
4. Agrupar con diccionario `[ClaveAgrupacion: Int]`; incrementar en 1 por usuario.
5. `ciudadesDistintas` = número de claves `.valor` (no `.ausente`). Igual `empresasDistintas`.
6. `usuariosSinCiudad` = conteo de `.ausente` (0 si la clave no aparece).
7. Series: mapear el diccionario a `[PuntoGrafico]`, **omitir** entradas con `valor == 0` (no deberían existir).
8. Orden de series (estable, para snapshots de test y para Charts): `valor` **descendente**; empate → `.ausente` al **final**; entre `.valor`, `String` lexicográfico ascendente.
9. Sin I/O, sin `MainActor`, sin aleatorio. Complejidad O(n) con n≈10 + overlay.

**No** crear `ContarUsuariosCasoUso`. El total vive en `ResumenDashboard`.

**No** añadir `ejecutar() async throws` que llame al repositorio. Eso sería HTTP extra respecto a la lista ya cargada.

`ListarUsuariosCasoUso`, `UsuarioRepositorio` y el overlay **no cambian**.

**App — DI (extensión de `ContenedorDependencias`)**

```swift
@MainActor
protocol ContenedorDependencias: AnyObject {
    // ADR-001 + ADR-002 (sin cambio de firma)
    var listarUsuarios: ListarUsuariosCasoUso { get }
    var obtenerUsuario: ObtenerUsuarioCasoUso { get }
    var crearUsuario: CrearUsuarioCasoUso { get }
    var actualizarUsuario: ActualizarUsuarioCasoUso { get }
    var iniciarSesion: IniciarSesionCasoUso { get }
    var cerrarSesion: CerrarSesionCasoUso { get }
    var sesionActual: SesionActualCasoUso { get }
    var sesion: Sesion? { get }

    var resumenUsuarios: ResumenUsuariosCasoUso { get }
}
```

`ContenedorApp` construye `ResumenUsuariosServicio()` una vez (sin dependencias). **Prohibido** `ResumenDashboard.shared`.

Presentation, tras cada listado exitoso (carga inicial, recarga, alta/edición que refresca el array):

```swift
resumen = contenedor.resumenUsuarios.ejecutar(usuarios)
```

Si el listado falla y no hay caché local: `resumen = .vacio` y el error de UI sigue siendo `ErrorUsuario` (copy existente). No inventar `ErrorUsuario.dashboard`.

### Swift Charts (Presentation — contrato, no Views)

- `import Charts` **solo** en archivos de Presentation (p. ej. futuros `GraficoUsuariosPorCiudadVista.swift`). Domain/Data/App no importan Charts.
- Marcas: **`BarMark`** para ciudad y para empresa (lectura comparable con n pequeño). `SectorMark` (pie) es opcional para empresa si UX lo pide después; **no** es obligatorio. **Prohibido** `LineMark` / `AreaMark` con eje temporal inventado.
- `ForEach(resumen.usuariosPorCiudad)` / `ForEach(resumen.usuariosPorEmpresa)` usando `PuntoGrafico.id`.
- Eje X: copy de Presentation (`TextosUsuarios`) mapeando `ClaveAgrupacion.ausente` → “Sin ciudad” / “Sin empresa”; `.valor` se muestra tal cual (nombres del dataset).
- Color: tokens de `TemaUsuarios` / acento de sistema. **No** paleta Bootstrap MixPro.
- Vacío (`totalUsuarios == 0` y sin error): empty state nativo existente (texto + SF Symbol), **no** chart vacío a pantalla completa sin explicación.
- Accesibilidad: el gráfico no puede ser el único canal. Cada KPI numérico es texto (Dynamic Type). El `Chart` lleva `accessibilityLabel` / `accessibilityValue` resumiendo la serie (p. ej. “Usuarios por ciudad: Gwenborough 1, …”). Detalle a11y = UX/G10; Architect no cierra G10.
- **Prohibido**: `WKWebView`, `NSViewRepresentable` de WebKit, paquetes JS, imágenes PNG de un dashboard web, métricas hardcodeadas en la vista.

Este ADR **no** escribe esas Views.

### Shell de aplicación (Architect elige)

**Se mantiene ADR-002.** Decisión explícita frente a “sidebar oscura admin”:

| Superficie | Decisión |
|------------|----------|
| Contenedor de navegación | **`NavigationSplitView` de 2 columnas**, el que ya hospeda `RaizAppVista`. **No** `TabView`. **No** anidar otro split. **No** segundo `WindowGroup`. |
| Secciones | `SeccionApp.inicio` y `.usuarios` **sin** tercer caso `.dashboard`. El dashboard **es** Inicio. |
| Sidebar | **Nativa**: `List` + `.listStyle(.sidebar)` + anchos actuales (Inicio 180–220; Usuarios 220–320). Sigue el `colorScheme` del sistema (clara u oscura). |
| Sidebar “admin” MixPro (fondo `#212529` fijo, logo, badges) | **Rechazada.** Rompe DS §2, contraste forzado, y el split nativo. El carácter “admin” está en el **contenido** del detalle (KPIs + Charts), no en chrome web. |
| Detalle `.inicio` | Sustituye el cuerpo actual (hero + 1 total + 2 atajos) por: hero/sesión **opcional a conservar**; **tres KPIs** (`totalUsuarios`, `ciudadesDistintas`, `empresasDistintas`); **dos charts**; atajos a lista / alta **pueden permanecer**. No grid de 12 columnas. No cuarta métrica fake. |
| Ancho | UX hoy limita Inicio a 720 pt. Charts se benefician del ancho del detalle (mínimo 400). Architect **permite** que el bloque de dashboard use `frame(maxWidth: .infinity)` en la columna detalle, con un techo razonable (p. ej. 960) si UX no ha enmendado aún `maxAnchoInicio`. No es un canvas web a todo el monitor. |
| CRUD | Sin cambio: sidebar sustituible; comandos focused en usuarios; Inicio no habilita CRUD salvo los atajos ya definidos. |

Logout, `.id(sesion)`, overlay `reiniciar()`, gate `sesionRequerida`: **sin cambio**.

### Estructura de carpetas (objetivo)

Filesystem-sync: crear solo lo que el Developer implemente. Este ADR no crea los `.swift` de producción.

```
GestionUsuarios/
  Domain/
    CasosDeUso/
      ResumenUsuariosCasoUso.swift    # protocol + ResumenUsuariosServicio
    Entidades/                        # o ValueObjects/ si el Developer prefiere subcarpeta
      ResumenDashboard.swift          # ClaveAgrupacion, PuntoGrafico, ResumenDashboard
  App/
    ContenedorApp.swift               # + resumenUsuarios
  Presentation/
    Inicio/                           # hospeda KPIs + Charts (Developer; fuera de este ADR)
      # p. ej. Grafico*.swift — import Charts

GestionUsuariosTests/
  Domain/
    ResumenUsuariosCasoUsoTests.swift
```

No tocar Data, entitlements, ni `Domain/Autenticacion/`.

### Concurrencia

| Pieza | Aislamiento |
|-------|-------------|
| `ClaveAgrupacion`, `PuntoGrafico`, `ResumenDashboard` | `nonisolated`, `Sendable` |
| `ResumenUsuariosCasoUso` / `ResumenUsuariosServicio` | `nonisolated`; método **síncrono** (CPU despreciable, n≈10) |
| ViewModels / Views / Charts | `@MainActor` (default) |

Hop: Presentation ya tiene `[Usuario]` en MainActor → llama `ejecutar` (sync, Sendable) → guarda `ResumenDashboard`. No hace falta `Task` ni `nonisolated(unsafe)`. No usar `MainActor.assumeIsolated` en Domain.

### App Sandbox y red

Sin entitlements nuevos. Sin URLs nuevas. El único GET sigue siendo `/users` del listar existente. Prohibido construir URLs desde etiquetas de ciudad/empresa.

ATS, Codable, logs sin cuerpos: ADR-001. El resumen no se loguea con PII (emails); si se loguea algo, solo conteos.

### Estrategia de errores

| Situación | Tipo | UI (Presentation) |
|-----------|------|-------------------|
| Lista en carga | Estado existente `.cargando` | KPIs: placeholder/`ProgressView`; no chart con ceros fingidos como “dato” |
| Lista error sin caché | `ErrorUsuario` | Copy de red existente; `resumen = .vacio`; no Chart.js “demo data” |
| Lista error con usuarios previos | `ErrorUsuario` + array | Banner de error; resumen de la lista **en memoria** (coherente con CRUD) |
| Lista OK vacía | No es error | Empty nativo; series vacías |
| Agregación | No falla | Función total |

### DI — Composition Root

Orden existente de ADR-002 **más** al final (o en el `init` que ya recibe el repositorio):

```
resumenUsuarios = ResumenUsuariosServicio()
```

No envolver el resumen en el decorator de sesión: no hay I/O. Tests: `ResumenUsuariosServicio()` directo con `FixturesUsuario`.

### NFRs

| NFR | Objetivo |
|-----|----------|
| Honestidad | Toda cifra es reducible a `[Usuario]` de la sesión actual |
| Latencia | Agregación &lt; 1 ms local; GET = el ya aceptado de ADR-002 (no segundo listar) |
| Memoria | O(n + k) con k ≤ n claves; n pequeño |
| Confidencialidad | Sin HTTP nuevo; no loguear series con emails |
| Accesibilidad | KPIs como texto; chart no único canal (G10 UX) |
| Usabilidad | Inicio sigue siendo el home post-login; Usuarios sigue siendo el CRUD |
| Observabilidad | Sin métrica de producto nueva en backend (no hay backend propio) |

## Consequences

### Positive

- Domain testeable (`ResumenUsuariosServicio`) sin SwiftUI ni red.
- ADR-001/002 intactos en capas, gate, logout y split.
- Cero superficie HTTP nueva; DBA no aplica.
- Charts nativos evitan WebView/MixPro/Chart.js.
- Sidebar nativa respeta Dark Mode y el design system; el “admin” está en el detalle.

### Negative

- Enmienda el home UX (720 pt / “no gráficos”): hace falta alinear `docs/ux/login-home-logout.md` (fuera de este ADR; handoff UX si el orquestador lo pide).
- Tres KPIs + dos charts es más denso que hero+total; riesgo de apretar 760×480 → mitigar con `ScrollView` ya usado en Inicio.
- `ClaveAgrupacion` obliga a copy en Presentation (no hardcodear “Sin ciudad” en Domain).

### Neutral

- Un solo BC Usuarios; no aparece BC “Analytics”.
- `SectorMark` queda opcional.
- El conteo de Inicio **cambia de dueño** (Domain) pero no de fuente (listar).

## Compliance

- **Security:** delta de superficie = **ninguno** (mismo GET `/users`, misma sesión RAM, misma clave nunca en red). Agregar strings de ciudad/empresa a un Chart no es inyección HTTP (no van a URL). G4 no se reabre como P0; Architect **no** declara PASS G4. Threat models vigentes (`docs/security/threat-model-usuarios.md`, `threat-model-auth-demo.md`) siguen aplicando al listar.
- **Performance:** O(n) in-process. `degraded: qualitative only` (G7 no pedido).
- **DevOps:** mismos `xcodebuild`; Swift Charts es SDK, no SPM. Sin CI.
- **Database:** no aplica. **No consultar DBA.** Persistencia = HTTP + overlay. Prohibido SwiftData/Core Data “para el dashboard”.

## Plan incremental (para Developer)

1. Domain: `ClaveAgrupacion`, `PuntoGrafico`, `ResumenDashboard`, `ResumenUsuariosCasoUso` + `ResumenUsuariosServicio` según algoritmo.
2. Tests Swift Testing: lista vacía; un usuario sin ciudad/empresa; dos ciudades; empate de conteo (orden estable); trim; suma de barras = total; overlay sintético cuenta igual que remoto (son `Usuario`).
3. App: propiedad `resumenUsuarios` en contenedor.
4. Presentation: tras cada `[Usuario]` actualizado, `ejecutar`; KPIs + Swift Charts en Inicio; copy de `.ausente`; **sin** WebView. Views **fuera** de este ADR.
5. No tocar login, decorator, entitlements, ni Data.

No introducir Chart.js, MixPro, TabView, ni métricas hardcodeadas.

## Riesgos

| Riesgo | Severidad | Mitigación |
|--------|-----------|------------|
| Developer pega MixPro/Chart.js en WebView | Alta | Rechazo en review; criterio de éxito explícito |
| KPIs inventados para “que se vea lleno” | Alta | Tests: cifras = función de fixtures; code review |
| Segundo `listar()` solo para el dashboard | Media | Caso de uso **sync** sobre `[Usuario]`; Inicio reutiliza el array del shell |
| Sidebar negra custom | Media | Este ADR la rechaza; split nativo |
| `import Charts` en Domain | Media | Review de imports |
| Nested split al “meter el dashboard” | Media | Dashboard = detalle `.inicio`, no un split nuevo |
| Docs UX (“no gráficos”) vs este ADR | Baja | Enmienda UX posterior; Developer sigue **este** ADR para datos y Charts |
| Chart ilegible a 400 pt de detalle | Baja | ScrollView; barras horizontales si el implementador lo necesita; no es decisión de capas |

## Quality Gate Status (Architect)

| Gate | Status | Evidencia | Notas |
|------|--------|-----------|-------|
| G0 Context | PASS | Handoff EE-ARCH-20260919-4 | Swift 5 / SwiftUI / macOS 27; Charts nativo; JSONPlaceholder; sin DBA |
| G1 Design | PASS | este archivo | Contratos + enmienda ADR-002 + shell nativo + Charts en Presentation |
| G4 Security | SKIP | delta HTTP = 0; sin auth nueva | No handoff ARCH-SEC P0; threat models de listar/auth siguen vigentes |
| G10 a11y | SKIP | Architect no cierra UX | Charts + KPIs texto; UX puede enmendar `login-home-logout.md` |

G2/G3/G6: SKIP — no hay código de producción en este entregable. DBA: SKIP — no aplica.

## References

- ADR-001: `docs/adr/ADR-001-clean-architecture-usuarios.md`
- ADR-002: `docs/adr/ADR-002-autenticacion-demo-y-shell.md` (enmendado solo el contrato de datos de Inicio)
- Handoff EE-ARCH-20260919-4 (Enterprise → Architect)
- Design system: `docs/ux/design-system-usuarios.md` §2 (sigue vigente contra dashboard **web**)
- UX Inicio: `docs/ux/login-home-logout.md` (parcialmente supersedido: ahora sí hay gráficos nativos)
- Swift Charts: framework `Charts` del SDK macOS
- Plantilla MADR: AgentesAI `skills/_shared/adr-template.md`

---

## Handoff: @software-architect-agent → @senior-fullstack-developer-agent

**Handoff-ID**: ARCH-DEV-20260919-4  
**Prioridad**: P0

### Contexto detectado

- Stack: Swift 5 / SwiftUI / macOS 27. Framework nativo `Charts` (Swift Charts), no Bootstrap.
- Arquitectura: Domain/Data/Presentation; Inicio ya llama `ListarUsuariosCasoUso`. ADR-001 y ADR-002 Accepted. **ADR-003 Accepted** — proyección `ResumenDashboard` en Domain; Charts en Presentation; mismo `NavigationSplitView`.
- DB/ORM: N/A JSONPlaceholder. ~10 usuarios + overlay sesión.
- Build: `xcodebuild -scheme GestionUsuarios -destination 'platform=macOS'`
- Test: Swift Testing en `GestionUsuariosTests`; XCTest UI en `GestionUsuariosUITests`
- Lint: no detectado
- CI: no detectado
- Constraints: App Sandbox; MainActor default; filesystem-sync; español; **prohibido** WebView MixPro, Chart.js, métricas fake; **no** DBA; **no** TabView; **no** anidar `NavigationSplitView`

### Alcance

- **Incluye**: tipos y `ResumenUsuariosServicio` del ADR-003; tests Domain del algoritmo; extender `ContenedorDependencias` / `ContenedorApp` con `resumenUsuarios`; Presentation Inicio: 3 KPIs + 2 `Chart` sobre `ResumenDashboard`; copy de `ClaveAgrupacion.ausente`; recomputar resumen cuando cambie `[Usuario]`.
- **Excluye**: Views prescritas por Architect (el Developer **sí** implementa UI, pero **no** rediseña el shell); WebView; Chart.js; MixPro; sidebar admin oscura custom; `SeccionApp` extra; caso de uso que re-lista HTTP; SwiftData; OAuth; DBA; LineMark temporal fake.
- **Archivos afectados**: `GestionUsuarios/Domain/CasosDeUso/ResumenUsuariosCasoUso.swift`; value objects de resumen; `ContenedorApp.swift`; `InicioVista` / ViewModel de shell o usuarios; `TextosUsuarios`; `GestionUsuariosTests/Domain/ResumenUsuariosCasoUsoTests.swift`.

### Artefactos entregados

- `docs/adr/ADR-003-dashboard-graficos.md` (contratos Swift embebidos)

### Decisiones tomadas

| Decisión | Justificación | Alternativa descartada |
|----------|---------------|------------------------|
| Agregación en Domain sync sobre `[Usuario]` | Testeable; sin HTTP extra | ViewModel agrupa; `listar()` otra vez |
| Swift Charts en Presentation | Pedido nativo; Sendable | WebView/Chart.js; barras ad hoc solas |
| Inicio = dashboard; mismo split | No romper ADR-002 | TabView; sección Dashboard extra |
| Sidebar nativa, no MixPro oscura | DS + Dark Mode + NAV | Chrome admin negro fijo |
| KPIs = total, ciudades, empresas | Únicos datos reales | MAU, series temporales, ids sintéticos |
| `ClaveAgrupacion.ausente` sin copy Domain | ADR-001: Domain sin strings UI | “Sin ciudad” hardcodeado en Domain |

### Riesgos abiertos

| Riesgo | Severidad | Requiere validación de |
|--------|-----------|------------------------|
| UI MixPro / Chart.js por prisa | Alta | Developer + Code Review |
| Docs UX desfasados (“no gráficos”) | Baja | UX (`login-home-logout.md`) si el orquestador lo pide |
| a11y de Chart | Media | UX/QA G10 post-UI |
| Chart apretado a 760×480 | Baja | Developer (ScrollView / BarMark) |

### Criterio de éxito

- [ ] `ResumenUsuariosServicio` puro: cero `URLSession`, cero SwiftUI, cero `Charts`
- [ ] Tests: vacío, trim, `.ausente`, suma de series = total, orden estable
- [ ] Inicio **no** llama a un segundo `listar()` exclusivo del dashboard
- [ ] Cero `WKWebView` / Chart.js / HTML MixPro
- [ ] Cero números de KPI que no salgan de `ResumenDashboard`
- [ ] Un solo `NavigationSplitView`; `SeccionApp` sigue en dos casos
- [ ] Sidebar sigue `.listStyle(.sidebar)` (no fondo `#212529` fijo)
- [ ] Alta en sesión se refleja en KPIs/charts al refrescar la lista (overlay)
- [ ] Build `xcodebuild -scheme GestionUsuarios -destination 'platform=macOS'` verde
- [ ] Tests Swift Testing del resumen en verde

### Gates pendientes

| Gate | Esperado |
|------|----------|
| G2 | Build verde tras implementación |
| G6 | Tests Domain del resumen; UITests de KPIs (QA) |
| G3 | Code Review post-diff |
| G10 | Contraste / VoiceOver de Chart (UX) |

### Comandos de verificación

- Build: `xcodebuild -scheme GestionUsuarios -destination 'platform=macOS'`
- Test: `xcodebuild test -scheme GestionUsuarios -destination 'platform=macOS'`
- Lint: no detectado

**Bloqueo:** no implementar WebView ni métricas hardcodeadas. Si UX no ha enmendado `login-home-logout.md`, **este ADR prevalece** para datos y Charts nativos.
