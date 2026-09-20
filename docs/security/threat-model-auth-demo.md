# Threat Model: Login demo local (gate de sesión)

**Handoff-ID origen**: SEC-POST-20260919-3  
**Handoff-ID diseño**: EE-SEC-20260919-3 → SEC-DEV-20260919-3  
**Fecha auditoría post-código**: 2026-09-19  
**Owner**: `@security-specialist-agent`  
**Alcance**: STRIDE + OWASP Top 10 2021 **A07** Identification and Authentication Failures, **A02** Cryptographic Failures, **A04** Insecure Design. Cliente macOS sandbox. **Código de login demo implementado; esta revisión es G4 post-código.**

**Criterio de producto (AC, no negociable)**: el par `administrador` / `123456` **debe** iniciar sesión. El par `waldofeliz` / `123456` **no** autentica. JSONPlaceholder **no tiene auth**; no se inventa un endpoint de login remoto.

**Postura**: no bloquear el AC. **Sí bloquear** (FAIL G4) si el password viaja por red (incluido JSONPlaceholder), se persiste en disco en claro, o el literal `"123456"` queda en el target `GestionUsuarios/`. **Ninguno de los tres se materializó.**

---

## Scope

- **Componentes**: gate de autenticación **local** (Domain + Data CryptoKit + SwiftUI login); `GestionUsuariosApp` como Composition Root; sesión en RAM; CRUD de usuarios existente **detrás** del gate.
- **Fuera de alcance**: OAuth/OIDC, Keychain como almacén de password, backend propio, certificate pinning (sigue el TM HTTP), roles/RBAC, “auth real” de producción.
- **Data classification**:
  - Password demo: **Confidential** (secreto de comparación). Nunca en logs ni en red ni en disco.
  - Username demo `administrador`: **Internal** (identidad de demostración; puede aparecer en copy de usuario, no en el secreto de comparación).
  - Sesión autenticada: **Internal**; solo RAM.
  - PII de usuarios JSONPlaceholder: sin cambio respecto a `docs/security/threat-model-usuarios.md`.
- **Trust boundaries**:
  1. Teclado / VoiceOver / Accessibility API → proceso sandbox (el password no debe reexponerse en `accessibilityValue`).
  2. Proceso → **no hay** frontera de red para credenciales. El verificador **no** recibe `ClienteHTTP`.
  3. Proceso → host `jsonplaceholder.typicode.com` (solo CRUD de usuarios **después** de sesión válida; mismos verbos GET/POST/PUT `/users`).
  4. Proceso → disco (`UserDefaults`, plist, files, Keychain): **prohibido** para el password.

Relación con ADR-001: se añade un bounded context `Autenticacion` **local**. No se altera el contrato HTTP. Domain sigue sin `URLSession` ni SwiftUI. **CryptoKit vive en Data**, no en Domain (Domain solo Foundation).

---

## Assets

| Asset | Sensitivity | Location permitida | Location prohibida |
|-------|-------------|--------------------|--------------------|
| Password AC `123456` (input de usuario) | Confidential | Binding de `SecureField` en RAM; argumento transitorio al verificador | Fuente de producción como literal de comparación; logs; HTTP; `UserDefaults`/plist/archivos; `accessibilityValue` |
| HMAC-SHA256 del password | Confidential (verificador demo) | Constante hex en Data (binario) | N/A (es el control A02) |
| HMAC-SHA256 del username | Internal | Constante hex en Data | — |
| Clave HMAC derivada (pepper de demo) | Confidential (extractable del binario) | Constante hex / `SymmetricKey` en Data | Disco, red, logs |
| Flag de sesión autenticada | Internal | Memoria de proceso | Disco, cookies HTTP, UserDefaults |
| Contador de fallos / lockout | Internal | Memoria de proceso | Disco (no hace falta persistir en demo) |
| Overlay CRUD `UsuarioRepositorioSesion` | PII de sesión | Actor en RAM (existente) | Sin cambio; no es token de auth |

---

## Decisión criptográfica (A02) — MUST

El password **123456** es débil y está en rainbow tables. **No se puede rechazar el AC.** Sí se **prohíbe** almacenar o comparar el literal `"123456"` en el target de producción.

### Algoritmo obligatorio

1. Pepper (32 bytes) = `SHA256(UTF-8("com.devapp.GestionUsuarios.demo.v1"))`.
2. Verificar con **CryptoKit** `HMAC<SHA256>.isValidAuthenticationCode(_:authenticating:using:)` (comparación de MAC en tiempo constante documentada por Apple). **Prohibido** `String ==` / `!=` sobre el password. **Prohibido** SHA256 unsalted del password como secreto (el digest `8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92` es público).
3. Evaluar **siempre** MAC de usuario **y** MAC de password (sin `return` anticipado entre las dos llamadas HMAC) y combinar con AND. Evita oráculo de timing “usuario existe”.
4. Comparar bytes UTF-8 **exactos** (sin `lowercased()`, sin trim del password).

### Constantes canónicas (reproducibles; copiar al código Data)

| Nombre | Hex (minúsculas, 64 chars) |
|--------|----------------------------|
| `claveHMAC` = SHA256(`com.devapp.GestionUsuarios.demo.v1`) | `919cf51ddd83f974999c722b7c870ea018ae0a6767ea785aa9bd8aa91598fe8c` |
| MAC usuario = HMAC-SHA256(clave, UTF-8 `administrador`) | `6c0f832b4a36b08ff6226936e200e7acd81914d2ffd654bc74b3c0812a108acb` |
| MAC password = HMAC-SHA256(clave, UTF-8 del secreto AC) | `c3461883b9cf66ac6b566fe239544675b0f83e10bf61dd3e6288909f1eb3adcb` |

Verificación independiente (solo para el implementador, no va en la app):

```text
key = SHA256("com.devapp.GestionUsuarios.demo.v1")
HMAC-SHA256(key, "administrador") → 6c0f832b4a36b08ff6226936e200e7acd81914d2ffd654bc74b3c0812a108acb
HMAC-SHA256(key, "123456")         → c3461883b9cf66ac6b566fe239544675b0f83e10bf61dd3e6288909f1eb3adcb
```

Helper hex: función **privada** en el archivo Data; no añadir SPM de cripto.

Con esto, el hallazgo **High “password en claro en fuente”** queda **Mitigated** (el secreto de comparación es HASH/HMAC, no el literal). El residual “verificador extraíble del binario” se acepta solo como demo (tabla Residual Risk).

---

## Superficie actual (post-implementación, 2026-09-19)

| Elemento | Evidencia | Resultado |
|----------|-----------|-----------|
| Gate de login | `RaizCondicionalVista.swift:10-14` — `sesion == nil` → `LoginVista`; si no → `RaizAppVista` | **Presente** |
| Verificador | `VerificadorCredencialesDemo.swift:6-24` HMAC-SHA256 + ambas `isValidAuthenticationCode` | Constantes canónicas OK; **sin** `ClienteHTTP` |
| Sesión | `AlmacenSesionMemoria.swift:4-21` actor RAM; `Sesion` sin clave | **Sin disco** |
| Lockout | `PoliticaIntentosAutenticacion.demo` 5 / 30 s; `RegistroIntentosMemoria` | RAM only |
| Logout | `CerrarSesionServicio` + `CerrarSesionCompuesto` (borra flag + `overlay.reiniciar`) | Vuelve a login; overlay PII limpiado (SHOULD) |
| HTTP usuarios | `APIUsuariosJSONPlaceholder.swift` GET/POST/PUT `/users`; `UsuarioDTO` sin password | Sin headers de auth |
| Cliente HTTP | `ClienteHTTPURLSession.swift:31-35` `Accept`/`Content-Type` JSON | **Cero** `Authorization` |
| Gate HTTP | `UsuarioRepositorioAutorizado.swift:12-35` exige sesión **antes** de CRUD | Login fallido no dispara GET `/users` |
| Persistencia | Overlay actor RAM; `URLSessionConfiguration.ephemeral`; grep `UserDefaults` = 0 en `*.swift` | Sin UserDefaults |
| Logs | `ClienteHTTPURLSession.swift:41-49` DEBUG status, sin cuerpo; auth sin `Logger` | Sin secreto |
| UI demo | `TextosUsuarios.loginEntornoDemo` = «Entorno de demostración»; `SecureField` + `accessibilityValue` «oculto» | Copy y a11y MUST |
| Entitlements | `GestionUsuarios.entitlements` sandbox + `network.client` | Sin Keychain extra |
| Auth remota | JSONPlaceholder Users API pública | **No usada** como IdP |

Snyk Code (path repo, 2026-09-19 post-login): **success, issueCount: 0**.  
Snyk Secrets: `degraded: feature not enabled (SNYK-CLI-0016)`. Grep: `"123456"` solo en Tests/UITests/docs; `UserDefaults` y `Authorization` **cero** en `GestionUsuarios/**/*.swift`.

---

## STRIDE Analysis

| Threat | Category | Component | Description | Mitigation | Status |
|--------|----------|-----------|-------------|------------|--------|
| Login con credencial débil conocida | Spoofing | Gate local | Cualquiera que lea el AC o el binario entra como `administrador` | Copy **“Entorno de demostración”** (`LoginVista.swift:50-53`); HMAC en vez de literal; no es IdP real | **Accepted** (demo / AC) — residual High de “auth real” |
| Spoofing remoto (POST login a typicode) | Spoofing | `ClienteHTTP` | Enviar usuario/password a un host que no autentica y tratar 200 como éxito | Verificador **sin** `ClienteHTTP`; Composition Root no inyecta cliente (`ContenedorApp.swift:68-76`) | **Mitigated** (verificado post-código) |
| Comparación `==` con timing | Information Disclosure / Spoofing | Verificador | `password == "123456"` filtra el secreto en fuente y por timing | HMAC CryptoKit `isValidAuthenticationCode` ambas MACs siempre (`VerificadorCredencialesDemo.swift:15-25`) | **Mitigated** (verificado) |
| Password en claro en fuente | Information Disclosure | Data/Presentation | Literal `"123456"` en target app | Cero hits en `GestionUsuarios/`; solo HMAC hex; tests usan el input AC | **Mitigated** (verificado) |
| Password en logs | Information Disclosure | Logger / `print` | `Logger` interpola el binding | Auth sin `Logger`; HTTP solo status DEBUG | **Mitigated** (verificado) |
| Password en VoiceOver | Information Disclosure | `LoginVista` | `accessibilityValue` relee el secreto | `SecureField` + `accessibilityValue` «oculto»; label «Contraseña» (`LoginVista.swift:117-122`) | **Mitigated** (verificado) |
| Password en disco | Information Disclosure | UserDefaults / plist / files / Keychain | “Remember me”, autofill Keychain, dump de estado | Sesión solo RAM; no UserDefaults; **falta** `.textContentType(.none)` en `SecureField` (SEC-AUTH-007 Medium) | **Mitigated** en claro (FAIL no aplica); residual autofill Keychain = Medium |
| Sesión zombie tras logout | Elevation of Privilege (local) | App / overlay | Logout no limpia el flag; CRUD sigue visible | Logout MUST poner sesión inválida y volver a login **antes** de pintar CRUD; vaciar binding del `SecureField` | **Mitigated** (MUST). Overlay PII: SHOULD recrear/limpiar |
| Fuerza bruta local | Denial of Service / Spoofing | Intentos | Ataque de adivinación en el proceso | Lockout en RAM: **5** fallos → **30 s** sin verificar (mismo copy genérico); al éxito resetear contador | **Mitigated** (MUST, razonable para demo) |
| Enumeración usuario vs password | Information Disclosure | UI errores | Mensajes distintos “usuario incorrecto” / “password incorrecto” | Un solo copy: “No se pudo iniciar sesión.” Lockout: “Demasiados intentos. Espera Xs.” | **Mitigated** (MUST) |
| Bypass del gate | Elevation of Privilege | `GestionUsuariosApp` | `RaizUsuariosVista` sin comprobar sesión; Preview de producción | Root: si no hay sesión → solo login. Previews de CRUD pueden inyectar sesión de test, no el binario Release | **Mitigated** (MUST) |
| Tampering del HMAC en binario | Tampering | Data | Patcher cambia `isValid` a `true` | Fuera de alcance demo (sin anti-tamper). Hardened Runtime ya ON | **Accepted** (demo) |
| Repudio de quién usó la app | Repudiation | Cliente local | Un usuario de macOS, sin auditoría | Aceptado igual que TM usuarios | **Accepted** |
| Login bloquea UI / flood | Denial of Service | Vista modelo | Reintentos en bucle, HMAC en MainActor pesado | HMAC es barato; lockout limita; trabajo de verify off-MainActor o sincrónico corto OK | **Mitigated** |
| Inyección en username | Tampering | Verificador | Username no va a URL ni a SQL | Bytes UTF-8 → HMAC; no interpolar en paths | **Mitigated** |

---

## OWASP (mapeo del alcance)

| ID | Tema | Resultado de diseño |
|----|------|---------------------|
| **A07** Identification and Authentication Failures | Password débil, sin MFA, sin IdP | AC impone `123456`. Compensaciones: demo-only, copy en UI, lockout, sesión volátil, logout. **No** es auth de producción. |
| **A02** Cryptographic Failures | Secreto en claro; hash débil; `==` | HMAC-SHA256 + `isValidAuthenticationCode`. Prohibido SHA256(password) unsalted y literal. TLS del CRUD no cambia. |
| **A04** Insecure Design | Tratar JSONPlaceholder como login; persistir sesión; mezclar HTTP y auth | Auth **100 % local**. Verificador **sin** red. Gate en Composition Root. |
| A01 Broken Access Control | Sin roles; un usuario local | Gate binario autenticado / no. Sin IDs de rol. |
| A09 Logging Failures | Password en logs | MUST NOT. Cliente HTTP existente ya no loguea cuerpos. |
| MASVS M1 / M3 | Credenciales / AuthN | Demo local documentado; no M3 de servidor. |
| MASVS M9 | Storage | Password y sesión **no** a disco. |
| MASVS M6 | Privacy / a11y leak | `accessibilityValue` sin secreto. |

---

## Attack Scenarios

1. **Enviar login a JSONPlaceholder**: el implementador hace `POST /users` o un path inventado con `{ username, password }`. Impacto: secreto en tránsito a tercero + falsa sensación de auth. **Bloqueante.** Mitigación: `VerificadorCredencialesDemo` no tiene `ClienteHTTP`; review: cero usos de `SolicitudHTTP` en archivos de autenticación.
2. **Guardar password en `UserDefaults`**: “mantener sesión” o debug. Impacto: plist en el container sandbox. **Bloqueante** si el valor es el secreto en claro. Mitigación: solo flag en RAM; no “remember me”.
3. **Literal `"123456"` en `TextosUsuarios` o Data**: grep del binario revela el AC. Impacto: High de secret-in-source. Mitigación: HMAC hex; copy de demo **sin** el password. El username **puede** mostrarse; el password **no**.
4. **VoiceOver lee el `SecureField`**: `accessibilityValue` por defecto = contenido. Mitigación: valor de accesibilidad no secreto.
5. **Fuerza bruta sin límite**: 123456 se adivina en pocos intentos. Mitigación: lockout 5/30s en RAM (no convierte esto en auth fuerte; reduce abuso casual).
6. **Logout incompleto**: flag sigue `true` o el split view permanece. Mitigación: invalidar sesión **y** sustituir la raíz por login; vaciar campos.
7. **Extracción del HMAC del binario + brute force**: `123456` cae en segundos. Residual **High** de “auth real”. **Aceptado** solo como demo local con copy visible.

---

## Controles (normativos)

### Bloqueantes (FAIL G4 si se implementan así)

- Enviar usuario y/o password (claro, hash o HMAC) en query, header, cookie o body HTTP a **cualquier** host, incluido `jsonplaceholder.typicode.com`.
- Persistir el password en claro en `UserDefaults`, plist, archivo, Core Data, SwiftData o logs rotativos.
- Usar JSONPlaceholder (u otro remoto) como oráculo de login.

### MUST (producción / target `GestionUsuarios`)

- AC: `administrador` + `123456` **sí** autentica vía HMAC canónico (tabla de constantes). `waldofeliz` + `123456` **no**.
- Cero literales `"123456"` en `GestionUsuarios/` (target app). Permitido **solo** como **input** en tests (`GestionUsuariosTests/`, UITests).
- Cero `String ==` / `hashedPassword == sha256("123456")` unsalted sobre el secreto.
- CryptoKit HMAC + `isValidAuthenticationCode` para usuario y password; ambas MACs siempre.
- `VerificadorCredenciales` (protocol Domain) **sin** tipos HTTP. Implementación Data **sin** importar ni inyectar `ClienteHTTP`.
- Sesión: bool/enum en memoria; proceso muerto = no autenticado.
- Logout: invalida sesión de inmediato; UI de login; `SecureField` vacío.
- Login **antes** de `RaizUsuariosVista` y **antes** de `cargarInicial()` de usuarios (no disparar GET `/users` en login fallido).
- UI: banner/texto persistente **“Entorno de demostración”** (o equivalente inequívoco) en la pantalla de login.
- `SecureField` (no `TextField`) para el secreto; `.textContentType(.none)` (evitar guardar en Llavero); `accessibilityLabel` “Contraseña”; `accessibilityValue` sin el secreto.
- Rate limit: 5 fallos consecutivos → lockout 30 s en RAM; botón/submit deshabilitado; anuncio a11y del espera. Éxito → reset de contador. Reloj: `Date`/`ContinuousClock` en memoria.
- Logs: no password, no username+password, no hex del HMAC de un intento. DEBUG como máximo categoría `auth` + “fallo”/“ok” sin PII de credencial.
- Copy de error genérico (sin distinguir usuario vs password).
- Entitlements: **no** añadir Keychain/network extra para login.

### SHOULD

- Recrear o vaciar `UsuarioRepositorioSesion` al logout (PII de la sesión CRUD).
- Deshabilitar comandos de menú CRUD (`ComandosUsuarios`) sin sesión (ya no hay `modeloUsuarios` focused).
- Comentario de archivo en el verificador: “solo demo local; no es un IdP”.
- Test que el archivo Data de auth no referencia `SolicitudHTTP` / `URLSession` (grep de revisión; o test de tipo: el init no acepta `ClienteHTTP`).

### MUST NOT (además de bloqueantes)

- Mostrar el password en labels, placeholders, help, o “usuario: x password: y”.
- `print` / `dump` del binding.
- Persistencia de “sesión válida” en UserDefaults (equivalente a auth persistente sin secreto, aún así no pedido; queda fuera. Si se añade, reabrir TM).

---

## Requisitos file-level (cuando se implemente)

Capas alineadas a ADR-001. Nombres en español salvo APIs Apple.

| Archivo | Capa | MUST |
|---------|------|------|
| `GestionUsuarios/Domain/Autenticacion/VerificadorCredenciales.swift` | Domain | Protocol `Sendable` `nonisolated`. Firma tipo `func coinciden(usuario: String, secreto: String) -> Bool` (o `async` innecesario). Cero CryptoKit, cero SwiftUI, cero red. |
| `GestionUsuarios/Domain/Autenticacion/IniciarSesionCasoUso.swift` | Domain | Protocol + servicio: lockout + llamada al verificador + activar sesión. No HTTP. |
| `GestionUsuarios/Domain/Autenticacion/CerrarSesionCasoUso.swift` | Domain | Invalida sesión. |
| `GestionUsuarios/Domain/Autenticacion/AlmacenSesion.swift` | Domain | Protocol del flag (o actor/estado). Solo memoria. |
| `GestionUsuarios/Domain/Errores/ErrorAutenticacion.swift` | Domain | Casos `credencialRechazada`, `bloqueado(hasta:)` — **sin** distinguir usuario/password. No reutilizar `ErrorUsuario.http`. |
| `GestionUsuarios/Data/Autenticacion/VerificadorCredencialesDemo.swift` | Data | Único sitio de `claveHMAC` + MACs hex. CryptoKit. Helper hex privado. **Prohibido** inyectar `ClienteHTTP`. **Prohibido** literal `"123456"` / `"administrador"` como secreto de comparación (el username literal tampoco: va por HMAC). |
| `GestionUsuarios/Data/Autenticacion/AlmacenSesionMemoria.swift` | Data | Flag + contador fallos + `fechaDesbloqueo`. `actor` o clase MainActor; **no** UserDefaults. |
| `GestionUsuarios/App/ContenedorApp.swift` | App | Registrar casos de uso de auth. **No** pasar `cliente` HTTP al verificador. |
| `GestionUsuarios/App/GestionUsuariosApp.swift` | App | Gate: sin sesión → `LoginVista`; con sesión → `RaizUsuariosVista`. Logout vuelve al login. |
| `GestionUsuarios/Presentation/Autenticacion/LoginVista.swift` | Presentation | Copy demo; `SecureField`; a11y MUST; identifiers (abajo). |
| `GestionUsuarios/Presentation/Autenticacion/LoginVistaModelo.swift` | Presentation | Consume protocols Domain; limpia el secreto del binding tras éxito o al logout. |
| `GestionUsuarios/Presentation/Navegacion/TextosUsuarios.swift` | Presentation | Strings de login **sin** password. Identificadores `login.*`. |
| `GestionUsuarios/Presentation/Comandos/` (nuevo o extensión) | Presentation | Comando Cerrar sesión habilitado solo con sesión. |
| `GestionUsuariosTests/Data/VerificadorCredencialesDemoTests.swift` | Tests | Input `administrador`/`123456` → true; `waldofeliz`/`123456` → false; basura → false; lockout cubierto en tests de caso de uso. |
| `GestionUsuariosTests/Domain/AutenticacionCasosDeUsoTests.swift` | Tests | 5 fallos → bloqueo; éxito resetea; logout invalida. |

**No tocar para auth**: `EndpointsJSONPlaceholder.swift`, `APIUsuariosJSONPlaceholder.swift`, `ClienteHTTPURLSession.swift`, `UsuarioDTO.swift` (salvo review que confirmen que siguen sin credenciales).

Identifiers a11y sugeridos (consistentes con `IdentificadorAccesibilidad`):

- `login.entornoDemo`
- `login.usuario`
- `login.password`
- `login.enviar`
- `login.error`
- `login.lockout`
- `sesion.cerrar`

---

## Hallazgos

Auditoría **post-código** del login demo (2026-09-19). Evidencia `file:line` + grep + Snyk Code.

| ID | Sev | OWASP | Ubicación | Descripción | Status |
|----|-----|-------|-----------|-------------|--------|
| SEC-AUTH-001 | Medium | A04 | `RaizCondicionalVista.swift:10-14` + `UsuarioRepositorioAutorizado.swift:32-35` | CRUD ya no es accesible sin sesión (UI + repositorio). | **Mitigated** |
| SEC-AUTH-002 | High* | A07 / A02 | Residual de diseño | Credencial demo débil + HMAC extraíble del binario = High si se vendiera como auth real. Copy «Entorno de demostración» presente. | **Accepted** demo; *no OPEN* |
| SEC-AUTH-003 | High | A02 | `VerificadorCredencialesDemo.swift:6-8` | Cero `"123456"` en target `GestionUsuarios/`. HMAC canónicos verificados de forma independiente. | **Mitigated** |
| SEC-AUTH-004 | High | A04 / A07 | `VerificadorCredencialesDemo.swift` (solo CryptoKit/Foundation); `ClienteHTTPURLSession.swift:31-35` | Credenciales no viajan por HTTP. Verificador sin `ClienteHTTP`. Cero `Authorization`. | **Mitigated** |
| SEC-AUTH-005 | High | A02 / MASVS M9 | `AlmacenSesionMemoria.swift:4-21`; grep `UserDefaults` = 0 en Swift | Sesión y lockout en RAM. Password no se escribe a disco en claro. | **Mitigated** |
| SEC-AUTH-006 | Low | A09 | Política org | Snyk Secrets org deshabilitado (SNYK-CLI-0016). Grep manual: 0 secretos en target. | **Open** tooling |
| SEC-AUTH-007 | Medium | A02 / MASVS M9 | `LoginVista.swift:117-123` | `SecureField` cumple a11y (`accessibilityLabel` «Contraseña», `accessibilityValue` «oculto») pero **no** aplica `.textContentType(.none)`. Autofill de macOS podría ofrecer guardar en Llavero (cifrado, no «en claro»). | **Open** — no FAIL G4; no High |

**Critical abiertos: 0.**  
**High de implementación abiertos: 0.**  
**High de “auth real” (SEC-AUTH-002): Accepted documentado, no OPEN.**

Controles confirmados:

- HMAC `claveHMAC` / MAC usuario / MAC password = tabla canónica (reproducción Python SHA256+HMAC-SHA256, match exacto).
- Ambas `HMAC<SHA256>.isValidAuthenticationCode` se evalúan **antes** del `&&` (`VerificadorCredencialesDemo.swift:15-25`).
- Sin `Authorization` en `ClienteHTTPURLSession.swift:31-35`.
- Host fijo HTTPS `EndpointsJSONPlaceholder.swift:4`.
- Overlay y URLSession ephemeral; logout reinicia overlay (`CerrarSesionCompuesto.swift:12-15`).
- Entitlements: sandbox + network.client; **sin** Keychain extra.

---

## Fix / implementación

Código de login ya implementado por Developer. Security **no** reescribió Swift en este G4 (0 High/Critical MUST-fix). SEC-AUTH-007 (`.textContentType(.none)`) queda en backlog P2.

Checklist de cierre post-código (2026-09-19):

1. [x] Grep target app: `"123456"` = 0; `UserDefaults` = 0; `accessibilityValue` de login = «oculto»
2. [x] Auth Data no referencia red (`VerificadorCredencialesDemo` solo CryptoKit + Foundation)
3. [x] Tests AC existen (`VerificadorCredencialesDemoTests`, `AutenticacionCasosDeUsoTests`) — ejecución = G6
4. [x] Snyk Code post-login: `issueCount: 0`
5. [x] Copy «Entorno de demostración» en `LoginVista.swift:50-53`

---

## Scan

| Tool | Resultado |
|------|-----------|
| Snyk Code (`snyk_code_scan`) path `/Users/waldofeliz/Desktop/Project/Apple/GestionUsuarios` | **success, issueCount: 0** (2026-09-19, **post-login**) |
| Snyk Secrets (`snyk_secret_scan`) | `degraded: feature not enabled (SNYK-CLI-0016)` — 403 org `7684c8c8-635d-4980-91bc-367718c225e6` |
| Grep `"123456"` | Hits solo en `GestionUsuariosTests/`, `GestionUsuariosUITests/`, `docs/` — **cero** en `GestionUsuarios/` |
| Grep `UserDefaults` | Cero en `GestionUsuarios/**/*.swift` |
| Grep `Authorization` | Cero en `GestionUsuarios/**/*.swift` |
| Snyk SCA | N/A — sin SPM. CryptoKit es sistema |

---

## Security Requirements

- [x] Gate de sesión en `GestionUsuariosApp` / `RaizCondicionalVista` (SEC-AUTH-001)
- [x] HMAC canónico + `isValidAuthenticationCode` (A02)
- [x] Cero `"123456"` en target `GestionUsuarios/`
- [x] Verificador sin red (A04)
- [x] Cero persistencia del password en claro (M9)
- [x] Cero logs del password (A09)
- [x] `accessibilityValue` sin secreto
- [x] Lockout 5 / 30 s en RAM
- [x] Copy “Entorno de demostración”
- [x] Logout invalida sesión y vuelve a login
- [x] AC `administrador` / `123456` cubierto en tests (tests existen; ejecución G6 = QA)
- [x] Residual SEC-AUTH-002 aceptado y visible en UI
- [x] Re-scan Snyk Code post-implementación (`issueCount: 0`)
- [ ] Snyk Secrets org (TOOL-001, preexistente)
- [ ] `.textContentType(.none)` en `SecureField` (SEC-AUTH-007)

---

## Residual Risk

| Risk | Severity | Accept? | Compensating control |
|------|----------|---------|---------------------|
| Credencial demo en binario (HMAC+pepper extraíbles) + password débil `123456` = bypass trivial de “auth real” | **High** (si se vendiera como auth de producción) | **Y — solo demo local** | Copy UI “Entorno de demostración”; sin red; sin persistencia; no Keychain; documentado en este TM |
| Sin MFA / sin IdP / un solo usuario | High (prod) / N/A (demo) | Y (demo) | Alcance de producto |
| Lockout solo en RAM (se resetea al matar el proceso) | Low | Y | Demo local unipuesto |
| VoiceOver/AX avanzado aún puede inferir teclas | Low | Y | `SecureField` + value vacío; residual de plataforma |
| Overlay CRUD sobrevive al logout si no se recrea | Low | Y (cerrado en código) | `CerrarSesionCompuesto` llama `overlay.reiniciar()` |
| Autofill macOS puede ofrecer Llavero (sin `.textContentType(.none)`) | Medium | N corto plazo | SEC-AUTH-007 backlog; Keychain cifrado ≠ password en claro |
| MITM del CRUD (sin pinning) | Low | Y | TM usuarios SEC-002 |
| Snyk Secrets disabled | Tooling | N | Grep + review |

El High residual **no** se trata como High *abierto de implementación*: está **Accepted** con compensaciones. Eso permite **CONDITIONAL** (no FAIL) **siempre que** SEC-AUTH-003/004/005 no se materialicen en código.

---

## Quality Gate G4

| Campo | Valor |
|-------|-------|
| Verdict | **CONDITIONAL** |
| Critical abiertos | 0 |
| High abiertos de implementación | 0 (SEC-AUTH-002 residual High **Accepted** demo, no OPEN) |
| Bloqueantes (HTTP / disco en claro / literal `"123456"` en target) | **No materializados** |
| Evidencia | este archivo + Snyk Code `success, issueCount: 0` + grep `"123456"`/`UserDefaults`/`Authorization` + HMAC Python match |
| Degraded | `degraded: Snyk Secrets feature disabled (SNYK-CLI-0016)` |

CONDITIONAL porque: (1) residual High de auth demo (SEC-AUTH-002) está **Accepted** con copy UI; (2) Secrets MCP degradado; (3) SEC-AUTH-007 Medium (autofill Keychain) documentado, no bloqueante.

**FAIL** no aplica: no hay credenciales en HTTP, no hay password en claro en disco, no hay literal `"123456"` en `GestionUsuarios/`.

---

## Backlog

| ID | Prioridad | Acción | Owner |
|----|-----------|--------|-------|
| SEC-AUTH-001 | — | Cerrado (gate UI + `UsuarioRepositorioAutorizado`) | — |
| SEC-AUTH-007 | P2 | Añadir `.textContentType(.none)` al `SecureField` de login | `@senior-fullstack-developer-agent` |
| SEC-AUTH-002 | P3 | Sustituir demo por IdP real si el producto deja de ser demo | Architect + Security |
| TOOL-001 | P2 | Habilitar Snyk Secrets (preexistente) | DevOps |
| SEC-001 | P2 | `ENABLE_USER_SELECTED_FILES` (TM usuarios; no auth) | Developer |

---

## Handoff: `@security-specialist-agent` → `@senior-fullstack-developer-agent`

**Handoff-ID**: SEC-DEV-20260919-3  
**Prioridad**: P0 (G4)

### Contexto detectado

- Stack: Swift 5 / SwiftUI / macOS 27, App Sandbox, HTTPS solo a `jsonplaceholder.typicode.com`
- Arquitectura: ADR-001 (Domain / Data / Presentation / App); overlay RAM; `ContenedorApp` Composition Root
- Auth hoy: **gate local implementado** (`RaizCondicionalVista` + HMAC Data)
- Threat models: `docs/security/threat-model-usuarios.md` (HTTP); **este archivo** (login demo, G4 post-código)
- JSONPlaceholder **no** autentica; no se añadió login remoto

### Alcance

- **Incluye**: gate local, HMAC CryptoKit, sesión RAM, logout, lockout, UI login + copy demo, tests del AC, file-level MUST de la tabla anterior.
- **Excluye**: reescribir CRUD; OAuth; Keychain del password; pinning; implementar desde este agente de seguridad (ya definido).
- **Archivos afectados**: lista file-level; no `APIUsuariosJSONPlaceholder` / cliente HTTP.

### Artefactos entregados

- `docs/security/threat-model-auth-demo.md` (este documento)
- Constantes HMAC canónicas (tabla A02)
- Verdict G4 **CONDITIONAL** de diseño

### Decisiones tomadas

| Decisión | Justificación | Alternativa descartada |
|----------|---------------|------------------------|
| Auth 100 % local | API sin auth; AC local | POST a typicode como login |
| HMAC-SHA256 + `isValidAuthenticationCode` | A02; no literal `"123456"`; tiempo constante | `==` de String; SHA256 unsalted (rainbow table) |
| CryptoKit en Data, protocol en Domain | ADR-001 Domain = Foundation | CryptoKit en Domain |
| Lockout 5 / 30 s RAM | A07 razonable para demo | Sin límite; lockout en UserDefaults |
| Copy demo obligatorio | Residual High aceptado solo como demo | Ocultar que es demo |
| No mostrar password en UI | Evitar reintroducir el literal en el binario | Hint “password: 123456” |
| AC no se bloquea | Exigencia de producto | Rechazar 123456 por política de password |

### Riesgos abiertos

| Riesgo | Severidad | Requiere validación de |
|--------|-----------|------------------------|
| SEC-AUTH-002 residual demo | High (prod) / Accepted (demo) | Copy UI en review |
| SEC-AUTH-003/004/005 si el diff los materializa | High → FAIL | Code Review + Security re-scan |
| Snyk Secrets off | Tooling | DevOps |

### Criterio de éxito

- [x] `administrador` / `123456` cubierto en tests de verificador y caso de uso; `waldofeliz` / `123456` no autentica
- [x] Credenciales **nunca** en HTTP
- [x] Password **nunca** en disco en claro
- [x] Cero `"123456"` en target app; HMAC canónico en Data
- [x] Logout invalida; lockout 5/30; a11y sin `accessibilityValue` del secreto
- [x] “Entorno de demostración” visible en login
- [x] Snyk Code post-código (`issueCount: 0`); Secrets `degraded: SNYK-CLI-0016`

### Gates

| Gate | Estado |
|------|--------|
| G4 post-código | **CONDITIONAL** — residual High demo Accepted; 0 High OPEN; bloqueantes no materializados |
| G2 / G3 / G6 | Fuera de este handoff (Developer / Review / QA) |

### Comandos de verificación

- Build: esquema Xcode del target `GestionUsuarios` (macOS)
- Test: `GestionUsuariosTests` (Swift Testing) — casos auth
- Lint: analizador Xcode del target
- Grep: `"123456"` solo bajo tests; auth Data sin `URLSession`/`SolicitudHTTP`
- Snyk: `snyk_code_scan` path absoluto del repo

---

## References

- ADR-001: `docs/adr/ADR-001-clean-architecture-usuarios.md`
- TM HTTP: `docs/security/threat-model-usuarios.md`
- Handoff EE-SEC-20260919-3
- Plantilla: AgentesAI `skills/_shared/threat-model-template.md`
- CryptoKit HMAC verify: `HMAC.isValidAuthenticationCode(_:authenticating:using:)`
- JSONPlaceholder Users: https://jsonplaceholder.typicode.com/users (sin auth)
- OWASP Top 10 2021 A02, A04, A07
