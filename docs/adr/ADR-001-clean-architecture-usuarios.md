# ADR-001: Clean Architecture para gestión de usuarios (macOS + JSONPlaceholder)

## Status
Accepted

## Date
2026-09-19

## Context

`GestionUsuarios` es una app macOS SwiftUI (Swift 5, Xcode 27, bundle `com.devapp.GestionUsuarios`) que hoy es el template vacío (`ContentView` con “Hello, world!”). No hay capas, ni persistencia local, ni CI, ni `AGENTS.md`/`README`.

El producto debe exponer CRUD de usuarios contra JSONPlaceholder (`https://jsonplaceholder.typicode.com`):

| Operación | HTTP | Recurso |
|-----------|------|---------|
| Listar | GET | `/users` |
| Detalle | GET | `/users/{id}` |
| Crear | POST | `/users` |
| Actualizar | PUT o PATCH | `/users/{id}` |

El usuario remoto típico incluye: `id`, `name`, `username`, `email`, `address` (street, suite, city, zipcode, geo lat/lng), `phone`, `website`, `company` (name, catchPhrase, bs).

Restricciones duras:

- App Sandbox ON (`ENABLE_APP_SANDBOX=YES`). No existe archivo `.entitlements` en el repo; hace falta declarar cliente de red.
- `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor` y `SWIFT_APPROACHABLE_CONCURRENCY=YES`.
- Groups sincronizados con filesystem: los archivos nuevos bajo `GestionUsuarios/` se incluyen solos en el target.
- Idioma de UI y código: español, salvo nombres de APIs externas y claves JSON.
- No hay autenticación (API pública).
- JSONPlaceholder **no persiste** POST/PUT/PATCH: responde 201/200 con el cuerpo, pero un GET posterior sigue devolviendo el dataset original (10 usuarios, ids 1…10).

Este ADR fija capas, contratos (protocols), DI, navegación, concurrencia, errores y sandbox. **No** prescribe Views/ViewModels de producción.

## Decision Drivers

- Separar dominio de SwiftUI y de `URLSession`/`Codable` para testear casos de uso sin red ni UI.
- Encajar en un único target de app (sin microservicios ni módulos SPM extra).
- Respetar MainActor por defecto sin bloquear el hilo UI con I/O de red.
- Hacer el CRUD usable pese a la persistencia ilusoria de JSONPlaceholder.
- Superficie de ataque mínima: un host HTTPS fijo, sin credenciales.
- Convenciones en español; DTOs en inglés porque reflejan el contrato remoto.

## Considered Options

1. **Clean Architecture + SwiftUI (capas Domain / Data / Presentation)**  
   Dominio con entidades y protocols de repositorio/casos de uso. Data implementa HTTP + DTO + mapper + overlay de sesión. Presentation (SwiftUI) consume solo casos de uso. Composition Root en el `App`.

2. **MVVM monolítico en Presentation**  
   ViewModels llaman `URLSession` y decodifican DTOs. Sin capa Domain. Más rápido de escribir; acopla UI, red y reglas.

3. **The Composable Architecture (TCA)**  
   Store/Reducer/Effect como columna vertebral. Navegación y efectos muy explícitos; dependencia grande (swift-composable-architecture) y curva alta para un CRUD de un bounded context.

## Decision

**Opción 1: Clean Architecture + SwiftUI**, en un solo módulo de app, con dependencias hacia adentro:

```
Presentation → Domain ← Data
       App (Composition Root) → todas las capas
```

Justificación:

- Un solo bounded context (`Usuarios`). No hay justificación para TCA ni para paquetes extra.
- El quirk de JSONPlaceholder se encapsula en Data (decorator de sesión), no en Views.
- Los protocols de Domain permiten stubs en `GestionUsuariosTests` (Swift Testing) sin levantar red.
- MVVM monolítico ahorra archivos al inicio y mezcla `URLSession`, `Codable` y estado de UI; con MainActor por defecto eso empuja I/O al hilo principal y dificulta el overlay de persistencia ilusoria.
- TCA no está en el repo y añade superficie de aprendizaje desproporcionada al alcance.

Patrón de persistencia: **remoto JSON + overlay de sesión en memoria** (no Core Data, no SwiftData, no SQLite). DBA no aplica.

### Capas

| Capa | Responsabilidad | Puede importar |
|------|-----------------|----------------|
| **Domain** | Entidades, value objects, errores de dominio, protocols de repositorio y casos de uso, implementaciones de casos de uso (orquestación pura) | Solo Foundation (tipos, `Sendable`). Cero SwiftUI, ceros `URLSession`/`Codable` de red |
| **Data** | DTOs JSONPlaceholder, mapper DTO↔dominio, cliente HTTP, repositorio remoto, overlay de sesión | Domain + Foundation + `URLSession` |
| **Presentation** | SwiftUI, estado de pantalla, navegación, mapeo error→copy | Domain (casos de uso + entidades). No DTOs, no `URLSession` |
| **App** | `@main`, Composition Root, registro de DI, entitlements | Todas |

### Modelo de dominio vs DTO

El dominio **no** copia el JSON. Nombres en español; invariantes en el dominio.

| Dominio | JSONPlaceholder (DTO) |
|---------|------------------------|
| `UsuarioID` (`Int`, `Sendable`) | `id` |
| `Usuario.nombre` | `name` |
| `Usuario.nombreUsuario` | `username` |
| `Usuario.correo` | `email` |
| `Usuario.telefono` | `phone` |
| `Usuario.sitioWeb` | `website` |
| `Direccion.calle`, `.apartamento`, `.ciudad`, `.codigoPostal` | `address.street/suite/city/zipcode` |
| `Coordenada.latitud`, `.longitud` | `address.geo.lat/lng` (String en API → `Double?` en dominio; parseo en mapper) |
| `Empresa.nombre`, `.eslogan`, `.rubro` | `company.name/catchPhrase/bs` |
| `UsuarioNuevo` (sin id) | cuerpo POST |
| `Usuario` (con id) | GET/PUT/PATCH |

Reglas:

- DTOs (`UsuarioDTO`, `DireccionDTO`, `GeoDTO`, `EmpresaDTO`) viven **solo** en Data, `Codable`, claves en inglés.
- El mapper (`UsuarioMapeador`) es el único que conoce ambos mundos.
- `geo.lat`/`lng` llegan como `String`; un valor no numérico no tumba el usuario: coordenada `nil` + log/error de mapeo parcial según política del mapper (no fallar el listado entero).
- Validación de correo/nombre no vacío ocurre en casos de uso de crear/actualizar, no en el DTO.

### Contratos (protocols) — nombres Swift

Todos `Sendable`. Domain y Data **no** heredan el MainActor por defecto: se declaran `nonisolated` (ver Concurrencia).

**Domain — repositorio**

```swift
nonisolated protocol UsuarioRepositorio: Sendable {
    func listar() async throws -> [Usuario]
    func obtener(id: UsuarioID) async throws -> Usuario
    func crear(_ alta: UsuarioNuevo) async throws -> Usuario
    func actualizar(_ usuario: Usuario) async throws -> Usuario
}
```

No hay `eliminar` en el alcance actual.

**Domain — casos de uso (ISP: un protocol por operación)**

```swift
nonisolated protocol ListarUsuariosCasoUso: Sendable {
    func ejecutar() async throws -> [Usuario]
}

nonisolated protocol ObtenerUsuarioCasoUso: Sendable {
    func ejecutar(id: UsuarioID) async throws -> Usuario
}

nonisolated protocol CrearUsuarioCasoUso: Sendable {
    func ejecutar(_ alta: UsuarioNuevo) async throws -> Usuario
}

nonisolated protocol ActualizarUsuarioCasoUso: Sendable {
    func ejecutar(_ usuario: Usuario) async throws -> Usuario
}
```

Implementaciones de Domain (structs): `ListarUsuariosServicio`, `ObtenerUsuarioServicio`, `CrearUsuarioServicio`, `ActualizarUsuarioServicio`. Reciben `UsuarioRepositorio` por constructor. Crear/actualizar validan invariantes y lanzan `ErrorUsuario.validacion` **antes** de tocar red.

**Data — HTTP y repositorio**

```swift
nonisolated protocol ClienteHTTP: Sendable {
    func enviar(_ solicitud: SolicitudHTTP) async throws -> RespuestaHTTP
}

nonisolated protocol FuenteUsuariosRemota: Sendable {
    func listarRemotos() async throws -> [UsuarioDTO]
    func obtenerRemoto(id: UsuarioID) async throws -> UsuarioDTO
    func crearRemoto(_ cuerpo: UsuarioDTO) async throws -> UsuarioDTO
    func actualizarRemoto(id: UsuarioID, cuerpo: UsuarioDTO) async throws -> UsuarioDTO
}
```

Implementaciones Data (no son protocols de Domain):

- `ClienteHTTPURLSession` — `URLSession` + timeout, status HTTP, cuerpo `Data`.
- `APIUsuariosJSONPlaceholder` — arma URLs bajo base fija `https://jsonplaceholder.typicode.com`.
- `UsuarioRepositorioRemoto` — DTO + mapper + `UsuarioRepositorio`.
- `UsuarioRepositorioSesion` — **decorator**: aplica altas/ediciones de la sesión sobre el resultado GET. Domain no sabe que la API es fake.

**App — DI**

```swift
@MainActor
protocol ContenedorDependencias: AnyObject {
    var listarUsuarios: ListarUsuariosCasoUso { get }
    var obtenerUsuario: ObtenerUsuarioCasoUso { get }
    var crearUsuario: CrearUsuarioCasoUso { get }
    var actualizarUsuario: ActualizarUsuarioCasoUso { get }
}
```

`ContenedorApp` es el Composition Root concreto. SwiftUI recibe el contenedor (o los casos de uso) por `Environment`; los ViewModels futuros reciben protocols por constructor. **Prohibido** service locator global mutable (`UsuarioRepositorio.shared`).

### Estructura de carpetas

Xcode sincroniza el filesystem. Crear solo lo que el Developer implemente; la forma objetivo es:

```
GestionUsuarios/
  App/
    GestionUsuariosApp.swift          # mover desde la raíz actual
    ContenedorApp.swift
  Domain/
    Entidades/
      Usuario.swift                   # UsuarioID, Usuario, UsuarioNuevo
      Direccion.swift                 # Direccion, Coordenada
      Empresa.swift
    Errores/
      ErrorUsuario.swift
    Repositorios/
      UsuarioRepositorio.swift        # protocol
    CasosDeUso/
      ListarUsuariosCasoUso.swift
      ObtenerUsuarioCasoUso.swift
      CrearUsuarioCasoUso.swift
      ActualizarUsuarioCasoUso.swift
  Data/
    Red/
      SolicitudHTTP.swift
      RespuestaHTTP.swift
      ClienteHTTP.swift               # protocol
      ClienteHTTPURLSession.swift
      EndpointsJSONPlaceholder.swift
    DTOs/
      UsuarioDTO.swift
    Mapeadores/
      UsuarioMapeador.swift
    Repositorios/
      APIUsuariosJSONPlaceholder.swift
      UsuarioRepositorioRemoto.swift
      UsuarioRepositorioSesion.swift
  Presentation/
    Navegacion/
      RutaUsuarios.swift
      CoordinadorUsuarios.swift
    Usuarios/
      Lista/                          # (futuro; no en este ADR)
      Detalle/
      Formulario/
  Recursos/
    Assets.xcassets                   # mover
    GestionUsuarios.entitlements      # nuevo
  ContentView.swift                   # deprecar / sustituir al implementar UI

GestionUsuariosTests/
  Domain/
  Data/
  Fixtures/

docs/adr/
  ADR-001-clean-architecture-usuarios.md
```

Tests de Presentation y UI (`GestionUsuariosUITests`) quedan fuera de este ADR.

### Navegación (nivel arquitectura)

Patrón macOS: `NavigationSplitView` (lista | detalle), no stack iOS-first.

- Estado de ruta: enum `RutaUsuarios` (`lista`, `detalle(UsuarioID)`, `alta`, `edicion(UsuarioID)`).
- `CoordinadorUsuarios` (`@MainActor`, `Observable`) posee la selección y las hojas/inspectores de alta-edición.
- Alta: sheet o inspector, no push iOS.
- Deep link interno: el coordinador acepta `UsuarioID`; no parsea URLs remotas.
- Presentation no navega “a un DTO”; solo ids y entidades de Domain.
- Un único `WindowGroup` (ya existe). No documentamos multi-window en este ADR.

### Concurrencia

Hecho del proyecto: **todo tipo es `@MainActor` salvo que se marque lo contrario**.

| Pieza | Aislamiento | Motivo |
|-------|-------------|--------|
| Entidades Domain (`Usuario`, etc.) | `nonisolated`, `Sendable` (structs) | Datos inmutables; cruzan hilos |
| Protocols Domain y Data | `nonisolated protocol …: Sendable` | Evitar que el default MainActor pinte el contrato |
| Casos de uso (structs) | `nonisolated`, métodos `async throws` | Orquestación sin UI |
| `ClienteHTTPURLSession` | `nonisolated` o `actor` de I/O | `URLSession` ya es thread-safe; no saltar a MainActor para decodificar |
| `UsuarioRepositorioSesion` | `actor` | Overlay mutable de sesión sin data races |
| `ContenedorApp`, coordinador, Views, futuros ViewModels | `@MainActor` (default) | UI y estado de pantalla |
| Mapper | `nonisolated` | CPU barata; no en MainActor |

Reglas de hop:

1. Presentation llama `await casoUso.ejecutar()` desde MainActor (ok: `await` suspende).
2. Data decodifica y mapea fuera del MainActor.
3. El resultado `Sendable` vuelve a Presentation; no se publican DTOs.
4. No usar `MainActor.assumeIsolated` en Data.
5. Tests de Domain/Data pueden correr sin isolation de UI.

Elección PUT vs PATCH: **PUT** para actualizar el recurso completo que el formulario envía (el dominio trata `Usuario` como agregado). PATCH queda fuera salvo que un campo opcional lo exija después.

### App Sandbox y red (G4 — superficie)

Sin `com.apple.security.network.client`, `URLSession` falla en runtime con sandbox denial. El Developer debe añadir `GestionUsuarios/Recursos/GestionUsuarios.entitlements` (o la ruta que Xcode asigne) y referenciarlo en el target:

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
```

Política:

- Solo cliente saliente. **No** `network.server`.
- Solo HTTPS a host fijo `jsonplaceholder.typicode.com` (constante en `EndpointsJSONPlaceholder`; prohibido construir URL desde input de usuario).
- ATS: HTTPS válido; **no** `NSAllowsArbitraryLoads`.
- No se piden entitlements de archivos, cámara ni incoming connections.
- No hay secretos ni tokens (API pública).

### Estrategia de errores

Un solo tipo de dominio, mapeado en Data y mostrado en Presentation:

```swift
nonisolated enum ErrorUsuario: Error, Sendable, Equatable {
    case red(Red)
    case decodificacion
    case noEncontrado(UsuarioID)
    case validacion(String)
    case http(codigo: Int)
    case inesperado
}

nonisolated enum Red: Sendable, Equatable {
    case sinConexion
    case tiempoAgotado
    case cancelado
}
```

Mapeo Data → Domain:

| Origen | `ErrorUsuario` |
|--------|----------------|
| `URLError.notConnectedToInternet` / DNS | `.red(.sinConexion)` |
| `URLError.timedOut` | `.red(.tiempoAgotado)` |
| `CancellationError` / `URLError.cancelled` | `.red(.cancelado)` (la UI no muestra banner) |
| HTTP 404 | `.noEncontrado` |
| HTTP 4xx/5xx resto | `.http(codigo:)` |
| `DecodingError` | `.decodificacion` |
| Cuerpo vacío inesperado | `.decodificacion` |
| Nombre/correo inválidos (use case) | `.validacion` |

Presentation traduce a copy en español. Domain no contiene strings de UI.

**Persistencia ilusoria:** no es un error. `UsuarioRepositorioSesion` fusiona:

- GET list/detalle de red (fuente de verdad remota).
- Altas de la sesión (ids sintéticos ≥ 10_000 para no chocar con 1…10; el id que JSONPlaceholder devuelve —suele ser 11— **no** se usa como clave de sesión porque se reutiliza).
- Ediciones de la sesión por `UsuarioID`.
- Un GET de red no debe borrar el overlay. Cerrar la app sí (memoria de proceso).

La UI (cuando se implemente) debe mostrar un aviso persistente de que los cambios no se guardan en el servidor. Eso es Presentation; el overlay evita que listar “deshaga” el alta.

Timeouts: 15 s de request; 1 reintento solo en GET idempotentes ante timeout; POST/PUT **sin** reintento automático (evitar altas duplicadas en sesión).

### DI — Composition Root

`GestionUsuariosApp` construye una vez:

1. `URLSession` con `waitsForConnectivity = false` (fallar visible, no colgar la UI).
2. `ClienteHTTPURLSession`
3. `APIUsuariosJSONPlaceholder`
4. `UsuarioRepositorioRemoto` envuelto en `UsuarioRepositorioSesion` (`actor`)
5. Los cuatro servicios de caso de uso
6. `ContenedorApp` inyectado al árbol SwiftUI

Sustitución en tests: stub de `UsuarioRepositorio` o de `ClienteHTTP`. No mockear SwiftUI.

### NFRs

| NFR | Objetivo |
|-----|----------|
| Latencia percibida | GET lista &lt; 2 s en red normal; skeleton/loading en Presentation |
| Disponibilidad | Sin API, lista vacía + `ErrorUsuario.red`; no crash |
| Confidencialidad | Sin PII real; dataset fake. Aun así no loguear cuerpos completos en Release |
| Integridad | Overlay de sesión coherente; ids sintéticos no colisionan con 1…10 |
| Observabilidad | Errores de red/decode con código HTTP; sin PII |

## Consequences

### Positive

- Casos de uso y repositorio testeables sin red ni ventana.
- El overlay de sesión hace demostrable el CRUD pese a JSONPlaceholder.
- MainActor queda en Presentation; I/O no bloquea el hilo UI si Data es `nonisolated`/`actor`.
- Superficie HTTP acotada a un host y cuatro verbos.

### Negative

- Más archivos que un ViewModel con `URLSession` (aceptable: un contexto).
- El overlay **diverge** del servidor real; no debe copiarse a una API de producción sin quitar el decorator.
- `nonisolated` + default MainActor exige disciplina; olvidarlo reintroduce jank o warnings de concurrencia.

### Neutral

- Un solo target; no hay límites de módulo del compilador entre capas (la frontera es por convención y review).
- PUT en lugar de PATCH; el formulario envía el agregado completo.
- Sin capa de caché disco ni SwiftData.

## Compliance

- **Security:** superficie = HTTPS cliente a `jsonplaceholder.typicode.com` (`GET/POST/PUT /users`). Sin auth, sin secrets, sin URL inyectada por usuario. Requiere entitlement `network.client`. Decodificación `Codable` estricta (no `JSONSerialization` suelto ni `eval`). Handoff a Security (G4).
- **Performance:** N+1 evitable (lista usa GET `/users`, no N detalles). Overlay en memoria O(n) con n≈10 + altas de sesión. Sin paging (API no pagina usuarios).
- **DevOps:** build `xcodebuild -scheme GestionUsuarios -destination 'platform=macOS'`. Sin CI; no hay artefacto de pipeline en este ADR.
- **Database:** no aplica. Persistencia = HTTP + `actor` de sesión. No hay consulta a DBA.

## Plan incremental (para Developer)

1. Entitlements sandbox + `network.client`.
2. Domain: entidades, `ErrorUsuario`, protocols, servicios de casos de uso.
3. Data: HTTP, DTOs, mapper, remoto, decorator de sesión.
4. `ContenedorApp` + mover `GestionUsuariosApp` a `App/`.
5. Presentation y tests (fuera de este ADR; el Developer implementa).

No migrar a SwiftData/TCA en este ciclo.

## Riesgos

| Riesgo | Severidad | Mitigación |
|--------|-----------|------------|
| Falta `network.client` → todas las llamadas fallan | Alta | Entitlement en el primer PR de Data |
| Default MainActor en repositorio → red en UI thread | Media | `nonisolated` / `actor` obligatorio en Domain y Data |
| Confiar en el `id` 11 de POST | Media | Ids sintéticos de sesión ≥ 10_000 |
| Overlay interpretado como persistencia real | Media | Banner en UI + comentario en `UsuarioRepositorioSesion` |
| `geo` String no numérico tumba el listado | Baja | Mapper tolerante en coordenadas |
| Sin CI, regresiones de capa no se ven | Media | Tests Swift Testing de mapper, errores y overlay (Developer + QA) |
| Logs de `URLSession` con email/teléfono | Baja | No imprimir cuerpos en Release |

## Quality Gate Status (Architect)

| Gate | Status | Evidencia | Notas |
|------|--------|-----------|-------|
| G0 Context | PASS | Handoff EE-ARCH-20260919-1 | Swift 5 / SwiftUI / macOS; JSONPlaceholder; sandbox |
| G1 Design | PASS | este archivo | Contratos + carpetas + DI + concurrencia |
| G4 Security | SKIP (pendiente especialista) | superficie documentada abajo | Handoff ARCH-SEC-20260919-1; Architect no cierra G4 |

G2/G3/G6: SKIP — no hay código de producción en este entregable.

## References

- Handoff EE-ARCH-20260919-1 (Enterprise → Architect)
- JSONPlaceholder Users: https://jsonplaceholder.typicode.com/users
- App Sandbox: `com.apple.security.network.client`
- Xcode: `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY=YES`, `ENABLE_APP_SANDBOX=YES`
- Plantilla MADR: AgentesAI `skills/_shared/adr-template.md`

---

## Handoff: @software-architect-agent → @senior-fullstack-developer-agent

**Handoff-ID**: ARCH-DEV-20260919-1  
**Prioridad**: P0

### Contexto detectado

- Stack: Swift 5 / SwiftUI / macOS (SDKROOT=macosx, MACOSX_DEPLOYMENT_TARGET=27.0, Xcode 27)
- Arquitectura: ADR-001 Accepted — Domain / Data / Presentation + Composition Root; template aún vacío
- DB/ORM: no aplica — HTTP JSONPlaceholder + overlay de sesión (`actor`)
- Build: `xcodebuild -scheme GestionUsuarios -destination 'platform=macOS'`
- Test: Swift Testing en `GestionUsuariosTests`; XCTest UI en `GestionUsuariosUITests`
- Lint: no detectado
- CI: no detectado
- Constraints: App Sandbox ON; hace falta `com.apple.security.network.client`; `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor`; `SWIFT_APPROACHABLE_CONCURRENCY=YES`; groups sincronizados con filesystem; bundle `com.devapp.GestionUsuarios`; DEVELOPMENT_TEAM B3J6J9Z2H6; idioma español salvo APIs; **no persistencia real en POST/PUT**

### Alcance

- **Incluye**: capas y protocols del ADR-001; entitlements; `ContenedorApp`; cliente HTTP; mapper; overlay de sesión; casos de uso CRUD; tests unitarios Domain/Data (Swift Testing).
- **Excluye**: rediseño de arquitectura; TCA; SwiftData; auth; Docker; microservicios.
- **Archivos afectados**: bajo `GestionUsuarios/` según árbol del ADR; `GestionUsuarios.entitlements`; tests en `GestionUsuariosTests/`.

### Artefactos entregados

- `docs/adr/ADR-001-clean-architecture-usuarios.md`

### Decisiones tomadas

| Decisión | Justificación | Alternativa descartada |
|----------|---------------|------------------------|
| Clean Architecture 3 capas + App | Testabilidad y overlay de fake API | MVVM monolítico; TCA |
| Overlay `actor` de sesión | CRUD demoable pese a API fake | Solo optimistic UI; ids del POST |
| PUT de agregado completo | Formulario edita el usuario entero | PATCH parcial |
| `nonisolated` Domain/Data | Default MainActor bloquearía I/O | Dejar tipos en MainActor |
| Host URL constante | Evitar SSRF / open URL | Base URL configurable por usuario |

### Riesgos abiertos

| Riesgo | Severidad | Requiere validación de |
|--------|-----------|------------------------|
| Entitlement de red mal enlazado al target | Alta | Developer (build + llamada real) |
| Isolation incorrecta (warnings Swift 6) | Media | Developer (compilación) |
| Superficie HTTP / ATS / logs PII | Media | Security (ARCH-SEC-20260919-1) |

### Criterio de éxito

- [ ] Entitlement `network.client` presente y el GET `/users` no muere por sandbox
- [ ] Protocols del ADR implementados con los nombres Swift acordados
- [ ] Domain no importa SwiftUI ni `URLSession`
- [ ] Presentation no ve DTOs
- [ ] Overlay: crear usuario y volver a listar lo muestra en la misma sesión
- [ ] Build `xcodebuild -scheme GestionUsuarios -destination 'platform=macOS'` en verde
- [ ] Tests Swift Testing de mapper, errores y overlay en verde

### Gates pendientes

| Gate | Esperado |
|------|----------|
| G2 | Build verde tras implementación |
| G6 | Tests Domain/Data |
| G4 | Cierre por Security (paralelo) |

### Comandos de verificación

- Build: `xcodebuild -scheme GestionUsuarios -destination 'platform=macOS'`
- Test: `xcodebuild test -scheme GestionUsuarios -destination 'platform=macOS'`
- Lint: no detectado

---

## Handoff: @software-architect-agent → @security-specialist-agent

**Handoff-ID**: ARCH-SEC-20260919-1  
**Prioridad**: P0 (G4)

### Contexto detectado

(mismo bloque que ARCH-DEV-20260919-1)

### Alcance

- **Incluye**: threat model de cliente macOS sandbox; HTTP outbound único; entitlements; ATS; decodificación JSON; ausencia de auth; logs; overlay no es control de seguridad.
- **Excluye**: auth/OAuth (API pública); backend propio; CI secrets.
- **Archivos afectados**: ADR-001 (superficie); futuro `.entitlements` y `EndpointsJSONPlaceholder`.

### Artefactos entregados

- Superficie HTTP (esta sección + ADR Compliance)

### Superficie de ataque (para G4)

| Elemento | Detalle |
|----------|---------|
| Dirección | Egress HTTPS `https://jsonplaceholder.typicode.com` |
| Endpoints | `GET /users`, `GET /users/{id}`, `POST /users`, `PUT /users/{id}` |
| Auth | Ninguna |
| Secrets | Ninguno |
| Input usuario | Campos de formulario (nombre, email, etc.) → cuerpo JSON; **id** como `Int` de dominio, no concatenar strings a URL |
| Sandbox | App Sandbox + `network.client` únicamente |
| ATS | Solo HTTPS; sin arbitrary loads |
| Datos | Dataset público fake; tratar email/teléfono como PII de todos modos en logs |

STRIDE preliminar (Architect, no cierra G4): spoofing de API irrelevante (sin sesión de usuario); tampering del JSON remoto → decode fail seguro; DoS → timeout 15 s; info disclosure → logs; elevation N/A.

### Decisiones tomadas

| Decisión | Justificación | Alternativa descartada |
|----------|---------------|------------------------|
| Base URL constante | No open-redirect/SSRF de cliente | URL libre en settings |
| Codable estricto | Evitar parsers ad hoc | `JSONSerialization` + diccionarios |
| Sin pinning de certificado (por ahora) | API pública de demo | Pinning (overhead, rotación) |

### Riesgos abiertos

| Riesgo | Severidad | Requiere validación de |
|--------|-----------|------------------------|
| MITM en red local sin pinning | Baja (demo) | Security: aceptar o exigir ATS-only |
| Entitlement más amplio de lo necesario | Media | Security: review del plist |
| Inyección en path `/users/{id}` | Baja si id es `Int` | Security + Developer |

### Criterio de éxito

- [ ] Verdict G4 `PASS` o `CONDITIONAL` sin Critical/High
- [ ] Entitlements mínimos confirmados
- [ ] Política de logs/PII documentada o hallazgo file:line

### Gates pendientes

| Gate | Esperado |
|------|----------|
| G4 | Threat model o review + tool scan o `degraded: manual review` |

### Comandos de verificación

- Build: `xcodebuild -scheme GestionUsuarios -destination 'platform=macOS'`
- Test: `xcodebuild test -scheme GestionUsuarios -destination 'platform=macOS'`
- Lint: no detectado
