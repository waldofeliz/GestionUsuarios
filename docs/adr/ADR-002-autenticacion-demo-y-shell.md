# ADR-002: Autenticación demo y shell de aplicación (Inicio vs Usuarios)

## Status
Accepted

## Date
2026-09-19

**Enmienda (2026-09-19):** el contrato de **datos** de Inicio (conteo en Presentation; “no gráficos”) lo sustituye [ADR-003](ADR-003-dashboard-graficos.md). Auth, gate, logout, un solo `NavigationSplitView` y “Inicio usa `ListarUsuariosCasoUso`” siguen vigentes.

**Enmienda (2026-09-20):** identidad demo de producto = `administrador` (MAC de usuario actualizado). Pepper HMAC y MAC de password **sin cambio**. El usuario `waldofeliz` deja de autenticar. Auth local HMAC (ADR-002) no se rediseña.

## Context

`GestionUsuarios` ya implementa ADR-001 (Accepted): Domain / Data / Presentation + Composition Root. El `@main` (`GestionUsuariosApp`) entra **directo** a `RaizUsuariosVista`; el CRUD contra JSONPlaceholder no tiene gate de sesión.

El producto pide ahora:

1. Pantalla de **inicio** post-login (home / resumen; no un dashboard web de KPIs).
2. Login demo con un único usuario: nombre `administrador`, clave `123456`. JSONPlaceholder **no autentica**.
3. **Logout**.

Restricciones duras (reutilizadas del handoff EE-ARCH-20260919-3):

- Swift 5 / SwiftUI / macOS 27; App Sandbox; MainActor por defecto; filesystem-sync; español.
- Design system teal en `docs/ux/design-system-usuarios.md` (prohíbe dashboard web de 12 columnas / cards de métricas tipo SaaS).
- Navegación split de usuarios existente (`NavigationSplitView` lista | detalle) **no se tira**.
- ADR-001: un solo `WindowGroup`; Data ya tiene overlay `UsuarioRepositorioSesion` (`actor`, RAM).
- **Prohibido** enviar la clave a JSONPlaceholder (Security prevalece sobre “reusar HTTP”).
- Este ADR **no** prescribe Views/ViewModels de producción ni el algoritmo concreto de comparación de clave (lo cierra `@security-specialist-agent`).

Hoy hay **un** bounded context (`Usuarios`). Auth es un segundo contexto; no se mezcla con entidades `Usuario` ni con DTOs remotos.

## Decision Drivers

- No ampliar la superficie HTTP ni inventar backend / OAuth / Keychain “por si acaso”.
- Respetar ADR-001: mismas capas, mismo Composition Root, mismos casos de uso de usuarios.
- Gate real: el CRUD no debe ser invocable sin sesión aunque alguien llame al protocol desde un test o un ViewModel huérfano.
- Logout coherente: sin sesión de auth **y** sin overlay de altas/ediciones del proceso anterior.
- Inicio consume `ListarUsuariosCasoUso` para el conteo; cero cliente HTTP extra.
- Demo local: un solo usuario; la clave no viaja; la sesión no sobrevive al proceso (alineado al overlay).
- macOS: una ventana; no `NavigationStack` raíz; no segunda `WindowGroup` de login.

## Considered Options

### A — Origen de las credenciales

1. **Auth local en proceso** (verifier compilado + compare en cliente). Cero red en el camino de login.
2. **POST de usuario/clave a JSONPlaceholder** (p. ej. `/users` o un endpoint inventado). La API no valida passwords; además **filtra la clave a un tercero**.
3. **GET `/users` y “login” si el username existe en el dataset remoto**. No hay clave en JSONPlaceholder; `administrador` no es un usuario de esa API; acoplaría Auth a Usuarios y a la red.

### B — Material de la clave en el binario

1. **Plaintext en fuente** (`clave == "123456"`). Simple; la clave queda en el binario y en diffs; enseña mal hábito.
2. **Hash/compare local**: el binario guarda un **verificador** (digest + política). Domain solo ve `VerificadorCredenciales`. El algoritmo, salt, encoding y compare en tiempo constante los cierra Security.
3. **Clave en Keychain** poblada en runtime. Persistencia de secreto innecesaria para un único usuario demo hardcodeado; no resuelve el bootstrap (¿de dónde sale el primer secreto?).

### C — Dónde vive la sesión

1. **Memoria de proceso** (`@MainActor` store en Composition Root). Muere al cerrar la app; coherente con el overlay.
2. **UserDefaults / AppStorage** (`sesionIniciada = true`). Persiste un flag, no es almacén de secretos; al relanzar habría “logueado” sin overlay (PII de altas ya perdidas) o tentación de persistir overlay en disco.
3. **Keychain** (token/sesión). Overhead de entitlements/ACL para un flag demo; implica sesión durable que el producto no pide.

### D — Shell de ventana y navegación autenticada

1. **Misma `WindowGroup`, raíz condicional**: `sesion == nil` → inicio de sesión; `sesion != nil` → shell (secciones Inicio | Usuarios).
2. **Ventana de login aparte** (`Window` / segundo `WindowGroup`) y luego la ventana de usuarios. Multi-window no está en ADR-001 (`NAV-01`: una ventana).
3. **`NavigationStack` login → home → usuarios**. Patrón iPhone; UX existente lo prohíbe como raíz.
4. **Sidebar de secciones vs stack interno**: (4a) lista de secciones `Inicio` | `Usuarios` en el split de app; (4b) push/pop entre home y usuarios.

## Decision

**A1 + B2 + C1 + D1/4a**, con matices de composición:

| Tema | Elegido | Por qué | Descartado |
|------|---------|---------|------------|
| Credenciales | **Auth 100 % local** | JSONPlaceholder no es IdP; Security prohíbe enviar password a red | POST/GET remoto como login |
| Clave | **Verificador hash/compare** (algoritmo = Security) | Domain no compara plaintext; username demo sí puede ser constante de identidad | `== "123456"` en Domain; Keychain de bootstrap |
| Sesión | **RAM, Composition Root** | Misma vida que `UsuarioRepositorioSesion`; logout = proceso limpio | UserDefaults; Keychain |
| Shell | **Un `WindowGroup`, raíz condicional** | Incremental sobre ADR-001 | Login window; `NavigationStack` raíz |
| IA autenticada | **Secciones `Inicio` \| `Usuarios`** | Home post-login + CRUD existente sin tirar el split | Stack Inicio→Usuarios |

No hay microservicios, no hay módulo SPM nuevo, no hay DBA.

### Bounded contexts

```
┌─────────────────────────────────────────────────────────────┐
│ App (Composition Root)                                      │
│  ContenedorApp · EstadoSesion · CerrarSesionCompuesto       │
│  Raíz SwiftUI condicional                                   │
└────────────┬──────────────────────────────┬─────────────────┘
             │                              │
             ▼                              ▼
┌────────────────────────┐     ┌─────────────────────────────┐
│ BC Autenticacion       │     │ BC Usuarios (ADR-001)       │
│ Sesion, Credenciales   │     │ Usuario, casos CRUD         │
│ Iniciar / Cerrar /     │     │ ListarUsuariosCasoUso       │
│ SesionActual           │     │ Overlay RAM (Data)          │
│ VerificadorCredenciales│     │ Gate: exige Sesion          │
└────────────────────────┘     └─────────────────────────────┘
        ▲ no HTTP                         ▲ HTTPS /users
        │                                 │
        └── la clave NUNCA sale de aquí ──┘
```

Reglas de frontera:

- Autenticacion **no** importa DTOs, `UsuarioRepositorio` ni JSONPlaceholder.
- Usuarios **no** conoce la clave ni `CredencialesInicio`.
- El **único** puente permitido es: (1) gate “¿hay `Sesion`?” antes de CRUD; (2) logout compuesto que reinicia el overlay.
- `Usuario` remoto (Bret, etc.) **no** es identidad de login. Identidad demo = `administrador` local.

### Capas (extensión de ADR-001)

| Capa | Autenticacion | Usuarios (sin cambio de regla) |
|------|---------------|--------------------------------|
| **Domain** | Entidades `Sesion`, `CredencialesInicio`; `ErrorAutenticacion`; protocols de casos de uso + `AlmacenSesion` + `VerificadorCredenciales`; servicios de iniciar/cerrar/actual | Igual ADR-001. **No** añadir login aquí |
| **Data** | `AlmacenSesionMemoria`; implementación del verificador demo (detalle = Security) | Overlay + **nuevo** `reiniciar()`; decorator `UsuarioRepositorioAutorizado` |
| **Presentation** | Vista de inicio de sesión; menú Cerrar sesión; shell de secciones | Split existente **compuesto** por el shell, no como `@main` |
| **App** | Posee estado de sesión; orquesta logout (auth + overlay + reset de UI); raíz condicional | Sigue construyendo HTTP + overlay una vez |

Dependencias: `Presentation → Domain ← Data`; `App → todas`. Igual que ADR-001.

### Modelo de dominio (Autenticacion)

| Tipo | Rol | Notas |
|------|-----|--------|
| `Sesion` | Entidad inmutable, `nonisolated`, `Sendable` | `nombreUsuario: String`, `iniciadaEn: Date`. **Sin clave**, sin token, sin cookie |
| `CredencialesInicio` | Value object de entrada | `nombreUsuario`, `clave`. Vive solo en el hop de `IniciarSesion`. Prohibido loguear `clave`. Prohibido almacenarla en `Sesion` o UserDefaults |
| `ErrorAutenticacion` | Errores del BC | **No** reutilizar `ErrorUsuario` para clave incorrecta |

Identidad demo (producto):

- Único `nombreUsuario` válido: `administrador` (constante de identidad, no secreto; comparación por HMAC en Data, no literal en el target app).
- Única clave válida: la que Security materialice en el verificador (equivalente funcional a `123456` para el usuario demo).
- Usuario desconocido y clave incorrecta → **el mismo** error de dominio (`credencialesInvalidas`) para no enumerar identidades.

### Contratos (protocols) — nombres Swift

Todos los protocols de Domain/Data de este ADR: `nonisolated`, `Sendable`. No heredar el MainActor por defecto.

**Domain — Autenticacion**

```swift
nonisolated struct Sesion: Sendable, Equatable {
    let nombreUsuario: String
    let iniciadaEn: Date
}

nonisolated struct CredencialesInicio: Sendable {
    let nombreUsuario: String
    let clave: String
}

nonisolated enum ErrorAutenticacion: Error, Sendable, Equatable {
    case credencialesInvalidas
    case sesionRequerida
    case sesionYaIniciada
}

nonisolated protocol AlmacenSesion: Sendable {
    func actual() async -> Sesion?
    func guardar(_ sesion: Sesion) async
    func borrar() async
}

nonisolated protocol VerificadorCredenciales: Sendable {
    func verificar(_ credenciales: CredencialesInicio) async throws
}

nonisolated protocol IniciarSesionCasoUso: Sendable {
    func ejecutar(_ credenciales: CredencialesInicio) async throws -> Sesion
}

nonisolated protocol CerrarSesionCasoUso: Sendable {
    func ejecutar() async
}

nonisolated protocol SesionActualCasoUso: Sendable {
    func ejecutar() async -> Sesion?
}
```

Implementaciones Domain (structs, `nonisolated`):

| Struct | Depende de | Comportamiento |
|--------|------------|----------------|
| `IniciarSesionServicio` | `VerificadorCredenciales`, `AlmacenSesion` | Trim de `nombreUsuario`; `verificar`; si ok, `Sesion` + `guardar`. Si ya hay sesión, `sesionYaIniciada` **o** reemplazar — **decidir: rechazar con `sesionYaIniciada`** (el shell no muestra login con sesión viva). No toca HTTP |
| `CerrarSesionServicio` | `AlmacenSesion` | `borrar()`. **No** conoce el overlay de usuarios |
| `SesionActualServicio` | `AlmacenSesion` | `actual()` |

`VerificadorCredenciales.verificar`:

- Éxito: `return`.
- Fallo: `throw ErrorAutenticacion.credencialesInvalidas`.
- **Prohibido** en Domain: `clave == "123456"`, logs de la clave, hashing ad hoc sin el contrato.
- **Security** elige algoritmo, salt/pepper, encoding y compare (tiempo constante). Este ADR solo exige: compare local, sin red, sin plaintext de clave como literal de dominio.

**Domain — Usuarios (sin nuevos casos de uso de listado)**

No crear `ContarUsuariosCasoUso`. El home llama `ListarUsuariosCasoUso.ejecutar()` y deriva `usuarios.count` en Presentation. Evita un GET distinto y un protocol extra.

Añadir en Data (no en el protocol CRUD de Domain) la capacidad de vaciar el overlay:

```swift
nonisolated protocol ReiniciableOverlayUsuarios: Sendable {
    func reiniciar() async
}
```

`UsuarioRepositorioSesion` conforma: vacía `altas`/`ediciones` y restablece `siguienteID` a `idSinteticoMinimo`. **No** se añade `reiniciar` a `UsuarioRepositorio` (el BC Usuarios no es un almacén de sesión de login).

**Gate de autorización (Data, decorator)**

```swift
nonisolated protocol ProveedorSesionActiva: Sendable {
    func haySesion() async -> Bool
}

// Decorator delante del overlay (y por tanto de todo CRUD):
// UsuarioRepositorioAutorizado: UsuarioRepositorio
```

Antes de `listar` / `obtener` / `crear` / `actualizar`: si `haySesion() == false` → `throw ErrorAutenticacion.sesionRequerida`.

`AlmacenSesion` puede conformar `ProveedorSesionActiva`. El decorator envuelve `UsuarioRepositorioSesion`, no al revés (el overlay no debe ejecutarse sin gate).

Presentación **también** oculta el CRUD sin sesión (raíz condicional). El decorator es el gate de verdad; la UI no es el control de seguridad.

**App — DI (extensión de `ContenedorDependencias`)**

```swift
@MainActor
protocol ContenedorDependencias: AnyObject {
    var listarUsuarios: ListarUsuariosCasoUso { get }
    var obtenerUsuario: ObtenerUsuarioCasoUso { get }
    var crearUsuario: CrearUsuarioCasoUso { get }
    var actualizarUsuario: ActualizarUsuarioCasoUso { get }

    var iniciarSesion: IniciarSesionCasoUso { get }
    var cerrarSesion: CerrarSesionCasoUso { get }
    var sesionActual: SesionActualCasoUso { get }

    var sesion: Sesion? { get }
}
```

`ContenedorApp` sigue siendo el Composition Root **único**. **Prohibido** `Sesion.shared` / service locator.

`sesion` en el contenedor es el snapshot para SwiftUI (raíz condicional). Fuente de verdad: `AlmacenSesion`. Tras `iniciar`/`cerrar`, el contenedor actualiza `sesion` en MainActor.

### Logout compuesto (auth + overlay + UI)

`CerrarSesionServicio` de Domain **solo** borra `AlmacenSesion`. El producto exige limpiar también el overlay. Eso es orquestación de **aplicación**, no del BC Autenticacion:

```swift
nonisolated struct CerrarSesionCompuesto: CerrarSesionCasoUso {
    // 1. CerrarSesionServicio (Domain Autenticacion)
    // 2. ReiniciableOverlayUsuarios.reiniciar()
}
```

Vive en **App** (junto a `ContenedorApp`). Presentation solo llama `cerrarSesion.ejecutar()`.

Tras logout, Presentation **debe destruir** estado de usuarios (coordinador, ViewModel, sheets, búsqueda, selección). Mecanismo: `RaizAppVista.id(sesion?.nombreUsuario)` y/o recrear modelos cuando `sesion` pasa a `nil`. Si no, el siguiente login vería la lista en memoria aunque el overlay esté vacío.

**No** es aceptable documentar “el overlay se queda” como atajo: queda **prohibido**. El overlay se reinicia siempre en el compuesto.

### Shell de aplicación

**Raíz (`GestionUsuariosApp`)**

```
WindowGroup
└── if contenedor.sesion == nil
        Vista de inicio de sesión
    else
        RaizAppVista (shell autenticado)
```

Un solo `WindowGroup` (ADR-001). Frame mínimo existente (760×480) se mantiene. Login no abre otra ventana.

**Shell autenticado — secciones, no stack**

```
enum SeccionApp: Hashable {
    case inicio
    case usuarios
}
```

`CoordinadorApp` (`@MainActor`, `Observable`) posee `seccion: SeccionApp` (default `.inicio` post-login).

**Prohibido anidar `NavigationSplitView`**. `RaizUsuariosVista` es hoy un split de 2 columnas y **no** puede meterse como `detail` de otro split.

Patrón elegido: **un único `NavigationSplitView` de 2 columnas**, sidebar sustituible:

| `seccion` | Sidebar | Detail |
|-----------|---------|--------|
| `.inicio` | Lista de secciones: **Inicio**, **Usuarios** | Resumen nativo de inicio (conteo vía `ListarUsuariosCasoUso`) |
| `.usuarios` | Cabecera/acción **Inicio** (vuelve a `.inicio`) + lista de usuarios existente | Detalle / edición in-place existente |

El Developer **extrae** de `RaizUsuariosVista` las columnas lista | detalle para hospedarlas en el split del shell, o parametriza `RaizUsuariosVista` para no ser Scene root. El BC Presentation/Usuarios permanece; cambia el **anfitrión**.

Menú (extensión, no Views):

- **Cerrar sesión** en Archivo (sin usurpar ⌘Q). Habilitado solo con sesión.
- Comandos CRUD existentes (`ComandosUsuarios`): disabled sin `FocusedValue` de usuarios — de hecho no hay modelo de usuarios en login ni en Inicio. No hace falta un flag extra si el foco no está en usuarios; en Inicio deben permanecer disabled.
- Login: cero comandos de CRUD.

**Inicio (home) — contrato de datos, no de layout**

- Consume **solo** `ListarUsuariosCasoUso` del contenedor (misma instancia que el CRUD).
- Métrica: `count` de `[Usuario]` (y opcionalmente si la carga falló: mismo mapeo `ErrorUsuario` que la lista).
- **No** nuevo `ClienteHTTP`, **no** `GET` artesanal, **no** duplicar mapper/DTO.
- Visual: resumen de escritorio (un número + atajo a Usuarios), **no** grid KPI de 12 columnas (design system §2). Copy y a11y los cierra UX si hace falta; Architect no prescribe Views.
- Latencia: un GET `/users` al entrar a Inicio es aceptable (n≈10). No se añade caché de listado en este ADR. Si Inicio y Usuarios disparan dos GET, es NFR aceptado en demo.

### Estado: dónde vive (Composition Root)

| Estado | Dueño | Vida |
|--------|-------|------|
| `Sesion?` | `AlmacenSesionMemoria` + snapshot en `ContenedorApp.sesion` | Proceso; nil al arrancar y tras logout |
| Overlay altas/ediciones | `UsuarioRepositorioSesion` | Proceso; **reiniciar en logout** |
| `SeccionApp` | `CoordinadorApp` | Proceso autenticado; al login nuevo → `.inicio` |
| Selección/sheet usuarios | `CoordinadorUsuarios` | Se descarta en logout (identidad de vista) |
| Verificador | Data, inyectado una vez | Inmutable |

Arranque: siempre **sin** sesión → pantalla de login. No hay “remember me”.

### Estructura de carpetas (objetivo)

Filesystem-sync: crear solo lo que el Developer implemente.

```
GestionUsuarios/
  App/
    GestionUsuariosApp.swift          # raíz condicional
    ContenedorApp.swift               # + auth, gate, CerrarSesionCompuesto
    CerrarSesionCompuesto.swift       # orquestación logout
  Domain/
    Autenticacion/
      Entidades/
        Sesion.swift
        CredencialesInicio.swift
      Errores/
        ErrorAutenticacion.swift
      Repositorios/
        AlmacenSesion.swift           # protocol
        VerificadorCredenciales.swift # protocol
      CasosDeUso/
        IniciarSesionCasoUso.swift
        CerrarSesionCasoUso.swift
        SesionActualCasoUso.swift
    … (Usuarios ADR-001, intacto)
  Data/
    Autenticacion/
      AlmacenSesionMemoria.swift
      VerificadorCredencialesDemo.swift  # contenido = Security
    Repositorios/
      UsuarioRepositorioAutorizado.swift
      UsuarioRepositorioSesion.swift     # + reiniciar()
  Presentation/
    AppShell/
      CoordinadorApp.swift
      RaizAppVista.swift              # Developer (este ADR no lo escribe)
    Autenticacion/                    # login UI — Developer
    Inicio/                           # home — Developer
    Usuarios/                         # existente, hospedado por el shell

GestionUsuariosTests/
  Domain/Autenticacion/
  Data/Autenticacion/
```

### Concurrencia

| Pieza | Aislamiento |
|-------|-------------|
| `Sesion`, `CredencialesInicio`, `ErrorAutenticacion` | `nonisolated`, `Sendable` |
| Protocols auth + verificador | `nonisolated` |
| Servicios Domain auth | `nonisolated`, `async` |
| `AlmacenSesionMemoria` | `@MainActor` class **o** `actor`. Elegido: **`actor`** (misma disciplina que el overlay; tests sin UI) |
| Snapshot `ContenedorApp.sesion` | `@MainActor` |
| `UsuarioRepositorioAutorizado` | `nonisolated` / async hacia actor overlay + actor sesión |
| `VerificadorCredencialesDemo` | `nonisolated` (CPU; no MainActor) |
| Coordinadores y Views | `@MainActor` (default) |

Hop: Presentation `await iniciarSesion.ejecutar`; verificador no salta a red; resultado `Sesion` vuelve a MainActor.

### App Sandbox y red

Sin entitlements nuevos. Login **no** usa `network.client`. El GET de Inicio (conteo) reutiliza el stack HTTP ya autorizado a `jsonplaceholder.typicode.com`. Sigue prohibido construir URLs desde el campo de login.

ATS, Codable, logs sin cuerpos: ADR-001 + threat model vigente. **Nuevo asset**: `CredencialesInicio.clave` en RAM el tiempo del intento. No disco, no UserDefaults, no query string, no header HTTP.

### Estrategia de errores

| Situación | Tipo | Copy (Presentation; UX puede pulir) |
|-----------|------|-------------------------------------|
| Usuario o clave incorrectos | `ErrorAutenticacion.credencialesInvalidas` | Un solo mensaje (p. ej. “No se pudo iniciar sesión.”) |
| CRUD / listar Inicio sin sesión | `ErrorAutenticacion.sesionRequerida` | No debería verse (gate UI); tests sí |
| Login con sesión viva | `ErrorAutenticacion.sesionYaIniciada` | No expuesto si la raíz es condicional |
| GET conteo Inicio falla | `ErrorUsuario` existente | Mismos textos de red que la lista |
| Validación de campos vacíos de login | Presentation (no Domain) o `credencialesInvalidas` | No revelar si el usuario existe |

Domain Autenticacion no contiene strings de UI.

### DI — Composition Root (orden de construcción)

`ContenedorApp` construye una vez:

1. HTTP + `UsuarioRepositorioRemoto` + `UsuarioRepositorioSesion` (igual ADR-001).
2. `AlmacenSesionMemoria` (`actor`).
3. `VerificadorCredencialesDemo` (Security).
4. `UsuarioRepositorioAutorizado(base: overlay, proveedor: almacen)`.
5. Casos de uso CRUD **sobre el autorizado**, no sobre el overlay desnudo.
6. `IniciarSesionServicio`, `SesionActualServicio`.
7. `CerrarSesionCompuesto(domain: CerrarSesionServicio, overlay: overlay)`.
8. Snapshot `sesion = nil`.

Tests: stub de `VerificadorCredenciales` y de `AlmacenSesion`; stub de `UsuarioRepositorio` **detrás** del gate para probar `sesionRequerida`.

### NFRs

| NFR | Objetivo |
|-----|----------|
| Confidencialidad | Clave nunca en red ni logs; sesión no durable |
| Integridad | CRUD imposible sin `Sesion`; overlay no sobrevive al logout |
| Disponibilidad | Login offline (es local). Inicio con API caída: error de usuarios, sesión intacta |
| Latencia | Verificar credenciales &lt; 50 ms locales; GET conteo = GET lista ADR-001 |
| Observabilidad | Loguear resultado de login como éxito/fallo **sin** nombre+clave concatenados en Release; username demo puede ser `privacy: private` |
| Usabilidad | Arranque → login; éxito → Inicio; Usuarios = CRUD actual; Cerrar sesión → login limpio |

## Consequences

### Positive

- Segundo BC claro; ADR-001 intacto en reglas de Usuarios/HTTP.
- Password no sale del proceso; Security puede endurecer el verifier sin tocar casos de uso.
- Sesión RAM + overlay RAM + logout compuesto = un solo ciclo de vida demo.
- Home no inventa transporte: reutiliza `ListarUsuariosCasoUso`.
- Una ventana; el split de usuarios se rehospeda, no se reemplaza por stack iOS.

### Negative

- Más tipos/archivos (auth + decorator + compuesto).
- El Developer debe **rehospedar** el split de usuarios para no anidar `NavigationSplitView`.
- Hash en binario sigue siendo reversible/atacable (demo); no es un IdP.
- Dos GET posibles (Inicio y luego Usuarios) sin caché.

### Neutral

- Un único usuario demo; no hay roles ni refresh token.
- `ErrorAutenticacion` convive con `ErrorUsuario`; Presentation mapea según pantalla.
- UX/a11y de login e Inicio no están en este ADR (handoff a UX si el orquestador lo pide).

## Compliance

- **Security:** superficie nueva = captura local de clave + compare. **Cero** endpoints de login. No Keychain, no UserDefaults de sesión, no Basic Auth. G4 lo cierra el especialista (algoritmo, constant-time, logs, brute-force demo). Architect no declara PASS G4.
- **Performance:** verifier local despreciable; Inicio = un listar existente. `degraded: qualitative only` hasta que Performance mida si se pide.
- **DevOps:** mismos comandos `xcodebuild`; sin CI. Sin secretos de pipeline: el verifier va en el binario de demo (aceptable y explícito).
- **Database:** no aplica. No consultar DBA.

## Plan incremental (para Developer)

1. Domain Autenticacion: entidades, errores, protocols, `IniciarSesionServicio` / `CerrarSesionServicio` / `SesionActualServicio` (verifier y almacén inyectados).
2. Data: `AlmacenSesionMemoria`, `VerificadorCredencialesDemo` **según Security**, `UsuarioRepositorioAutorizado`, `reiniciar()` en overlay.
3. App: extender `ContenedorDependencias`, `CerrarSesionCompuesto`, snapshot `sesion`, raíz condicional.
4. Presentation: login + shell secciones + extraer split usuarios + Inicio con `ListarUsuariosCasoUso` (Views **fuera** de este ADR).
5. Tests Swift Testing: login ok/fail, gate sin sesión, overlay vacío tras `CerrarSesionCompuesto`, Inicio usa listar (no HTTP duplicado — aserción de no añadir cliente).

No introducir OAuth, Keycloak, SwiftData, TCA, ni persistir sesión.

## Riesgos

| Riesgo | Severidad | Mitigación |
|--------|-----------|------------|
| Enviar clave a JSONPlaceholder “para validar” | Alta | Prohibido en review; login sin `ClienteHTTP` |
| Plaintext `123456` en Domain | Media | Protocol `VerificadorCredenciales`; Security cierra implementación |
| CRUD callable sin sesión | Alta | Decorator + raíz condicional |
| Logout no limpia overlay | Alta | `CerrarSesionCompuesto` obligatorio; test |
| ViewModel de usuarios sobrevive al logout | Media | `.id(sesion)` / recrear modelos |
| `NavigationSplitView` anidado (UI rota) | Media | Un solo split; sidebar sustituible |
| Home duplica URLSession | Media | Solo `ListarUsuariosCasoUso` del contenedor |
| Brute-force de clave demo de 6 dígitos | Baja (demo) | Security: delay/lockout opcional; no es producción |
| Design system vs “dashboard” | Baja | Inicio = resumen nativo, no KPI web |

## Quality Gate Status (Architect)

| Gate | Status | Evidencia | Notas |
|------|--------|-----------|-------|
| G0 Context | PASS | Handoff EE-ARCH-20260919-3 | Swift 5 / SwiftUI / macOS 27; auth local; JSONPlaceholder sin login |
| G1 Design | PASS | este archivo | Contratos + BC + shell + DI + logout compuesto |
| G4 Security | SKIP (pendiente especialista) | superficie documentada en ARCH-SEC | Architect no cierra compare de clave |

G2/G3/G6: SKIP — no hay código de producción en este entregable.

## References

- ADR-001: `docs/adr/ADR-001-clean-architecture-usuarios.md`
- Handoff EE-ARCH-20260919-3 (Enterprise → Architect)
- Threat model vigente: `docs/security/threat-model-usuarios.md` (pre-auth; hay que extender en G4)
- UX split: `docs/ux/navegacion-usuarios.md` (`NAV-01`, prohibido stack raíz)
- Design system: `docs/ux/design-system-usuarios.md` (no dashboard web)
- ADR-003: `docs/adr/ADR-003-dashboard-graficos.md` (enmienda datos de Inicio: `ResumenDashboard` + Swift Charts)
- Plantilla MADR: AgentesAI `skills/_shared/adr-template.md`

---

## Handoff: @software-architect-agent → @senior-fullstack-developer-agent

**Handoff-ID**: ARCH-DEV-20260919-3  
**Prioridad**: P0

### Contexto detectado

- Stack: Swift 5 / SwiftUI / macOS 27
- Arquitectura: ADR-001 Accepted — Domain/Data/Presentation + Composition Root. App hoy entra directo a `RaizUsuariosVista`. **ADR-002 Accepted** — BC Autenticacion + shell Inicio \| Usuarios.
- DB/ORM: N/A — JSONPlaceholder **no tiene login**. Auth es local/demo.
- Build: `xcodebuild -scheme GestionUsuarios -destination 'platform=macOS'`
- Test: Swift Testing + XCTest UI
- Lint: no detectado
- CI: no detectado
- Constraints: App Sandbox; MainActor default; filesystem-sync; español; design system teal en `docs/ux/design-system-usuarios.md`; navegación split usuarios existente; **no anidar** `NavigationSplitView`; **no** enviar password a red

### Alcance

- **Incluye**: protocols y servicios de ADR-002; `AlmacenSesionMemoria`; decorator `UsuarioRepositorioAutorizado`; `reiniciar()` overlay; `CerrarSesionCompuesto`; extender `ContenedorApp` / raíz condicional; rehospedar split usuarios; Inicio que llama `ListarUsuariosCasoUso` (conteo); tests Domain/Data del gate y logout.
- **Excluye**: OAuth, Keycloak, backend propio, JSONPlaceholder como IdP, algoritmo de hash (espera ARCH-SEC), rediseño del design system, CI.
- **Archivos afectados**: árbol del ADR-002; `GestionUsuariosApp.swift`; `ContenedorApp.swift`; `UsuarioRepositorioSesion.swift`; Presentation shell/login/inicio; `GestionUsuariosTests/`.

### Artefactos entregados

- `docs/adr/ADR-002-autenticacion-demo-y-shell.md`

### Decisiones tomadas

| Decisión | Justificación | Alternativa descartada |
|----------|---------------|------------------------|
| Auth local | API sin login; Security prohíbe enviar clave | POST/GET JSONPlaceholder |
| Verificador (no plaintext Domain) | Separar contrato de algoritmo | `clave == "123456"` |
| Sesión en RAM (actor) | Coherente con overlay; no persistir demo | UserDefaults; Keychain |
| Un `WindowGroup` + raíz condicional | ADR-001 / NAV-01 | Ventana de login aparte |
| Sidebar Inicio \| Usuarios, un solo split | No stack iOS; no split anidado | `NavigationStack`; nested split |
| Gate decorator sobre overlay | CRUD imposible sin sesión | Solo ocultar UI |
| Logout = auth + `overlay.reiniciar()` + reset UI | Un solo usuario demo no justifica fugas de overlay | Solo `AlmacenSesion.borrar` |
| Inicio usa `ListarUsuariosCasoUso` | No duplicar HTTP | `ContarUsuariosCasoUso` + cliente nuevo |

### Riesgos abiertos

| Riesgo | Severidad | Requiere validación de |
|--------|-----------|------------------------|
| Algoritmo de compare / constant-time / logs de clave | Alta | Security (ARCH-SEC-20260919-3) **antes** de implementar `VerificadorCredencialesDemo` |
| Nested split al componer `RaizUsuariosVista` | Media | Developer (UI macOS) |
| UITests de login aún no especificados | Media | QA tras UI |

### Criterio de éxito

- [ ] Arranque muestra login, no `RaizUsuariosVista`
- [ ] `administrador` + clave demo (según verifier Security) → Inicio; `waldofeliz` + misma clave **no** autentica
- [ ] Credencial inválida → `ErrorAutenticacion.credencialesInvalidas`; cero HTTP de login
- [ ] CRUD y `listar` sin sesión → `sesionRequerida` (test del decorator)
- [ ] Inicio: conteo vía `ListarUsuariosCasoUso`; ningún `URLSession` nuevo
- [ ] Logout → login + overlay vacío + ViewModels de usuarios descartados (test overlay)
- [ ] Un solo `NavigationSplitView` a la vez
- [ ] Domain Autenticacion sin SwiftUI ni `URLSession`
- [ ] Build `xcodebuild -scheme GestionUsuarios -destination 'platform=macOS'` verde
- [ ] Tests Swift Testing del BC auth + gate en verde

### Gates pendientes

| Gate | Esperado |
|------|----------|
| G2 | Build verde tras implementación |
| G6 | Tests Domain/Data auth + overlay reset; UITests login (QA) |
| G4 | Cierre Security del verifier **antes** o en paralelo bloqueante del archivo demo |
| G10 | UX/a11y de login e Inicio (no este ADR) |

### Comandos de verificación

- Build: `xcodebuild -scheme GestionUsuarios -destination 'platform=macOS'`
- Test: `xcodebuild test -scheme GestionUsuarios -destination 'platform=macOS'`
- Lint: no detectado

**Bloqueo:** no implementar `VerificadorCredencialesDemo` con plaintext ni con hash improvisado. Esperar decisión de `@security-specialist-agent` (ARCH-SEC-20260919-3). Stubs en tests sí.

---

## Handoff: @software-architect-agent → @security-specialist-agent

**Handoff-ID**: ARCH-SEC-20260919-3  
**Prioridad**: P0 (G4)

### Contexto detectado

(mismo bloque que ARCH-DEV-20260919-3)

### Alcance

- **Incluye**: cerrar **cómo se compara la clave** (`VerificadorCredenciales`); threat model de login demo; STRIDE (spoofing local, disclosure de clave en logs/binario, brute-force); política de no-red; confirmar RAM vs Keychain vs UserDefaults; logs; constant-time; materialización de `123456` en el binario; gate `sesionRequerida` como control de AuthZ de cliente (no es servidor).
- **Excluye**: OAuth, Keycloak, backend, implementar Swift de producción, Views.
- **Archivos afectados**: ADR-002 (este); futuro `VerificadorCredencialesDemo.swift`; extensión de `docs/security/threat-model-usuarios.md`.

### Artefactos entregados

- Contratos `VerificadorCredenciales`, `CredencialesInicio`, `Sesion` (sin clave)
- Decisión arquitectónica: hash/compare local; **algoritmo abierto a Security**
- Superficie (abajo)

### Superficie de ataque (para G4)

| Elemento | Detalle |
|----------|---------|
| Login | Solo local. Cero HTTP en `IniciarSesionServicio` |
| Identidad demo | `administrador` (no secreto) |
| Secreto demo | Equivalente a `123456`; **no** viaja a `jsonplaceholder.typicode.com` |
| Almacén sesión | Actor memoria; no UserDefaults; no Keychain (Architect) |
| Overlay usuarios | RAM; se borra en logout compuesto |
| Gate CRUD | `UsuarioRepositorioAutorizado` → `ErrorAutenticacion.sesionRequerida` |
| Egress existente | Igual ADR-001 (GET/POST/PUT `/users`) **sin** Authorization header |
| Input | `nombreUsuario` + `clave` en form de login; no concatenar a URLs |
| Binario | Verifier compilado (demo); atacante con el .app puede extraer |

STRIDE preliminar (Architect, **no** cierra G4): spoofing de API irrelevante para login; tampering del verifier en binario = demo aceptado; info disclosure = logs/clave en heap; DoS = N/A local; elevation = sin roles, un usuario.

### Decisiones tomadas (Architect) vs abiertas (Security)

| Decisión | Owner | Estado |
|----------|-------|--------|
| No enviar clave a red | Architect + constraint Security | Cerrada |
| No plaintext como `==` en Domain | Architect | Cerrada |
| Hash/compare vía `VerificadorCredenciales` | Architect | Cerrada la forma; **abierto el algoritmo** |
| Sesión RAM, no Keychain/UserDefaults | Architect | Cerrada; Security puede **vetar o confirmar** |
| Mismo error usuario/clave | Architect | Cerrada; Security confirma anti-enumeración |
| Constant-time, salt, CryptoKit vs otras | Security | **Abierta — debe cerrar** |
| Lockout / delay anti-brute-force | Security | Abierta (recomendado/omitido para demo) |
| Zeroización de `String` clave | Security | Abierta (limitación de Swift) |

### Riesgos abiertos

| Riesgo | Severidad | Requiere validación de |
|--------|-----------|------------------------|
| Clave demo en binario (ingeniería inversa) | Media (demo) | Security: aceptar residual o endurecer |
| Compare no constant-time | Media | Security: exigir API concreta |
| Logger Debug imprime credenciales | Alta si ocurre | Security + review file:line post-código |
| Developer implementa `== "123456"` por prisa | Alta | Security: criterio de rechazo en G4 |

### Criterio de éxito

- [ ] Verdict G4 `PASS` o `CONDITIONAL` sin Critical/High
- [ ] Especificación implementable de `VerificadorCredencialesDemo` (pasos de hash/compare, constantes permitidas, tests)
- [ ] Confirmación o veto de sesión RAM
- [ ] Política de logs del intento de login
- [ ] Threat model actualizado (auth ya no es N/A)

### Gates pendientes

| Gate | Esperado |
|------|----------|
| G4 | Threat model o review + tool scan o `degraded: manual review` |

### Comandos de verificación

- Build: `xcodebuild -scheme GestionUsuarios -destination 'platform=macOS'`
- Test: `xcodebuild test -scheme GestionUsuarios -destination 'platform=macOS'`
- Lint: no detectado
