# UX / Accesibilidad — Panel de inicio tipo administración (macOS)

**Handoff origen**: EE-UX-20260919-4  
**Handoff destino**: UX-DEV-20260919-4  
**Owner**: `@ux-accessibility-agent`  
**Destino implementación**: `@senior-fullstack-developer-agent`  
**Fecha**: 2026-09-19  
**Plataforma**: macOS 27 · SwiftUI · **no iOS**  
**Idioma UI**: español (`es`)  
**Contratos previos (no se relajan salvo las enmiendas puntuales de §2)**:
- `docs/ux/navegacion-usuarios.md` — IA CRUD, menú, atajos, copy base, WCAG, identifiers de usuarios
- `docs/ux/design-system-usuarios.md` — tokens teal, avatares, tarjetas, wells, contraste AA
- `docs/ux/login-home-logout.md` — login demo, shell Inicio/Usuarios, logout, identifiers `login.*` / `toolbar.logout`
- `docs/adr/ADR-001-clean-architecture-usuarios.md` — capas Domain/Data/Presentation
- `docs/adr/ADR-002-autenticacion-demo-y-shell.md` — sesión RAM, un `WindowGroup`, un solo `NavigationSplitView`

**G10**: `CONDITIONAL` (`degraded: revisión manual WCAG`) hasta Accessibility Inspector post-implementación.

Este documento es el contrato **visual y a11y** del lienzo de login, del sidebar autenticado y del **Inicio** con KPI + gráficos. No es código de producción. **No** copia MixPro, Bootstrap, jQuery ni logos de terceros.

---

## 1. Qué resuelve

Hoy el login vive sobre `windowBackgroundColor` plano y el Inicio es un resumen de escritorio (hero + 1 total + 2 accesos). El producto pide un **mood de panel de administración nativo**:

1. Login: **la misma tarjeta 420** sobre un **lienzo con degradado azul de sistema**.
2. Shell autenticado: sidebar de destinos más «admin» (fondo distinto + ítem activo con acento, no solo tinte).
3. Inicio: **fila de 4 KPI** (Usuarios, Ciudades, Empresas, Altas de sesión) + **área** (usuarios por ciudad) + **barras** (empresas) + accesos **Ver usuarios** / **Nuevo**.

Flujo intacto: **Login → Inicio → Usuarios (CRUD) → Logout → Login**. Una sola `WindowGroup`.

**Fuera de alcance**

- Código Swift de producción (este archivo es spec).
- AuthN real, OAuth, Keychain de producto.
- `TabView`, `NavigationStack` raíz, patrón iPhone.
- Feeds sociales vacíos, widgets de correo rápido, «visitantes», porcentajes de analítica inventados.
- Números de marketing (450, 6 374, series anuales ficticias). Toda cifra sale de `ListarUsuariosCasoUso` / la lista ya cargada.
- WebView, Bootstrap, jQuery, Chart.js, assets del marketing MixPro.
- Relajar identifiers `login.*`, `toolbar.logout`, `form.*`, `lista.*`.

---

## 2. Enmiendas puntuales a contratos previos

Solo lectura: este documento **sustituye la receta visual de `S-HOME`** y **ajusta** login/sidebar. No reabre el CRUD.

| Contrato previo | Cambio |
|-----------------|--------|
| `design-system-usuarios.md` §2 — «No: dashboard web KPI» | **Excepción acotada a `S-HOME`**: 4 KPI + 2 gráficos nativos Swift Charts. Sigue prohibido grid de 12 columnas, sombras > 8 pt, feeds sociales y chrome web. |
| `design-system-usuarios.md` §3.8 — sidebar solo material de sistema | **Excepción** en la lista de destinos (`shell.sidebar`): fondo distinto + acento de ítem activo (§7). El `List` de usuarios **sigue** `.listStyle(.sidebar)` nativo. |
| `login-home-logout.md` §5.1 — lienzo login = `windowBackgroundColor` | Lienzo = **degradado azul de sistema**; la tarjeta 420 **no cambia** de contenido ni identifiers. |
| `login-home-logout.md` §6 — Inicio = hero + 1 total + 2 acciones, max 720 | Inicio = hero + **4 KPI** + **2 gráficos** + 2 acciones. Ancho máximo de columna **960**. `home.total` **se retira** a favor de `home.kpi.usuarios`. |
| `login-home-logout.md` SHELL-02 — no color sólido custom | Enmendado en §7 para destinos. Selección **no** es solo color (1.4.1). |
| `login-home-logout.md` §2 — «Inicio usa 2–3 tarjetas, no grid de métricas» | Superado por esta spec. |

Navegación, atajos, validación, sheet 420, `toolbar.logout`, menú Cuenta, identifiers `login.*` / `form.*` / `lista.*` / `detalle.*` / `estado.*` **no se tocan**.

---

## 3. Norte estético (inspiración ≠ copia)

**Mood de referencia** (captura de marketing tipo panel web): fila de 4 tarjetas de color, gráfico de área a la izquierda, barras a la derecha, sidebar con ítem activo. Eso informa **jerarquía**, no la marca ni el toolkit.

**Sí (nativo macOS)**

- SwiftUI + **Swift Charts** (`import Charts`).
- SF Symbols + Dynamic Type + Dark Mode + Increase Contrast + Reduce Transparency + Reduce Motion.
- Tokens teal existentes (`TemaUsuarios`, `AccentColor`, wells, tarjetas opacas).
- Copy en español; números **derivados** de `[Usuario]`.

**No (copia o web)**

| Prohibido | Por qué |
|-----------|---------|
| Nombre, logo o chrome «MixPro» / «MixPro Admin» | Marca de terceros |
| Badges jQuery, HTML5, Bootstrap o logotipo Bootstrap | Toolkit web; esta app es AppKit/SwiftUI |
| Degradado o captura como **asset de imagen** del marketing | No es un recurso del producto; el lienzo se pinta con colores de **sistema** |
| Feeds Twitter / Facebook / Google+ vacíos, «Quick Email», «Our Visitors» | Ruido; no hay datos |
| Curva «Products Yearly Sales» con meses inventados | Viola «no números inventados» |
| `TabView`, `WKWebView` de dashboard, CSS Bootstrap, Chart.js | Fuera de arquitectura |
| KPI cuyo único distintivo sea el color | WCAG 1.4.1 |

---

## 4. Tokens nuevos (aditivos)

Namespace: `TemaUsuarios`. No sustituyen `DS-ACCENT`. Espacio **sRGB**, alpha 1,0.

### 4.1 KPI — rellenos (cyan / naranja / verde / azul)

Los rellenos «caramelo» del marketing (~`#00BCD4`, `#FF9800`, `#4CAF50`, `#2196F3`) con **texto blanco** fallan 1.4.3 (ratios 2,16–3,12). **Prohibido** copiarlos con blanco.

Se reutilizan hex **ya calculados** en la paleta de avatares / acento (Light) y variantes más oscuras en Dark e Increase Contrast. Texto e icono sobre el relleno: **`#FFFFFF`**.

| Token | Uso | Light | Dark | IC Light | IC Dark |
|-------|-----|-------|------|----------|---------|
| `DS-KPI-CYAN` | Usuarios | `#0B6E75` | `#085258` | `#084F54` | `#063F43` |
| `DS-KPI-ORANGE` | Ciudades | `#B85A00` | `#8A4300` | `#7A3A00` | `#5C2C00` |
| `DS-KPI-GREEN` | Empresas | `#1F7A4D` | `#165C3A` | `#125434` | `#0E4028` |
| `DS-KPI-BLUE` | Altas de sesión | `#125EAB` | `#0E4680` | `#0C3E70` | `#0A325A` |
| `DS-KPI-FG` | Label + valor + icono sobre KPI | `#FFFFFF` | `#FFFFFF` | `#FFFFFF` | `#FFFFFF` |

Componentes 0–255:

| Token / apariencia | R | G | B |
|--------------------|--:|--:|--:|
| Cyan Light | 11 | 110 | 117 |
| Cyan Dark | 8 | 82 | 88 |
| Cyan IC Light | 8 | 79 | 84 |
| Cyan IC Dark | 6 | 63 | 67 |
| Naranja Light | 184 | 90 | 0 |
| Naranja Dark | 138 | 67 | 0 |
| Naranja IC Light | 122 | 58 | 0 |
| Naranja IC Dark | 92 | 44 | 0 |
| Verde Light | 31 | 122 | 77 |
| Verde Dark | 22 | 92 | 58 |
| Verde IC Light | 18 | 84 | 52 |
| Verde IC Dark | 14 | 64 | 40 |
| Azul Light | 18 | 94 | 171 |
| Azul Dark | 14 | 70 | 128 |
| Azul IC Light | 12 | 62 | 112 |
| Azul IC Dark | 10 | 50 | 90 |

**Prohibido** sobre relleno KPI: `Color.secondary`, blanco a opacidad &lt; 1, `#5EC8C0` como texto.

Radio KPI: `DS-RADIUS-CARD` (10). Sin sombra &gt; 8 pt; preferible **cero sombra**. Increase Contrast: stroke 1 pt `Color.primary.opacity(0.45)` **además** del relleno (el stroke delimita el bloque; el texto sigue siendo blanco sobre el relleno).

### 4.2 Login — degradado de sistema (no asset)

No hay PNG. El ZStack del login sustituye `TemaUsuarios.ventana` a pantalla completa por un `LinearGradient` de **colores de sistema**:

| Apariencia | Receta |
|------------|--------|
| Light | `Color(nsColor: .systemBlue)` → `Color(nsColor: .systemIndigo)`, `start: topLeading`, `end: bottomTrailing` |
| Dark | Igual (los `nsColor` de sistema ya oscurecen) |
| Increase Contrast | Degradado **más corto**: `systemBlue` sólido al 100 % **o** dos paradas del mismo `systemBlue` (se lee como lienzo, no arcoíris). La tarjeta conserva stroke IC 1 pt |
| Reduce Transparency | El degradado es opaco (no blur). Sin `.ultraThinMaterial` detrás de la tarjeta |

La **tarjeta 420** sigue `DS-CARD` + `estiloTarjetaUsuarios`. En Dark, tarjeta vs azul oscuro puede quedar &lt; 3:1 (1.4.11): **obligatorio** stroke visible (ya en el estilo; en Dark default subir overlay a `Color.primary.opacity(0.35)` si Inspector midiera &lt; 3:1).

**LOGIN-GRAD-01** El degradado es decorativo: `.accessibilityHidden(true)` en el fondo.  
**LOGIN-GRAD-02** Prohibido `Image("mixpro")` o recortes de la captura.  
**LOGIN-GRAD-03** Identifiers y campos de §5 de `login-home-logout.md` **idénticos**.

### 4.3 Sidebar destinos — «admin»

Solo `ListaSeccionesAppVista` (`shell.sidebar`). No pintar la lista de usuarios.

| Token | Light | Dark | Uso |
|-------|-------|------|-----|
| `DS-SHELL-BG` | `#E8F4F4` | `#122022` | Fondo de la columna de destinos (opaco) |
| `DS-SHELL-ACTIVE-FILL` | `DS-ACCENT` @ 0,14 | `DS-ACCENT` @ 0,22 | Capsule/rounded rect del ítem seleccionado |
| `DS-SHELL-ACTIVE-BAR` | `DS-ACCENT` | `DS-ACCENT` | Barra leading **3 × 18** pt, radio 1,5 |

Texto de fila: `Color.primary`. Ítem activo: `Color.primary` + `.headline` (semibold), **no** blanco sobre acento. La barra + el peso tipográfico cumplen 1.4.1 si se apaga el color.

Increase Contrast: fill @ 0; **solo** barra 4 pt + semibold + stroke de fila `primary` @ 0,45. Reduce Transparency: fondos opacos (ya).

Ancho de columna destinos: **sin cambio** (min 180, ideal 200, max 220).

### 4.4 Layout Inicio

| Token | Valor |
|-------|--------|
| `DS-HOME-MAX` | **960** (antes 720) — enmienda `maxAnchoInicio` |
| Gap KPI | `DS-SPACE-12` |
| Min ancho celda KPI | **160** |
| Alto gráfico | **220** |
| Gap gráficos | `DS-SPACE-20` |

Reflow (1.4.10), no scroll horizontal de la ventana:

| Ancho columna detalle | KPI | Gráficos | Accesos |
|-----------------------|-----|----------|---------|
| ≥ 900 | 4 en fila (`LazyVGrid` adaptive 160) | 2 columnas | 2 columnas |
| 600–899 | 2×2 | apilados | apilados o 2 columnas si caben |
| &lt; 600 | 1 columna | apilados | apilados |

Ventana autenticada: se mantiene min **880×520** / default **1040×680**. A 880 los KPI pasan a 2×2; no recortar valores.

---

## 5. Contraste verificado (cálculo sRGB, 2026-09-19)

Fórmula WCAG 2.2 1.4.3 (luminancia relativa). **No** es captura de Accessibility Inspector.

| Par | Ratio | Umbral | Veredicto |
|-----|------:|--------|-----------|
| `#FFFFFF` sobre `#0B6E75` (cyan Light) | **6,00:1** | 4,5:1 | PASS |
| `#FFFFFF` sobre `#B85A00` (naranja Light) | **4,67:1** | 4,5:1 | PASS (margen estrecho; IC oscurece) |
| `#FFFFFF` sobre `#1F7A4D` (verde Light) | **5,32:1** | 4,5:1 | PASS |
| `#FFFFFF` sobre `#125EAB` (azul Light) | **6,53:1** | 4,5:1 | PASS |
| `#FFFFFF` sobre `#085258` (cyan Dark) | **8,91:1** | 4,5:1 | PASS |
| `#FFFFFF` sobre `#8A4300` (naranja Dark) | **7,28:1** | 4,5:1 | PASS |
| `#FFFFFF` sobre `#165C3A` (verde Dark) | **8,00:1** | 4,5:1 | PASS |
| `#FFFFFF` sobre `#0E4680` (azul Dark) | **9,52:1** | 4,5:1 | PASS |
| `#FFFFFF` sobre `#00BCD4` (cyan marketing) | **2,30:1** | 4,5:1 | **FAIL — prohibido** |
| `#FFFFFF` sobre `#FF9800` (naranja marketing) | **2,16:1** | 4,5:1 | **FAIL — prohibido** |
| `#FFFFFF` sobre `#4CAF50` (verde marketing) | **2,78:1** | 4,5:1 | **FAIL — prohibido** |
| `#FFFFFF` sobre `#2196F3` (azul marketing) | **3,12:1** | 4,5:1 | **FAIL — prohibido** |
| `#1C1C1E` sobre `#00BCD4` | **7,41:1** | 4,5:1 | PASS técnico, **no usar**: se aleja del teal DS y del blanco-sobre-color pedido si el relleno ya cumple |
| `#FFFFFF` sobre `#5EC8C0` | **2,00:1** | 4,5:1 | **FAIL — sigue prohibido** |

1.4.11 (no texto) KPI vs ventana: los cuatro rellenos Light sobre `#F5F5F7` superan 3:1 (son bloques grandes saturados). Dark: rellenos oscuros sobre `#1C1C1E` — naranja/verde/azul/cyan Dark siguen siendo distinguibles; IC añade stroke.

---

## 6. `S-LOGIN` — receta (delta)

Contenido de la tarjeta: **idéntico** a `login-home-logout.md` §5 (well, títulos, hint, campos, errores, `login.entrar`). Solo cambia el lienzo.

```
ZStack {
    LinearGradient(sistema azul→índigo)   // accessibilityHidden
        .ignoresSafeArea()
    tarjeta 420                           // centrada, identifiers intactos
}
```

Foco, teclado, 3.3.8, `SecureField`, copy `COPY-LOGIN-*`: **sin cambio**. UITests de `login.usuario` / `login.clave` / `login.entrar` no deben depender del color de fondo.

---

## 7. Shell autenticado — sidebar destinos

`ListaSeccionesAppVista` conserva exactamente dos filas: **Inicio** y **Usuarios**. Prohibido añadir Dashboard, Support, Forms, Charts, «UI Elements» u otros ítems de marketing.

```
List(selection:) {
    fila Inicio     // house + COPY-SHELL-INICIO, identifier shell.inicio
    fila Usuarios   // person.crop.rectangle.stack + COPY-SHELL-USUARIOS, identifier shell.usuarios
}
.listStyle(.sidebar)
.scrollContentBackground(.hidden)
.background(DS-SHELL-BG)
```

Ítem seleccionado (receta visual **además** de la selección nativa):

```
HStack(spacing: 8) {
    Capsule().fill(DS-SHELL-ACTIVE-BAR).frame(width: 3, height: 18)  // hidden a11y
    Label(...)
}
.padding(8)
.background(DS-SHELL-ACTIVE-FILL, in: RoundedRectangle(8, continuous))
```

Ítem no seleccionado: sin barra (o barra `Color.clear` para no saltar el layout) + `Color.primary`.

**SHELL-ADMIN-01** Identifiers `shell.sidebar` / `shell.inicio` / `shell.usuarios` **no se renombran**.  
**SHELL-ADMIN-02** VoiceOver: «Inicio, seleccionado» — el Label nombra; la barra es hidden.  
**SHELL-ADMIN-03** En destino **Usuarios**, la cabecera «Inicio» existente (`RaizAppVista`) **puede** adoptar la misma barra/acento si sigue siendo el control `shell.inicio`; no duplicar identifier.  
**SHELL-ADMIN-04** Prohibido sidebar navy con texto blanco tipo plantilla web (contraste y HIG).  
**SHELL-ADMIN-05** Sigue **prohibido** anidar `NavigationSplitView`.

Toolbar `toolbar.logout` y menú `menu.logout`: sin cambio.

---

## 8. `S-HOME` — receta

Norte: panel de administración **nativo**, no Analytics SaaS. Fondo de columna: `windowBackgroundColor`. Padding 24 / 20, gap 20, `maxWidth: 960`, alignment leading.

```
ScrollView {
  VStack(alignment: .leading, spacing: 20) {
    Hero                         // igual contrato login-home §6.1 (home.hero / home.saludo)
    LazyVGrid KPI × 4
    HStack/VStack gráficos       // reflow §4.4
    HStack/VStack accesos        // home.verLista / home.nuevo
  }
}
```

**Prohibido**: cuarta fila de widgets sociales; sparkline decorativo sin datos; tabla embebida de usuarios; duplicar `home.total`.

### 8.1 Hero

Sin cambio funcional respecto a `login-home-logout.md` §6.1: avatar 80, `COPY-HOME-HELLO`, `COPY-HOME-SUB`, identifiers `home.hero` / `home.saludo`. El subtítulo puede permanecer («Resumen de tu espacio de trabajo.»).

### 8.2 Fila de 4 KPI

Cada KPI es **texto estático** (no `Button`). Color **nunca** es el único medio: icono SF **visible** + label visible + valor.

```
VStack(alignment: .leading, spacing: 8) {
    HStack(spacing: 8) {
        Image(systemName: symbol)  // 16 pt, DS-KPI-FG, NO accessibilityHidden a nivel visual
        Text(label)                // caption, DS-KPI-FG
    }
    valor                          // title2.monospacedDigit, DS-KPI-FG
}
.padding(16)
.frame(maxWidth: .infinity, alignment: .leading)
.background(relleno, in: RoundedRectangle(10, continuous))
.accessibilityElement(children: .combine)
.accessibilityLabel(label + ", " + valorAccesible)
.accessibilityAddTraits(.isStaticText)
.accessibilityIdentifier(home.kpi.*)
```

Para VoiceOver el icono **sí** se oculta en el árbol combinado (el label textual nombra). En pantalla el icono **se ve** (1.4.1, 1.4.5 no aplica: es SF Symbol).

| KPI | Label | Symbol | Relleno | Identifier | Valor |
|-----|-------|--------|---------|------------|--------|
| Usuarios | `COPY-KPI-USERS` | `person.2` | `DS-KPI-CYAN` | `home.kpi.usuarios` | §9 |
| Ciudades | `COPY-KPI-CITIES` | `map` | `DS-KPI-ORANGE` | `home.kpi.ciudades` | §9 |
| Empresas | `COPY-KPI-COMPANIES` | `building.2` | `DS-KPI-GREEN` | `home.kpi.empresas` | §9 |
| Altas de sesión | `COPY-KPI-ALTA` | `person.badge.plus` | `DS-KPI-BLUE` | `home.kpi.altas` | §9 |

**HOME-KPI-01** No son botones.  
**HOME-KPI-02** `home.total` **deja de existir**. El conteo de usuarios vive en `home.kpi.usuarios`. UITests actuales usan `home.saludo`, no `home.total`.  
**HOME-KPI-03** Hit/lectura ≥ 24 pt de alto (padding 16 + dos líneas).  
**HOME-KPI-04** Prohibido un rectángulo de color sin texto.

Estados del **valor** (los cuatro KPI, misma matriz):

| Estado de lista | Valor visible | Label VO |
|-----------------|---------------|----------|
| Cargando, sin cache | `COPY-KPI-LOAD` («Contando…») + `ProgressView` small (tinta `DS-KPI-FG`) | `COPY-KPI-LOAD` |
| OK | número entero `monospacedDigit` (**no** miles inventados ni decimales de marketing) | `"{label}, {n}"` + unidad en copy accesible §11 |
| Error de red, sin cache | `COPY-KPI-NA` («No disponible») | `COPY-KPI-NA` — **no** mostrar `0` |
| Error con cache | número cacheado | igual que OK |

**HOME-KPI-05** Vacío ≠ error: `0` altas al login fresco es válido. `0` ciudades si todos los usuarios nuevos no tienen `direccion.ciudad` es válido.  
**HOME-KPI-06** No duplicar el banner de recarga de la lista.

### 8.3 Gráfico de área — usuarios por ciudad

Tarjeta `DS-CARD` + stroke DS. Identifier contenedor: `home.chart.ciudades`.

- Framework: Swift Charts, `AreaMark` + `LineMark` de la **misma** serie (un solo color `DS-ACCENT` / cyan KPI). No paleta arcoíris por ciudad: la categoría se lee en el eje y en el resumen VO.
- Eje X: nombre de ciudad (categoría). Si no cabe, truncar visualmente con `lineLimit(1)`; el resumen VO **no** trunca.
- Eje Y: enteros ≥ 0 (usuarios).
- Título visible `COPY-CHART-CITIES` (headline, `.isHeader`).
- **Índice**: el eje es el índice de **categoría** (ciudad ordenada), no un eje temporal ficticio. Prohibido etiquetar «Ene–Dic» o «Yearly Sales».
- Datos: §9.2. Si 0 ciudades con nombre: empty interno `COPY-CHART-CITIES-EMPTY` (icono `map` + texto), **sin** curva plana inventada.
- Carga / error: mismos textos KPI (`COPY-KPI-LOAD` / `COPY-KPI-NA`) dentro de la tarjeta; no dibujar ejes vacíos con ticks de mentira.

Altura 220. Reduce Motion: `animation(nil)` en el Chart si `accessibilityReduceMotion`.

### 8.4 Gráfico de barras — empresas

Tarjeta gemela. Identifier: `home.chart.empresas`.

- `BarMark` categoría = `empresa.nombre`, x = conteo.
- Un solo color de barra (`DS-KPI-GREEN` o acento). **No** una barra de color distinto por empresa como único distintivo: el nombre va en el eje.
- Título `COPY-CHART-COMPANIES`.
- Empty: `COPY-CHART-COMPANIES-EMPTY`.
- Máximo **8** barras; el resto se agrega en `COPY-CHART-OTHERS` (`Otras ({k})`) con la **suma real** de conteos restantes. Eso no es un número inventado.

### 8.5 Accesos

Igual que `login-home-logout.md` §6.3: botones-tarjeta `home.verLista` y `home.nuevo`, wells existentes, chevron hidden, `COPY-HOME-LIST-*` / `COPY-HOME-NEW-*`. Pueden ir en fila de 2 cuando el ancho ≥ 600.

**HOME-04** y **HOME-05** de login-home **siguen vigentes** (`home.nuevo` ≠ `toolbar.nuevo`; sin segunda toolbar de alta en Inicio).

### 8.6 Carga de datos

Tras login OK, **un** `ListarUsuariosCasoUso` (el que ya dispara `ShellVistaModelo` / `cargarInicial`). KPI y gráficos **derivan** de `modelo.usuarios.usuarios` en Presentation. **Prohibido** un segundo cliente HTTP o series hardcodeadas.

Anuncio 4.1.3: un solo `COPY-LOADED` al completar la lista (regla ya en login-home §6.4). No anunciar cada KPI por separado al cargar.

---

## 9. Datos — derivación obligatoria (cero cifras de diseño)

Fuente: `[Usuario]` de la sesión autenticada. No hay endpoint de métricas.

### 9.1 Totales KPI

| KPI | Fórmula |
|-----|---------|
| Usuarios | `usuarios.count` (misma verdad que `COPY-COUNT`) |
| Ciudades | `Set` de `direccion.ciudad` recortada, **excluyendo** vacías |
| Empresas | `Set` de `empresa.nombre` recortada, **excluyendo** vacías |
| Altas de sesión | `usuarios.filter { $0.id.valor >= 10_000 }.count` — umbral ya definido por `UsuarioRepositorioSesion.idSinteticoMinimo`. Presentation puede duplicar la constante nombrada (`umbralIdSintetico`) **sin** nuevo caso de uso Domain (ADR-002: no `ContarUsuariosCasoUso`) |

JSONPlaceholder típico (n≈10, 1 ciudad y 1 empresa por usuario) producirá KPI del orden de `10 / 10 / 10 / 0` al primer login. **Eso es correcto.** No «redondear» a 450 ni a 6 374.

Altas: cada `crear` del overlay sube el KPI en la misma sesión; logout lo vuelve 0 (overlay reiniciado).

### 9.2 Series de gráficos

**Ciudades (`home.chart.ciudades`)**

1. Agrupar usuarios con `ciudad` no vacía.  
2. `(ciudad, n)` ordenado por `n` descendente, empate alfabético `localizedStandard`.  
3. Si hay más de 8 ciudades, top 7 + `Otras (k)` con k = ciudades restantes y n = suma de esas.

**Empresas (`home.chart.empresas`)**: idéntico con `empresa.nombre`.

**Prohibido**: interpolar picos para que el área «se vea viva»; añadir meses; usar `id` de usuario como eje Y; mostrar lat/lng.

### 9.3 Copy de valor (unidad)

El número visible en KPI es **solo el entero**. La unidad va en el label de la tarjeta y en el `accessibilityLabel` (`"Ciudades, 10"` / `"1 ciudad"`). No concatenar «usuarios» otra vez en el valor (evita «10 10 usuarios»).

---

## 10. Charts y accesibilidad

Swift Charts en macOS expone un gráfico accesible. **Además** (no en vez):

| ID | Regla | WCAG |
|----|--------|------|
| `A11Y-CH-01` | El contenedor tiene `accessibilityLabel` que **resume los datos**, no «Gráfico» a secas. Plantilla: `COPY-CHART-CITIES` + lista `" {ciudad}: {n}"` unida por comas, máx. las mismas categorías visibles. | 1.1.1 |
| `A11Y-CH-02` | `accessibilityIdentifier` en el contenedor de la tarjeta (`home.chart.ciudades` / `home.chart.empresas`). | 4.1.2 |
| `A11Y-CH-03` | Empty y error son texto + icono, no un plot vacío silencioso. | 1.1.1, 1.4.1 |
| `A11Y-CH-04` | Un solo color de serie + etiquetas de categoría. Prohibido leyenda solo cromática. | 1.4.1 |
| `A11Y-CH-05` | Reduce Motion: sin animación de dibujo en bucle. | 2.3.1 / 2.2.2 |
| `A11Y-CH-06` | El Chart no roba el ciclo de Tab de login ni de la sidebar. Si el sistema lo hace foco AXChart, Enter no debe navegar. | 2.1.2 |
| `A11Y-CH-07` | Ejes con `Color.primary` (ticks) / `secondary` (guías) **sobre `DS-CARD`**, no sobre relleno KPI. | 1.4.3 |
| `A11Y-CH-08` | No incrustar imagen bitmap del marketing como «chart». | 1.4.5 |

Ejemplo de label (datos reales de la lista, no este texto fijo):

```
Usuarios por ciudad. Gwenborough: 1, Wisokyburgh: 1, McKenziehaven: 1.
```

Si hay 10 categorías, el label las enumera (n demo es pequeño). Si se agregó «Otras», incluir esa fila.

**No** usar `accessibilityHidden(true)` en todo el Chart (dejaría solo el título visual y rompería 1.1.1).

---

## 11. Catálogo de copy (español, cerrado)

Developer no improvisa. Tono COPY-01 / COPY-02. Reutilizar `COPY-HOME-HELLO`, `COPY-HOME-SUB`, `COPY-HOME-LIST-*`, `COPY-HOME-NEW-*`, `COPY-LOGIN-*`, `COPY-LOGOUT*`.

| ID | Contexto | String |
|----|----------|--------|
| `COPY-KPI-USERS` | Label KPI | Usuarios |
| `COPY-KPI-CITIES` | Label KPI | Ciudades |
| `COPY-KPI-COMPANIES` | Label KPI | Empresas |
| `COPY-KPI-ALTA` | Label KPI | Altas de sesión |
| `COPY-KPI-LOAD` | Valor cargando | Contando… |
| `COPY-KPI-NA` | Valor error sin cache | No disponible |
| `COPY-KPI-USERS-A11Y` | VO KPI usuarios | `Usuarios, {n}` / `Usuarios, 1` (el número basta; el label ya dice Usuarios) |
| `COPY-KPI-CITIES-A11Y` | VO | `Ciudades, {n}` |
| `COPY-KPI-COMPANIES-A11Y` | VO | `Empresas, {n}` |
| `COPY-KPI-ALTA-A11Y` | VO | `Altas de sesión, {n}` |
| `COPY-CHART-CITIES` | Título área | Usuarios por ciudad |
| `COPY-CHART-COMPANIES` | Título barras | Usuarios por empresa |
| `COPY-CHART-CITIES-EMPTY` | Empty área | No hay ciudades en los usuarios cargados. |
| `COPY-CHART-COMPANIES-EMPTY` | Empty barras | No hay empresas en los usuarios cargados. |
| `COPY-CHART-OTHERS` | Categoría agregada | `Otras ({k})` |
| `COPY-CHART-CITIES-A11Y` | Prefijo resumen VO | `Usuarios por ciudad.` |
| `COPY-CHART-COMPANIES-A11Y` | Prefijo resumen VO | `Usuarios por empresa.` |
| `COPY-CHART-PAIR` | Par VO | `{nombre}: {n}` |

Pluralización de pares: `{n}` es el entero; no hace falta «usuario/usuarios» en cada par si el título del gráfico ya lo dice (evita verbosidad VO). Si QA prefiere unidad, usar `1 usuario` / `{n} usuarios` **solo** en el resumen, de forma consistente.

**Prohibido en copy de producto**: MixPro, Bootstrap, jQuery, Dashboard (inglés), Sign in, Logout, «New Clients», «Products Yearly Sales», `123456`.

`COPY-HOME-TOTAL-*` de login-home **deja de usarse** en UI (reemplazado por `COPY-KPI-*`). No hace falta borrar las constantes de golpe si el Developer prefiere alias interno; **no** deben renderizarse.

---

## 12. Identifiers (contrato QA)

### 12.1 Invariantes — no renombrar

`login.titulo`, `login.hint`, `login.usuario`, `login.clave`, `login.entrar`, `login.error`, `login.lockout`, `login.entornoDemo` (si existe), `toolbar.logout`, `menu.logout`, `shell.sidebar`, `shell.inicio`, `shell.usuarios`, `home.hero`, `home.saludo`, `home.verLista`, `home.nuevo`, `form.nombre`, `form.username`, `form.email`, `form.guardar`, `form.cancelar`, `lista.busqueda`, `lista.usuario.{id}`, `lista.titulo`, `toolbar.nuevo`, `toolbar.recargar`, `toolbar.editar`, `detalle.*`, `estado.*`.

### 12.2 Nuevos (obligatorios)

| Identifier | Elemento |
|------------|----------|
| `home.kpi.usuarios` | Tarjeta KPI Usuarios |
| `home.kpi.ciudades` | Tarjeta KPI Ciudades |
| `home.kpi.empresas` | Tarjeta KPI Empresas |
| `home.kpi.altas` | Tarjeta KPI Altas de sesión |
| `home.chart.ciudades` | Contenedor gráfico de área |
| `home.chart.empresas` | Contenedor gráfico de barras |

### 12.3 Retirados

| Identifier | Destino |
|------------|---------|
| `home.total` | Sustituido por `home.kpi.usuarios`. No dejar ambos visibles. |

No identifier en el degradado de login ni en la barra de 3 pt del sidebar.

UITests: `testLaunch` / helper `autenticar` siguen esperando `login.*` y `home.saludo`. No es obligatorio asertar los KPI en este handoff; QA puede añadir casos después.

---

## 13. WCAG 2.2 — delta del panel

Siguen vigentes mapas de `navegacion-usuarios.md` §7 y `login-home-logout.md` §10.

| WCAG | Nivel | Delta | ID |
|------|-------|-------|-----|
| 1.4.1 Color | A | KPI = icono + texto + color; sidebar activo = barra + peso; charts = etiquetas, no solo serie cromática | `A11Y-DASH-01` |
| 1.4.3 Contraste | AA | Blanco sobre rellenos §5; **prohibido** blanco sobre hex marketing; naranja Light 4,67:1 (IC oscurece) | `A11Y-DASH-02` |
| 1.4.11 Contraste no texto | AA | Stroke tarjeta login vs degradado Dark; stroke IC en KPI | `A11Y-DASH-03` |
| 1.1.1 No textual | A | `accessibilityLabel` de charts resume datos; degradado hidden | `A11Y-DASH-04` |
| 1.4.10 Reflow | AA | Grid adaptive; no scroll X de ventana a 880 pt | `A11Y-DASH-05` |
| 1.4.4 / Dynamic Type | AA | Labels KPI a `.caption` de sistema; valor `.title2`; charts pueden clippear categorías → VO completo | `A11Y-DASH-06` |
| 2.4.6 Encabezados | AA | Títulos de gráficos `.isHeader`; hero ya es header | `A11Y-DASH-07` |
| 2.5.3 Label in name | A | Accesos y destinos sin cambio; KPI no son botones | `A11Y-DASH-08` |
| 4.1.2 Nombre, rol, valor | A | Identifiers §12; KPI `.isStaticText` | `A11Y-DASH-09` |
| 2.3.1 / Reduce Motion | A | Charts sin bounce | `A11Y-DASH-10` |
| 3.1.1 Idioma | A | Copy §11 en español | `A11Y-DASH-11` |

---

## 14. Checklist a11y verificable para Developer

Se **suma** a los checklists de navegación, DS y login-home. Full Keyboard Access ON. Inspector en Light, Dark e Increase Contrast.

### Teclado

- [ ] `A11Y-K-D01` Login: ciclo usuario → clave → Entrar intacto sobre el degradado (el fondo no es foco)
- [ ] `A11Y-K-D02` Sidebar destinos: ↑↓ Inicio/Usuarios; ítem activo visible sin color-only
- [ ] `A11Y-K-D03` `home.verLista` / `home.nuevo` en el ciclo tras el contenido de Inicio; KPI no son controles
- [ ] `A11Y-K-D04` Charts no atrapan Tab; Esc no cierra la app
- [ ] `A11Y-K-D05` `toolbar.logout` sigue una sola instancia

### VoiceOver

- [ ] `A11Y-V-D01` KPI: «Usuarios, {n}» (o Contando… / No disponible), no «cyan» ni nombre SF
- [ ] `A11Y-V-D02` `home.chart.ciudades` anuncia título + pares ciudad/n reales
- [ ] `A11Y-V-D03` `home.chart.empresas` anuncia título + pares empresa/n reales
- [ ] `A11Y-V-D04` Empty de gráfico: copy §11, no «imagen» / «grupo vacío»
- [ ] `A11Y-V-D05` Destino Inicio: «Inicio, seleccionado»; barra hidden
- [ ] `A11Y-V-D06` Degradado de login no se anuncia

### Contraste / visual

- [ ] `A11Y-C-D01` Light: blanco sobre los 4 rellenos KPI; muestrear naranja (`#B85A00`) en Inspector ≥ 4,5:1
- [ ] `A11Y-C-D02` Dark: blanco sobre rellenos oscuros §4.1; **nunca** blanco sobre `#5EC8C0`
- [ ] `A11Y-C-D03` Ningún KPI usa hex marketing §5 FAIL
- [ ] `A11Y-C-D04` Icono + label visibles en cada KPI (captura en escala de grises: se distinguen)
- [ ] `A11Y-C-D05` Login Dark: borde de tarjeta ≥ 3:1 vs degradado (o stroke IC)
- [ ] `A11Y-C-D06` Increase Contrast: stroke KPI + barra sidebar 4 pt

### Flujo / identifiers / datos

- [ ] `A11Y-F-D01` Identifiers §12.2 presentes; §12.1 intactos; `home.total` ausente
- [ ] `A11Y-F-D02` Tras login fresco, altas = 0 (no un número de plantilla)
- [ ] `A11Y-F-D03` Crear un usuario → altas incrementa en 1 al volver a Inicio (misma sesión)
- [ ] `A11Y-F-D04` KPI Usuarios coincide con el footer/conteo de la lista
- [ ] `A11Y-F-D05` Sin curva de área si 0 ciudades; sin barras si 0 empresas
- [ ] `A11Y-F-D06` UI en español; cero chrome MixPro/Bootstrap/jQuery
- [ ] `A11Y-F-D07` UITest login + `toolbar.nuevo` sigue verde

**Bloqueantes G10 (FAIL si uno falta)**: `A11Y-K-D01`, `A11Y-V-D01`, `A11Y-V-D02`, `A11Y-C-D01`, `A11Y-C-D03`, `A11Y-C-D04`, `A11Y-F-D01`, `A11Y-F-D05`, `A11Y-F-D06`, más bloqueantes vigentes de login (`A11Y-K-L01`, `A11Y-V-L02`, `A11Y-C-L03`, `A11Y-C-L05`) y CRUD.

**No bloqueantes (CONDITIONAL)**: recorte de labels de eje en Dynamic Type XXXL si VO está completo; Increase Contrast fino del fill sidebar; Audio Graphs de sistema no auditados.

---

## 15. Hallazgos sobre el estado actual (evidencia)

| Sev. | Hallazgo | Evidencia | WCAG | Remediación (esta spec) |
|------|----------|-----------|------|-------------------------|
| Medium (producto) | Inicio no tiene panel KPI/charts | `InicioVista.swift` hero + `home.total` + 2 accesos | Usabilidad; 1.1.1 N/A aún | Receta §8 |
| Medium | Login sin lienzo de gate | `LoginVista.swift` `ZStack { TemaUsuarios.ventana }` | 1.4.11 OK hoy; mood pedido | Degradado sistema §4.2 / §6 |
| Medium | Sidebar destinos = List nativo plano | `ListaSeccionesAppVista` | 1.4.1 OK (selección nativa) | Fondo + barra + peso §7 |
| Low | `home.total` único métrica | `IdentificadorAccesibilidad.homeTotal` | — | Retirar; `home.kpi.*` |
| Info | Design system prohibía dashboard KPI | `design-system-usuarios.md` §2 | — | Excepción acotada §2 |
| Info | No hay `import Charts` | grep del repo | — | Añadir Swift Charts en Presentation |
| Info | Captura MixPro usa blanco sobre cyan ~2,3:1 | Cálculo §5 | 1.4.3 | Rellenos DS, no hex marketing |

Teclado, login 3.3.8 y CRUD **no se reabren**.

---

## 16. Gate G10 — verdict

### 16.1 Esta entrega (spec, sin código de producción)

| Gate | Status | Evidencia | Notas |
|------|--------|-----------|-------|
| G0 Context | PASS | Handoff EE-UX-20260919-4 + repo SwiftUI macOS, ADR-001/002, DS teal, login/home existentes | Stack: Swift 5 / SwiftUI / macOS 27; JSONPlaceholder; auth demo |
| G10 Accessibility | CONDITIONAL | `degraded: revisión manual WCAG` — contrastes **calculados** §5 (script sRGB 2026-09-19); criterios §13–§14; **no** hay captura de Accessibility Inspector ni axe (no aplica a AppKit). UI de KPI/charts **aún no implementada**. | Máximo en degradado: **CONDITIONAL** |

PASS real de G10 solo tras implementar + Inspector Light/Dark/IC + checklist §14 bloqueantes + UITests invariantes.

### 16.2 Previsto tras implementación

- **PASS** si: 4 KPI con icono+texto+contraste §5; charts con resumen VO; identifiers §12; login identifiers verdes; cero hex marketing; cero números inventados.  
- **CONDITIONAL** si: bloqueantes OK pero falta Inspector (`degraded`) o recorte de ejes en XXXL.  
- **FAIL** si: `TabView`; blanco sobre `#00BCD4`/`#5EC8C0`; KPI solo color; `home.total` duplicado y `home.kpi.*` ausentes; curva anual ficticia; feeds sociales; se pierde `login.*` / `toolbar.logout` / `form.*` / `lista.*`.

**Backlog tooling** (no bloquea): UITest de `home.kpi.usuarios` vs conteo de lista; guía Inspector de Charts; CI.

---

## 17. Handoff hacia Developer

## Handoff: @ux-accessibility-agent → @senior-fullstack-developer-agent
**Handoff-ID**: UX-DEV-20260919-4  
**Prioridad**: P0

### Contexto detectado
- Stack: Swift 5 / SwiftUI / macOS 27 (NO iOS)
- Arquitectura: ADR-001 Clean Architecture (Domain/Data/Presentation). ADR-002 auth demo + un `WindowGroup` + un `NavigationSplitView`. NO anidar splits. NO cambiar contratos Domain/Data (Inicio sigue derivando de `ListarUsuariosCasoUso`).
- DB/ORM: JSONPlaceholder REST + overlay `UsuarioRepositorioSesion` (altas id ≥ 10_000)
- Build: `xcodebuild -scheme GestionUsuarios -destination 'platform=macOS'`
- Test: Swift Testing + XCTest UI. Conservar `login.*`, `toolbar.logout`, `form.*`, `lista.*`. Helper de autenticación ya existe.
- Lint: no detectado
- CI: no detectado
- Constraints: App Sandbox; HIG macOS; español; DS teal; WCAG 2.2 A/AA; no TabView; no NavigationStack raíz; no MixPro/Bootstrap/jQuery; no números inventados; G10 CONDITIONAL degradado Inspector

### Alcance
- **Incluye**: degradado de login de sistema; sidebar destinos con fondo + ítem activo; `S-HOME` con 4 KPI + Swift Charts (área ciudades, barras empresas) + accesos existentes; tokens KPI en `TemaUsuarios`; copy §11; identifiers §12.2; retirar `home.total`; `accessibilityLabel` de charts con resumen de datos
- **Excluye**: código Domain/Data nuevo; OAuth; TabView; NavigationStack raíz; assets MixPro; feeds sociales; Chart.js/WebView; inventar series; mostrar `123456`; rehacer CRUD
- **Archivos afectados** (orientativos; Presentation/tema/copy):
  - `GestionUsuarios/Presentation/Autenticacion/LoginVista.swift` — fondo degradado; tarjeta intacta
  - `GestionUsuarios/Presentation/AppShell/RaizAppVista.swift` — `ListaSeccionesAppVista` receta §7
  - `GestionUsuarios/Presentation/Inicio/InicioVista.swift` — receta §8
  - `GestionUsuarios/Presentation/Tema/TemaUsuarios.swift` — tokens §4
  - `GestionUsuarios/Presentation/Navegacion/TextosUsuarios.swift` — copy + identifiers
  - UITests: no romper login/logout/alta; no hace falta test nuevo de charts en este handoff
  - **No** Domain/Data

### Artefactos entregados
- `docs/ux/admin-dashboard.md` (tokens, recetas, contraste calculado, copy, identifiers, G10, este handoff)

### Decisiones tomadas
| Decisión | Justificación | Alternativa descartada |
|----------|---------------|------------------------|
| Rellenos KPI = paleta DS oscurecible + blanco | 1.4.3 ≥ 4,5:1; mood colorido sin hex marketing | Blanco sobre cyan/naranja MixPro (2,1–3,1:1 FAIL); rellenos caramelo + texto oscuro (válido AA pero rompe el teal DS) |
| KPI = icono SF + label + valor | 1.4.1; color no es el único medio | Rectángulo de color + número |
| Series 100 % derivadas de `[Usuario]` | Handoff: no números inventados | Sparkline anual; 6 374; % analítica |
| Área = ciudades; barras = empresas; máx. 8 + «Otras» | Pedido EE; n demo cabe; agregación honesta | Eje temporal ficticio; una barra de color por empresa sin nombre |
| Altas = `id >= 10_000` | Overlay ya usa ese umbral; cero caso de uso nuevo | Contar «sin ciudad» (falso positivo); nuevo protocol Domain |
| Login: misma tarjeta sobre `systemBlue`→`systemIndigo` | Mood de gate; no asset MixPro | PNG de marketing; blur Material |
| Sidebar destinos: lavado teal + barra 3 pt + semibold | «Admin» nativo; 1.4.1 | Navy + texto blanco tipo plantilla web |
| Swift Charts nativo | Stack SwiftUI macOS 27; a11y de sistema | jQuery/Bootstrap/Chart.js/WebView |
| G10 CONDITIONAL | Inspector no ejecutado; quality-gates degradado | PASS sin evidencia de runtime |
| Retirar `home.total` | Un solo identifier de conteo: `home.kpi.usuarios` | Alias duplicado (dos nodos VO) |

### Riesgos abiertos
| Riesgo | Severidad | Requiere validación de |
|--------|-----------|------------------------|
| Naranja Light `#B85A00` + blanco = 4,67:1 (margen fino) | Media | Inspector `A11Y-C-D01`; IC ya oscurece |
| Tarjeta login Dark vs degradado &lt; 3:1 (1.4.11) | Media | Developer + Inspector `A11Y-C-D05` |
| `LazyVGrid` + Charts + Dynamic Type XXXL recorta ejes | Baja | VO completo `A11Y-V-D02`; no bloquea si el label resume |
| Constant 10_000 en Presentation acopla a Data | Baja | Nombrar constante; Architect si se quiere mover a Domain |
| Swift Charts como foco extraño con Full Keyboard Access | Baja | `A11Y-K-D04` |
| `home.total` residual en algún test futuro | Baja | Grep al implementar |

### Criterio de éxito
- [ ] Login: tarjeta 420 igual; identifiers `login.*` verdes; fondo degradado de sistema (no PNG)
- [ ] Sidebar destinos: fondo distinto + ítem activo con barra y peso; `shell.*` intactos
- [ ] Inicio: 4 KPI (`home.kpi.*`) con icono + texto + contraste §5
- [ ] `home.chart.ciudades` área y `home.chart.empresas` barras; `accessibilityLabel` resume datos reales
- [ ] Accesos `home.verLista` / `home.nuevo` conservados
- [ ] Cero MixPro/Bootstrap/jQuery; cero números de marketing; altas = 0 al login fresco
- [ ] `form.*` / `lista.*` / `toolbar.logout` verdes; UITests existentes pasan
- [ ] Build `xcodebuild` macOS verde
- [ ] Light + Dark: sin blanco sobre `#5EC8C0` ni sobre hex marketing

### Gates pendientes
| Gate | Esperado |
|------|----------|
| G10 | CONDITIONAL (Inspector) o PASS con checklist §14 bloqueantes |
| G2 | Tras código: `xcodebuild` build sin errores |
| G6 | UITests invariantes + (opcional) KPI vs conteo |
| G3 | Review post-implementación |
| G1 | SKIP UX (excepción visual acotada; ADR-002 intacto) |

### Comandos de verificación
- Build: `xcodebuild -scheme GestionUsuarios -destination 'platform=macOS' build`
- Test: `xcodebuild -scheme GestionUsuarios -destination 'platform=macOS' test`
- Lint: no detectado
- A11y: Accessibility Inspector → Audit + Contrast en Light, Dark e Increase Contrast sobre Login, Inicio (4 KPI + 2 charts) y sidebar destinos (manual; `degraded`)

---

## Referencias

- `docs/ux/navegacion-usuarios.md` — IA CRUD, menú, WCAG base
- `docs/ux/design-system-usuarios.md` — tokens teal, avatares, contraste AA
- `docs/ux/login-home-logout.md` — login, shell, logout (enmendado puntualmente)
- `docs/adr/ADR-002-autenticacion-demo-y-shell.md` — sesión, un split, Inicio via `ListarUsuariosCasoUso`
- Apple HIG — macOS (sidebars, windows, charts)
- Swift Charts — accessibility / Audio Graphs
- WCAG 2.2 §1.4.1, §1.4.3, §1.4.10, §1.4.11, §1.1.1, §4.1.2
- AgentesAI quality-gates G10
