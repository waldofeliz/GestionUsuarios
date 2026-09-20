# Alcance — Rediseño UI admin (inspiración MixPro) + gráficos nativos + GitHub

**Handoff origen**: EE-PM-20260919-4  
**Owner**: `@technical-pm-agent`  
**Fecha**: 2026-09-19  
**Prioridad**: P0  
**Idioma**: español  
**Este entregable no incluye código de producción.**

---

## Contexto recibido (context-once)

Handoff `EE-PM-20260919-4` confirmado. **No** se re-exploró el monorepo.

**Contexto detectado**:
- Stack: Swift 5 / SwiftUI / macOS 27 (NO web, NO Bootstrap, NO jQuery)
- Arquitectura: ADR-001 CRUD JSONPlaceholder + ADR-002 login demo local
- DB/ORM: no aplica — HTTP JSONPlaceholder + overlay de sesión
- Build: `xcodebuild -scheme GestionUsuarios -destination 'platform=macOS'`
- Test: Swift Testing + XCTest UI
- Lint: no detectado
- CI: no detectado
- Constraints: español; App Sandbox; no clonar plantilla MixPro (copyright); repo local **sin commits**; remoto pedido `https://github.com/waldofeliz/GestionUsuarios.git` (GitHub vacío)

Estado de producto **hoy** (evidencia de docs + Presentation):

- Login → shell autenticado (Inicio | Usuarios) → logout. Credenciales demo `administrador` / verifier Security. CRUD intacto.
- `InicioVista` = hero + 1 total + 2 tarjetas de acceso. **Cero** `import Charts`.
- Contratos vigentes **prohíben** el look pedido:
  - `docs/ux/design-system-usuarios.md` §2: «No: dashboard web (KPI, grids de 12 columnas, cards de métricas)».
  - `docs/ux/login-home-logout.md` §6: «No cuarta tarjeta KPI. No gráficos.»
  - ADR-002: Inicio = resumen nativo (un número + atajo), no grid KPI.

**Decisión de producto (P0, este documento)**: esas prohibiciones quedan **enmendadas** para este epic. El usuario pidió cambiar **toda** la interfaz hacia un admin con sidebar, KPI de color, área, barras y número grande. La enmienda **no** autoriza web, Bootstrap, Chart.js, marca MixPro ni métricas inventadas.

---

## 1. Objetivo

Entregar un **escritorio nativo macOS** que *se sienta* como un admin contemporáneo (referencia visual MixPro / Bootstrap admin: sidebar, tarjetas KPI de color, gráfico de área, barras, cifra destacada), **sin** copiar la plantilla, **sin** WebKit y **sin** JavaScript.

Los números y las series salen **solo** de usuarios reales de `ListarUsuariosCasoUso` (JSONPlaceholder + overlay de sesión). Login/logout y el CRUD se conservan. Al cerrar el epic, el repositorio vive en GitHub.

**Éxito de negocio (verificable)**

1. Un revisor que conozca MixPro reconoce el *patrón* (sidebar + KPI color + área + barras + cifra) y **no** ve logo MixPro, Bootstrap, jQuery ni HTML embebido.
2. Cada KPI y cada punto de gráfico se puede trazar a `[Usuario]` de la sesión (conteo, ciudades, empresas). Cero «6374 visitas», cero feeds Twitter/Facebook.
3. Hay **exactamente dos** gráficos Swift Charts (`AreaMark` + `BarMark`), no Chart.js.
4. `administrador` entra, ve el dashboard, abre Usuarios, cierra sesión. Misma ventana, sandbox intacto.
5. El remoto GitHub deja de estar vacío (primer commit del proyecto, sin secretos).

---

## 2. Descomposición (Epic → slices)

```
Epic E-DASH-01  Rediseño admin nativo + gráficos + publicación GitHub
├── Slice A  Contratos (ADR + UX) — desbloquea código
├── Slice B  Dashboard Inicio (KPI + 2 Charts + cifra)     MUST
├── Slice C  Sidebar / chrome admin                         MUST
├── Slice D  Login + lista/detalle alineados al look        SHOULD
├── Slice E  Conservar sesión CRUD + identifiers            MUST (no-regresión)
└── Slice F  Primer push a GitHub                           MUST (después de B+C+E)
```

No hay slice de OAuth, WebView, SPM Chart.js, ni clon de MixPro.

---

## 3. MoSCoW (alcance cerrado)

### Must — entra en el epic; sin esto no hay Done

| ID | Ítem | Notas de producto |
|----|------|-------------------|
| M01 | **KPI derivados de usuarios reales** | Tres tarjetas: (1) total de usuarios, (2) ciudades distintas (`direccion.ciudad`), (3) empresas distintas (`empresa.nombre`). Vacío/error: no inventar 0 si la lista falló (reutilizar semántica `home.total` / `COPY-HOME-TOTAL-NA`). |
| M02 | **Cifra grande (número destacado)** | El total de usuarios es el ancla visual tipo MixPro «big number». Identifier vigente `home.total` **se conserva** (el valor grande vive ahí o el nuevo ancla **reutiliza** ese identifier). |
| M03 | **Dos gráficos Swift Charts** | Uno `AreaMark`, uno `BarMark`. Framework Apple `Charts` (`import Charts`). Prohibido Chart.js, Canvas, WKWebView, SPM de charts JS. |
| M04 | **Series honestas (sin tiempo inventado)** | JSONPlaceholder **no** trae visitas ni fechas. El área **no** puede titulse «tráfico» ni «visitas». Ver §3.1. |
| M05 | **Sidebar de admin** | Destinos Inicio \| Usuarios se conservan (`shell.inicio`, `shell.usuarios`). Look admin (cabecera de producto, ítems con icono, jerarquía). Una sola `NavigationSplitView` de shell (ADR-002). |
| M06 | **Login y logout se conservan** | Arranque = login; éxito → Inicio dashboard; menú Cuenta + `toolbar.logout`; overlay se reinicia (`CerrarSesionCompuesto`). Credenciales demo y verifier Security **sin cambio**. |
| M07 | **Sin feeds sociales** | No widgets Twitter/Facebook/Instagram. No hay datos ni API. |
| M08 | **Sin métricas inventadas** | Prohibido hardcodear 6374, % de bounce, revenue, «new users this week» si no sale de `[Usuario]`. |
| M09 | **Copyright: inspiración, no clon** | Ver §3.2. |
| M10 | **Idioma español** | Chrome, copy, VoiceOver. Datos remotos (nombres de ciudad/empresa) se muestran como dato. |
| M11 | **Publicar en GitHub** | Tras Must de UI verificados (build/test). Remoto `https://github.com/waldofeliz/GestionUsuarios.git`. Repo hoy sin commits. Sin `.env`, sin clave en README de producto (CRED-04: demo solo en README de desarrollo o UITests). |

### Must not — rechazo en review

| ID | Prohibido |
|----|-----------|
| MN01 | Copiar marca **MixPro**, wordmark, favicon o copy de la plantilla |
| MN02 | Logos **Bootstrap** / **jQuery** / «built with» de la plantilla |
| MN03 | Pegar HTML/CSS/JS de MixPro o cargarlo en `WKWebView` |
| MN04 | `import` o SPM de Chart.js / ApexCharts / Chartist / cualquier chart web |
| MN05 | OAuth, Keycloak, Keychain de sesión durable, POST de clave a JSONPlaceholder |
| MN06 | Segundo `WindowGroup` o `TabView` / `NavigationStack` raíz |
| MN07 | Relajar App Sandbox ni añadir entitlements extra (Charts es framework Apple, no red nueva) |
| MN08 | Inventar backend, Core Data o un GET distinto para el dashboard |

### Should — mismo look en el resto de la app (no solo el home)

| ID | Ítem | Si no entra |
|----|------|-------------|
| S01 | **Login** visualmente alineado al nuevo look (mismos tokens de sidebar/fondo/acento KPI, no una isla «Contactos teal» aislada) | El epic puede cerrar Must; queda deuda UX P1 |
| S02 | **Lista + detalle de usuarios** alineados (cabecera, densidad, color de chrome) **sin** romper identifiers `lista.*` / `detalle.*` / `form.*` / `toolbar.nuevo\|recargar\|editar` | Igual: P1 |
| S03 | Estados de gráfico: loading, error de red, dataset vacío (0 usuarios) | Mínimo Must: no crashear; Should: empty nativo, no placeholder fake |

### Could — backlog, no este epic

| ID | Ítem |
|----|------|
| C01 | Tercer gráfico (línea, donut) |
| C02 | Cuarta KPI (p. ej. usuarios con sitio web no vacío) |
| C03 | Exportar CSV / imprimir dashboard |
| C04 | Tema claro/oscuro *distinto* del sistema (un «admin dark» forzado) |
| C05 | CI GitHub Actions (el remoto nace vacío; pipeline es otro epic) |
| C06 | Más ítems de sidebar (Ajustes, Mensajes, Calendar) — no hay bounded contexts |

### Won't — fuera, no negociable en este ciclo

| ID | Ítem | Por qué |
|----|------|---------|
| W01 | WebView Bootstrap / plantilla MixPro embebida | Stack macOS; copyright |
| W02 | SPM o script de Chart.js | Producto nativo; Must M03 |
| W03 | OAuth / IdP / usuarios reales | ADR-002; Security |
| W04 | Feeds Twitter/Facebook | Sin datos, sin API, copyright de widgets |
| W05 | Métricas tipo SaaS (visitas, sessions, revenue) | Dataset = 10 usuarios fake |
| W06 | Clonar MixPro (HTML, marca, assets) | Copyright |
| W07 | Microservicios, Docker, SwiftData, TCA | ADR-001 |
| W08 | iOS / iPad destinos | App macOS |

### 3.1 Contrato de datos de los gráficos (Must M04)

JSONPlaceholder `/users` es un **snapshot** (~10 filas). No hay `createdAt`, no hay series temporales, no hay visitas.

| Gráfico | Mark | Eje X (categoría real) | Eje Y | Título UI (copy cerrado en UX) |
|---------|------|------------------------|-------|--------------------------------|
| G-AREA | `AreaMark` | Ciudad (`direccion.ciudad`), ordenada por conteo desc. y luego nombre | Nº de usuarios en esa ciudad | **Usuarios por ciudad** — nunca «Visitas», «Traffic», «Analytics» |
| G-BAR  | `BarMark` | Empresa (`empresa.nombre`), mismo criterio de orden | Nº de usuarios en esa empresa | **Usuarios por empresa** |

Si una ciudad/empresa está vacía en el dominio: categoría `"Sin ciudad"` / `"Sin empresa"` (copy UX). No omitir usuarios del total.

**Riesgo de producto aceptado**: con n≈10 la cardinalidad ciudad/empresa suele ser ~1 usuario por barra. **Se acepta.** Es honesto. UX debe diseñar para «muchas categorías, valores bajos» (scroll horizontal o Top 8 + «Otros»), no inflar Y con visitas falsas.

Agregación: **una sola** lectura de `ListarUsuariosCasoUso` (la que ya dispara el shell). **No** `ContarUsuariosCasoUso` ni segundo `URLSession`. Architect decide si el agregado vive en Presentation o en un value object de Domain puro (`ResumenDirectorio`).

### 3.2 Copyright — traducción de MixPro → nativo

La imagen MixPro es **referencia de layout**, no especificación de píxeles ni de marca.

| Señal MixPro (inspiración) | Traducción Must (nativa) | Prohibido |
|----------------------------|--------------------------|-----------|
| Sidebar oscura + logo producto | Sidebar sistema o tinte de token **nuevo** (UX); título «Gestión de usuarios» | Logo MixPro, texto MixPro, Bootstrap |
| Fila de KPI de colores | 3 tarjetas con acentos **distintos y AA** (no solo teal Contactos) | 12 columnas Bootstrap; cifras hardcode |
| Área + barras + número grande | Swift Charts + `home.total` | Chart.js, sparkline web |
| Widgets social / inbox | Omitir | Feeds, avatares stock de la plantilla |
| Tipografía web / iconos Glyphicons | SF Pro + SF Symbols | Fuentes de la plantilla; PNG de MixPro |

Criterio de review (Quality): si un screenshot lado a lado revela assets o copy de MixPro → **BLOCK**. Si solo se reconoce el patrón de admin → **OK**.

---

## 4. User stories + criterios de aceptación

Estimación en camisetas **propuesta**; **no es compromiso** hasta validación Architect + Developer (constraint del rol PM).

### US-01 — Enmendar contratos (Slice A)

**Como** equipo, **quiero** ADR y specs UX actualizados, **para** implementar el dashboard sin contradecir ADR-002 / DS.

**MoSCoW**: Must (docs)  
**Talla propuesta**: S  
**Owner**: Architect (ADR) + UX (spec visual)  
**AC**

- [ ] AC-01 Existe `docs/adr/ADR-003-dashboard-resumen-swift-charts.md` (o enmienda explícita a ADR-002 §Inicio) que autoriza KPI + Charts y **prohíbe** HTTP extra / WebView / Chart.js.
- [ ] AC-02 UX publica spec que **anula** «No gráficos / No KPI» de `design-system-usuarios.md` §2 y `login-home-logout.md` §6 **solo** en el sentido de este MoSCoW (no autoriza MixPro HTML).
- [ ] AC-03 La spec lista tokens de color de las 3 KPI con contraste AA (1.4.3) Light/Dark; prohíbe blanco sobre acento Dark insuficiente.
- [ ] AC-04 Identifiers nuevos documentados; `home.total`, `shell.*`, `login.*`, `toolbar.logout` no se renombran.

### US-02 — KPI reales en Inicio (Slice B)

**Como** usuario autenticado, **quiero** ver cuántos usuarios, ciudades y empresas hay, **para** entender el directorio de un vistazo.

**MoSCoW**: Must  
**Talla propuesta**: M  
**Owner**: Developer (tras US-01)  
**AC**

- [ ] AC-05 Tras login, Inicio muestra 3 KPI: usuarios, ciudades distintas, empresas distintas, calculadas sobre el `[Usuario]` de `ListarUsuariosCasoUso`.
- [ ] AC-06 Si la carga falla sin cache, las KPI **no** muestran «0 usuarios» / «0 ciudades» como si el directorio estuviera vacío (reutilizar `COPY-HOME-TOTAL-NA` o copy UX equivalente).
- [ ] AC-07 0 usuarios con 200 OK **sí** muestra ceros (vacío ≠ error).
- [ ] AC-08 Alta en sesión (overlay) incrementa las KPI al volver a Inicio **sin** métricas hardcode.
- [ ] AC-09 Identifiers: `home.total` (cifra usuarios), `home.kpi.ciudades`, `home.kpi.empresas`.
- [ ] AC-10 VoiceOver: cada KPI es texto estático (no botón) salvo que UX las haga navegación; entonces el nombre accesible contiene el título visible (2.5.3).

### US-03 — Gráfico de área por ciudad (Slice B)

**Como** usuario autenticado, **quiero** un área de usuarios por ciudad, **para** ver concentración geográfica del dataset.

**MoSCoW**: Must  
**Talla propuesta**: M  
**Owner**: Developer  
**AC**

- [ ] AC-11 Un `Chart` con `AreaMark` visible en Inicio; `import Charts` (Apple).
- [ ] AC-12 Categorías = ciudades reales del listado; Y = conteo. Título **no** contiene Visitas/Traffic/Analytics.
- [ ] AC-13 Identifier `home.chart.area`.
- [ ] AC-14 Accesible: el gráfico no es un lienzo mudo. `accessibilityLabel` (o tabla equivalente) resume «Usuarios por ciudad: {ciudad} {n}; …» (máx. Top N + Otros si UX lo recorta).
- [ ] AC-15 Reduce Motion: sin animación bounce de área (transición sistema o ninguna).

### US-04 — Gráfico de barras por empresa (Slice B)

**Como** usuario autenticado, **quiero** barras de usuarios por empresa, **para** ver distribución organizacional.

**MoSCoW**: Must  
**Talla propuesta**: M (puede empaquetarse con US-03)  
**Owner**: Developer  
**AC**

- [ ] AC-16 Un `Chart` con `BarMark`; mismos datos `[Usuario]`.
- [ ] AC-17 Identifier `home.chart.barras`.
- [ ] AC-18 Mismo estándar a11y que AC-14.
- [ ] AC-19 No hay un tercer `Chart` en este epic (Could C01).

### US-05 — Sidebar admin (Slice C)

**Como** usuario autenticado, **quiero** una barra lateral de consola, **para** cambiar entre dashboard y usuarios.

**MoSCoW**: Must  
**Talla propuesta**: S–M  
**Owner**: Developer + UX  
**AC**

- [ ] AC-20 `shell.inicio` / `shell.usuarios` / `shell.sidebar` intactos.
- [ ] AC-21 Cabecera de producto «Gestión de usuarios» (o copy UX cerrado); **cero** MixPro/Bootstrap.
- [ ] AC-22 Destino por defecto post-login = Inicio (dashboard).
- [ ] AC-23 Un solo split de shell; Usuarios sigue hospedando lista|detalle **sin** anidar un segundo split de destinos (ADR-002).
- [ ] AC-24 Full Keyboard Access: ↑↓ entre destinos.

### US-06 — No-regresión sesión y CRUD (Slice E)

**Como** usuario, **quiero** el mismo login/logout y CRUD, **para** no perder el producto actual.

**MoSCoW**: Must  
**Talla propuesta**: S (regresión)  
**Owner**: Developer + QA  
**AC**

- [ ] AC-25 Arranque = `login.usuario`; clave nunca en UI.
- [ ] AC-26 `administrador` + clave demo → Inicio dashboard (no CRUD directo).
- [ ] AC-27 Destino Usuarios: identifiers §11.1 de `login-home-logout.md` verdes.
- [ ] AC-28 Logout toolbar + menú; sucio → `COPY-DISCARD`; overlay vacío (test existente de `CerrarSesionCompuesto`).
- [ ] AC-29 UITest de alta: login helper **antes** de `toolbar.nuevo` / `form.nombre`.
- [ ] AC-30 Domain/Data de auth y usuarios **sin** cambio de contratos salvo el value object de resumen que Architect autorice.

### US-07 — Alinear login y lista (Slice D)

**Como** usuario, **quiero** que login y el CRUD no parezcan otra app, **para** que el rediseño sea de *toda* la interfaz.

**MoSCoW**: Should  
**Talla propuesta**: M  
**Owner**: Developer (tras spec UX)  
**AC**

- [ ] AC-31 Login usa los tokens nuevos (fondo, tarjeta, acento) definidos por UX para el admin; identifiers `login.*` intactos.
- [ ] AC-32 Lista/detalle/sheet no revierten al «inspector vacío»; tokens de chrome alineados; identifiers `lista.*` / `detalle.*` / `form.*` intactos.
- [ ] AC-33 Si el tiempo no alcanza: documentar gap en §12 backlog P1; **no** bloquear GitHub si Must B+C+E están verdes **y** el usuario acepta el gap. Default de este P0: **intentar S01+S02 en el mismo ciclo** porque el pedido fue «TODA la interfaz».

**Calibración P0 vs Should:** el pedido verbal es «toda la interfaz». En MoSCoW estricto login/lista son Should; en **prioridad de sprint** se tratan como **Must de hecho** si UX entrega tokens a tiempo. Si Architect/Dev señalan overflow, PM recorta Could, no M01–M11.

### US-08 — Push a GitHub (Slice F)

**Como** dueño del repo, **quiero** el código en GitHub, **para** no dejar el trabajo solo en disco local.

**MoSCoW**: Must (secuenciado **después** de build/test verdes del dashboard)  
**Talla propuesta**: S  
**Owner**: Developer (git) — **no** este entregable PM  
**AC**

- [ ] AC-34 `git status` limpio respecto a lo que se publica (sin secretos, sin DerivedData).
- [ ] AC-35 Remoto `https://github.com/waldofeliz/GestionUsuarios.git` contiene al menos un commit con app + docs.
- [ ] AC-36 README de desarrollo puede documentar credenciales demo; copy de producto **no**.
- [ ] AC-37 No hay `Verificador` plaintext comentado tipo `clave == "123456"` en Domain (regla ADR-002).
- [ ] AC-38 Primer commit **no** incluye HTML MixPro ni assets de la plantilla.

---

## 5. Priorización RICE (dentro del epic)

Escala: Reach 1–10 (usuarios de demo = 1 persona, pero P0 de dueño → Reach 8 para Must de UI). Impact 0.25–3. Confidence %. Effort = talla (1 S, 2 M, 4 L).

| Ítem | R | I | C | E | RICE | Orden |
|------|--:|--:|--:|--:|-----:|------:|
| US-01 Contratos | 8 | 3 | 0,9 | 1 | 21,6 | 1 |
| US-02 KPI | 8 | 3 | 0,8 | 2 | 9,6 | 2 |
| US-03+04 Charts | 8 | 3 | 0,7 | 2 | 8,4 | 3 |
| US-05 Sidebar | 8 | 2 | 0,8 | 2 | 6,4 | 4 |
| US-06 Regresión | 8 | 3 | 0,9 | 1 | 21,6 | paralelo a 2–5 |
| US-07 Login+lista | 8 | 2 | 0,7 | 2 | 5,6 | 5 (Should elevado) |
| US-08 GitHub | 8 | 2 | 0,9 | 1 | 14,4 | 6 último |

OAuth, WebView, Chart.js: **no puntúan** (Won't).

---

## 6. Riesgos

| ID | Riesgo | Sev. | Mitigación | Owner |
|----|--------|------|------------|-------|
| R1 | Contratos UX/ADR actuales **prohíben** el pedido | Alta | Este MoSCoW es la enmienda de producto; US-01 obligatorio antes de código | PM (hecho) → Arch/UX |
| R2 | Dataset n≈10 → gráficos «planos» (1 por categoría) | Media | Aceptado §3.1; UX Top-N; **prohibido** rellenar con visitas | UX + Dev |
| R3 | Developer embebe MixPro o Chart.js «para ir más rápido» | Alta | Must not MN01–MN04; Code Review BLOCK | Review |
| R4 | Segundo HTTP o `ContarUsuarios` | Media | ADR-003: solo `ListarUsuariosCasoUso` | Architect |
| R5 | Nested `NavigationSplitView` al «poner sidebar admin» | Media | Reusar shell ADR-002; no un tercer split | Architect + Dev |
| R6 | Charts poco accesibles (lienzo mudo) | Media | AC-14/18; G10 CONDITIONAL hasta Inspector | UX + QA |
| R7 | KPI de color fallan AA (estilo Bootstrap vivo) | Alta | Tokens UX con ratio ≥ 4,5:1; no texto blanco sobre pastel | UX |
| R8 | Repo sin git + remoto vacío: push falla (auth, .gitignore) | Media | US-08 al final; `.gitignore` Xcode estándar; no DerivedData | Dev |
| R9 | Estimación sin input Dev (constraint PM) | Media | Tallas §4 = **propuesta**; Architect/Dev confirman o recortan US-07 | Arch + Dev |
| R10 | Clave demo en README público de GitHub | Baja | CRED-04: README desarrollo sí; UI no. Security ya cubrió verifier | Dev + Sec |
| R11 | «Toda la interfaz» vs Should S01/S02 | Media | Sprint trata S01/S02 como Must de hecho; overflow → recortar Could, no M01–M11 | PM |

No hay fecha firme. Buffer: si Charts + a11y + alineación login desbordan **un** ciclo de un Dev, entregar Must B+C+E+F y dejar S01/S02 como hotfix P1 **solo** con acuerdo explícito del usuario.

---

## 7. Estimación (propuesta, no compromiso)

**Supuestos**

- 1 Developer macOS con el repo ya compilando (CRUD + login hechos).
- Architect y UX entregan Slice A en el mismo día calendario (docs, no código).
- No hay CI que configurar (Wont C05).
- n≈10: agregación trivial (no DBA, no índice).
- `Charts` está en el SDK macOS 27 (sin SPM). Architect **debe** confirmar linkage del framework en el target.

| Slice | Talla | Rango orientativo (un Dev, horas foco) |
|-------|-------|----------------------------------------|
| A Contratos | S | 2–4 h (docs) |
| B Dashboard + Charts | M | 6–10 h |
| C Sidebar chrome | S–M | 3–5 h |
| D Login + lista (Should elevado) | M | 4–8 h |
| E Regresión tests | S | 2–4 h |
| F GitHub | S | 1–2 h |
| **Total propuesto** | **~1 ciclo** | **18–33 h** |

**No hay fecha de calendario.** Si Dev estima L en Charts+a11y, PM parte US-03/US-04 en «marca visible + a11y label» (aún Must) vs. recorte visual fancy (Could).

---

## 8. Plan de ejecución (orden, no sprint Scrum con fechas)

```
Día lógico 0  PM (este doc)                         ← ahora
Día lógico 1  Architect ADR-003  ∥  UX spec visual (tras viabilidad Charts = sí)
Día lógico 2–4 Developer Slice B+C+E (+ D si cabe)
Día lógico 4  QA AC + Review + G10 degradado Inspector
Día lógico 5  US-08 git init/commit/push (cuando el usuario/Dev lo ejecute)
```

**Bloqueos**

1. Código de dashboard **antes** de ADR-003 → no.
2. Push GitHub **antes** de build/test del dashboard → no (el remoto vacío espera el producto, no un dump a medias). *Excepción*: el usuario puede pedir commit intermedio; entonces es otro alcance.
3. `VerificadorCredencialesDemo` no se reabre.

Agentes **no** invocados en este epic (SKIP con razón): DBA (sin persistencia nueva), AI/ML, Performance (n≈10, `degraded: qualitative` si alguien lo pide), DevOps CI (Could C05). Security: **no** hay superficie HTTP nueva; G4 existente de auth sigue vigente; Charts no añade red. Review G3 post-código.

---

## 9. Dependencias

```
EE-PM-20260919-4
    └── este alcance
            ├── PM-ARCH-20260919-4  @software-architect-agent
            ├── PM-UX-20260919-4    @ux-accessibility-agent   (puede paralelizar tras «Charts = Apple OK»)
            └── PM-DEV-20260919-4   @senior-fullstack-developer-agent  (espera A)
                    ├── G2 build / G6 tests
                    ├── G3 @code-review-agent
                    ├── G10 @ux-accessibility-agent (Inspector, degradado)
                    └── US-08 push GitHub
```

QA Automation no recibe handoff propio en esta entrega: los AC de §4 **son** el input; invocación `@qa-automation-engineer-agent` post-código si el orquestador lo pide.

---

## 10. Definition of Done (epic)

- [ ] MoSCoW Must M01–M11 cumplidos (M11 = remoto GitHub con commit).
- [ ] Must not MN01–MN08 verificados en review (screenshot + `grep` Chart.js/WKWebView/MixPro = 0).
- [ ] Should S01–S02 hechos **o** gap P1 escrito con acuerdo.
- [ ] Build: `xcodebuild -scheme GestionUsuarios -destination 'platform=macOS'` verde.
- [ ] Test: `xcodebuild test -scheme GestionUsuarios -destination 'platform=macOS'` verde (unit + UI con login helper).
- [ ] ADR-001/002 no violados (capas, auth local, un WindowGroup, overlay + logout compuesto).
- [ ] UI en español; cero copy MixPro/Bootstrap.
- [ ] G0 PASS (contexto). G1 = ADR-003. G2/G3/G6 post-código. G10 CONDITIONAL máximo hasta Inspector (`degraded`). G4 SKIP Charts (sin superficie nueva) / vigente auth. G5/G7/G8/G9 SKIP.

---

## 11. Enmiendas a contratos previos (tabla de producto)

| Contrato | Antes | Ahora (este epic) |
|----------|-------|-------------------|
| DS §2 «No dashboard KPI» | Prohibido | **Permitido** KPI 3 + 2 Charts nativos; sigue prohibido grid Bootstrap 12 col y WebView |
| login-home-logout §6 | Hero + 1 total + 2 acciones; no gráficos | Hero/cifra + 3 KPI + área + barras; las 2 acciones (Ver usuarios / Nuevo) **Should** conservarse como accesos (no son métricas inventadas) |
| ADR-002 Inicio = un número | Contrato de datos: `count` | Contrato de datos: `count` + agregados ciudad/empresa sobre el **mismo** `[Usuario]` |
| Identifiers `home.total` `home.verLista` `home.nuevo` | Obligatorio | `home.total` Must; `home.verLista` / `home.nuevo` Should (si el layout admin no deja sitio, UX propone 1 acceso primario + ⌘N; no borrar identifiers si el control existe) |

Navegación CRUD, menú, sandbox, auth local: **sin cambio**.

---

## 12. Backlog explícito (no scope creep)

| ID | Ítem | Prioridad |
|----|------|-----------|
| BL-01 | CI GitHub Actions `xcodebuild` | P2 (C05) |
| BL-02 | Cuarta KPI «con sitio web» | P2 (C02) |
| BL-03 | A11y automatizada de Charts (snapshot VoiceOver) | P2 |
| BL-04 | Si S01/S02 no entran: hotfix visual login/lista | P1 condicional |
| BL-05 | Documentar en README cómo abrir Accessibility Inspector sobre KPI | P2 |

---

## Quality Gate Status (PM — planning)

| Gate | Status | Evidencia | Notas |
|------|--------|-----------|-------|
| G0 Context | PASS | Handoff EE-PM-20260919-4 + este archivo | Swift 5 / SwiftUI / macOS 27; ADR-001/002 |
| G1–G10 resto | SKIP | Planning; no hay código de este epic | G1 lo cierra Architect en ADR-003 |

---

## Referencias

- ADR-001 `docs/adr/ADR-001-clean-architecture-usuarios.md`
- ADR-002 `docs/adr/ADR-002-autenticacion-demo-y-shell.md`
- UX `docs/ux/design-system-usuarios.md`, `docs/ux/login-home-logout.md`, `docs/ux/navegacion-usuarios.md`
- JSONPlaceholder `GET /users` (campos `address.city`, `company.name`)
- Apple Swift Charts — `import Charts` (SDK macOS)
- AgentesAI: `agent-handoff.md`, `quality-gates.md` (backlog = G0)

---

## Handoff: @technical-pm-agent → @software-architect-agent

**Handoff-ID**: PM-ARCH-20260919-4  
**Prioridad**: P0

### Contexto detectado

- Stack: Swift 5 / SwiftUI / macOS 27 (NO web, NO Bootstrap, NO jQuery)
- Arquitectura: ADR-001 CRUD JSONPlaceholder + ADR-002 login demo local (Accepted). App ya tiene shell Inicio \| Usuarios, `ListarUsuariosCasoUso`, overlay, logout compuesto.
- DB/ORM: no aplica
- Build: `xcodebuild -scheme GestionUsuarios -destination 'platform=macOS'`
- Test: Swift Testing + XCTest UI
- Lint: no detectado
- CI: no detectado
- Constraints: español; App Sandbox; no clonar MixPro; Charts = framework Apple, no Chart.js; KPI solo de `[Usuario]`; repo sin commits; remoto GitHub vacío pedido

### Alcance

- **Incluye**: ADR-003 (o enmienda ADR-002) que autorice dashboard de resumen: 3 KPI + `AreaMark` + `BarMark`; dónde vive la agregación (Presentation vs value object Domain `ResumenDirectorio`); linkage de `Charts.framework`; confirmar **cero** HTTP extra; confirmar que el shell actual se reusa (no nested split, no WebView); impacto en `ContenedorDependencias` (probablemente ninguno).
- **Excluye**: Views de producción; tokens de color; OAuth; DBA; implementar código.
- **Archivos afectados**: `docs/adr/ADR-003-*.md` (nuevo) y/o enmienda a ADR-002 §Inicio.

### Artefactos entregados

- `docs/pm/alcance-admin-dashboard.md` (MoSCoW, AC, §3.1 series honestas)

### Decisiones tomadas (PM — Architect puede vetar lo técnico)

| Decisión | Justificación | Alternativa descartada |
|----------|---------------|------------------------|
| Enmendar «no KPI» de UX/ADR-002 | Pedido P0 del usuario | Rechazar el dashboard y ofrecer solo el home actual |
| Agregar sobre `ListarUsuariosCasoUso` | Un GET, n≈10, ADR-002 ya lo usa | `ContarUsuariosCasoUso` + HTTP extra |
| Área = usuarios por ciudad; barras = por empresa | Únicos ejes reales; no hay timestamps | Área de «visitas» (métrica inventada) |
| Apple Charts, no SPM JS | Stack nativo macOS 27 | Chart.js, WKWebView MixPro |
| Value object de resumen = Architect | PM no prescribe capas de más | Forzar nuevo caso de uso HTTP |

### Riesgos abiertos

| Riesgo | Severidad | Requiere validación de |
|--------|-----------|------------------------|
| `Charts` no enlazado en el target / disponibilidad SDK | Alta | Architect (confirmar) |
| Agregar en Presentation vs Domain | Media | Architect (pureza ADR-001) |
| Nested split al «hacer sidebar más admin» | Media | Architect |
| ÁreaMark sobre categorías (no tiempo) idiomático | Baja | Architect + UX |

### Criterio de éxito

- [ ] ADR Accepted con contratos (quién agrega, qué Marks, qué queda prohibido)
- [ ] Handoff Arch → Dev con nombres Swift del resumen
- [ ] G1 PASS con path del ADR
- [ ] Superficie HTTP **idéntica** a ADR-001 (G4 no se reabre por Charts)

### Gates pendientes

| Gate | Esperado |
|------|----------|
| G1 | ADR-003 o enmienda ADR-002 |
| G4 | SKIP si no hay superficie nueva (confirmar en el ADR) |

### Comandos de verificación

- Build: `xcodebuild -scheme GestionUsuarios -destination 'platform=macOS'`
- Test: `xcodebuild test -scheme GestionUsuarios -destination 'platform=macOS'`
- Lint: no detectado

**Siguiente:** invoca `@software-architect-agent` con este handoff.

---

## Handoff: @technical-pm-agent → @ux-accessibility-agent

**Handoff-ID**: PM-UX-20260919-4  
**Prioridad**: P0

### Contexto detectado

(mismo bloque que PM-ARCH-20260919-4)

### Alcance

- **Incluye**: spec visual que **enmienda** DS §2 y `login-home-logout.md` §6; layout Inicio tipo admin (sidebar + 3 KPI color + cifra grande + área + barras); Should: login + lista/detalle con los **mismos tokens**; copy español cerrado; identifiers aditivos `home.kpi.ciudades`, `home.kpi.empresas`, `home.chart.area`, `home.chart.barras`; a11y de Charts (resumen VoiceOver, no solo color); contraste AA de tarjetas de color (Light/Dark/IC); receta para n≈10 categorías planas (Top N + Otros o scroll); **prohibir** marca MixPro, logos Bootstrap/jQuery, feeds sociales, tipografía/assets de la plantilla.
- **Excluye**: código Swift; clonar MixPro píxel a píxel; OAuth; WebView.
- **Archivos afectados**: nuevo `docs/ux/admin-dashboard.md` (preferido) **o** enmiendas explícitas a `design-system-usuarios.md` + `login-home-logout.md`. Conservar identifiers invariantes.

### Artefactos entregados

- MoSCoW §3–§4, traducción MixPro → nativo §3.2, AC de a11y AC-10/14/18

### Decisiones tomadas (PM — UX cierra layout y tokens)

| Decisión | Justificación | Alternativa descartada |
|----------|---------------|------------------------|
| 3 KPI (usuarios, ciudades, empresas) + cifra = total usuarios | Pedido + datos reales | 4ª tarjeta de visitas; 12 columnas |
| Conservar destinos Inicio \| Usuarios | ADR-002 / login-home | Ítems extra tipo MixPro (Inbox, Calendar) |
| Should = toda la app con el look | Pedido «TODA la interfaz» | Pintar solo Inicio y dejar login teal Contactos |
| Accesos Ver usuarios / Nuevo: Should | No son métricas falsas; caben como CTA | Obligar 2 tarjetas extra si el layout admin no tiene sitio — UX decide 1 CTA + ⌘N |
| G10 CONDITIONAL hasta Inspector | Igual que specs previas | PASS sin runtime |

### Riesgos abiertos

| Riesgo | Severidad | Requiere validación de |
|--------|-----------|------------------------|
| Colores tipo Bootstrap no llegan a 4,5:1 | Alta | UX (calcular ratios como en DS §3) |
| Chart mudo para VoiceOver | Alta | UX receta AC-14 |
| Sidebar «dark custom» vs material sistema / Reduce Transparency | Media | UX HIG macOS |
| Copyright: demasiado parecido a screenshot MixPro | Alta | UX: patrón, no assets; Review screenshot |

### Criterio de éxito

- [ ] Spec con receta Inicio + tokens KPI AA + copy + identifiers
- [ ] Enmienda explícita a la prohibición de gráficos
- [ ] Checklist G10 (teclado, VO de gráficos, contraste, sin MixPro)
- [ ] Handoff UX → Dev con archivos Presentation a tocar

### Gates pendientes

| Gate | Esperado |
|------|----------|
| G10 | CONDITIONAL `degraded: revisión manual WCAG` (spec); PASS real post-Inspector |

### Comandos de verificación

- Build / Test: los del contexto (post-código)
- A11y: Accessibility Inspector Light/Dark/IC sobre KPI y Charts (`degraded`)

**Siguiente:** invoca `@ux-accessibility-agent` con este handoff (paralelizable con Architect una vez Charts = framework Apple).

---

## Handoff: @technical-pm-agent → @senior-fullstack-developer-agent

**Handoff-ID**: PM-DEV-20260919-4  
**Prioridad**: P0  
**Bloqueo:** no implementar dashboard hasta ADR-003 (PM-ARCH) y spec UX (PM-UX). Este handoff adelanta el contrato de producto.

### Contexto detectado

(mismo bloque que PM-ARCH-20260919-4)

### Alcance

- **Incluye** (cuando A esté listo): Presentation Inicio con 3 KPI + cifra + 2 Swift Charts; chrome sidebar admin; conservar login/logout/CRUD; tests de agregación (ciudades/empresas a partir de fixtures); UITests identifiers nuevos + helper de login; Should login/lista tokens; **después** build/test verdes: `git` inicial + push a `https://github.com/waldofeliz/GestionUsuarios.git` (US-08) **solo si el usuario/orquestador lo autoriza en ese momento**.
- **Excluye**: WebView, Chart.js, MixPro HTML/assets, OAuth, HTTP nuevo, Domain auth, cambiar verifier, CI.
- **Archivos afectados** (orientativos, Architect/UX pueden ajustar):
  - `GestionUsuarios/Presentation/Inicio/InicioVista.swift`
  - `GestionUsuarios/Presentation/AppShell/*`
  - `GestionUsuarios/Presentation/Tema/TemaUsuarios.swift`
  - `GestionUsuarios/Presentation/Navegacion/TextosUsuarios.swift`
  - `GestionUsuarios/Presentation/Autenticacion/LoginVista.swift` (Should)
  - `GestionUsuarios/Presentation/Usuarios/**` (Should chrome)
  - Target: enlace `Charts.framework`
  - Tests: agregación + UI
  - **No** Domain HTTP; **sí** value object si ADR-003 lo pide

### Artefactos entregados

- Este alcance (AC US-02…US-08)

### Decisiones tomadas

| Decisión | Justificación | Alternativa descartada |
|----------|---------------|------------------------|
| Esperar Arch + UX | Evitar pintar KPI que ADR prohíba o colores que fallen AA | Code-first contra DS vigente |
| Fixtures para tests de conteo ciudad/empresa | G6 sin red | Solo UITests |
| GitHub al final del epic | Remoto vacío; no publicar a medias | Push de este doc PM ahora (no pedido como commit aislado) |

### Riesgos abiertos

| Riesgo | Severidad | Requiere validación de |
|--------|-----------|------------------------|
| Estimación 18–33 h sin acuerdo Dev | Media | Dev confirma tallas |
| Primer `git init` en carpeta con DerivedData | Media | `.gitignore` Xcode |
| Romper UITest `home.total` | Alta | Conservar identifier |

### Criterio de éxito

- [ ] AC Must §4 (US-02 a US-06, US-08) 
- [ ] `grep` en el repo: 0 MixPro / Chart.js / WKWebView de plantilla
- [ ] Build y test macOS verdes
- [ ] Should US-07 o gap BL-04 documentado

### Gates pendientes

| Gate | Esperado |
|------|----------|
| G2 | Build verde |
| G6 | Tests agregación + UI login + identifiers |
| G3 | Review post-código |
| G10 | UX Inspector (degraded CONDITIONAL aceptable) |

### Comandos de verificación

- Build: `xcodebuild -scheme GestionUsuarios -destination 'platform=macOS'`
- Test: `xcodebuild test -scheme GestionUsuarios -destination 'platform=macOS'`
- Lint: no detectado
- Copyright smoke: `rg -i 'mixpro|chart\\.js|bootstrap' --glob '!docs/pm/**'` debe ser vacío en código

**Siguiente:** no implementar aún. Invoca primero `@software-architect-agent` y `@ux-accessibility-agent`. Luego `@senior-fullstack-developer-agent` con ADR-003 + spec UX pegados a este handoff.
