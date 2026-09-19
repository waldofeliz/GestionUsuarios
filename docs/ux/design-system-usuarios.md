# Design system visual — Gestión de usuarios (macOS)

**Handoff origen**: EE-UX-20260919-2  
**Handoff destino**: UX-DEV-20260919-2  
**Owner**: `@ux-accessibility-agent`  
**Destino implementación**: `@senior-fullstack-developer-agent`  
**Fecha**: 2026-09-19  
**Plataforma**: macOS 27 · SwiftUI · **no iOS**  
**Idioma UI**: español (`es`)  
**Contrato previo**: `docs/ux/navegacion-usuarios.md` (navegación, atajos, copy, WCAG, identifiers). **Este documento no lo relaja.**  
**G10**: `CONDITIONAL` (`degraded: revisión manual WCAG`) hasta Accessibility Inspector post-implementación.

Este documento es el contrato **visual**: tokens con valores, receta por pantalla y contraste AA. No es código de producción.

---

## 1. Qué resuelve

La app ya navega como Mail/Contactos (`NavigationSplitView` + sheet crear + edición in-place), pero **se ve como un inspector vacío**: filas de dos `Text`, detalle `Form` + `LabeledContent`, `AccentColor` sin color, banner `.yellow.opacity(0.25)`.

Objetivo: interfaz nativa macOS pulida (Mail / Contactos), con identidad visual (avatar de iniciales, tarjeta de perfil, empty states gráficos) y contraste WCAG 2.2 AA verificable.

**Enmienda puntual a `navegacion-usuarios.md`**

| Sección previa | Cambio visual (solo lectura) |
|----------------|------------------------------|
| §2.1 / §5.3 — detalle solo `id, name, username, email` | El detalle **puede** mostrar `telefono`, `sitioWeb`, `direccion`, `empresa` como tarjetas de contacto si el valor no está vacío. No se piden campos nuevos a la API. El formulario sigue siendo **solo** nombre, username, email. Validación **sin cambios**. |
| §5.3 — detalle = `Form` + `LabeledContent` | El detalle de lectura pasa a **`ScrollView` + `VStack` + tarjetas**. `S-EDIT` y `S-CREATE` **conservan** `Form` grouped. |
| §5.1 — fila = dos `Text` | Fila = avatar 28 pt + dos líneas. Identifiers de fila **sin cambio**. |

Navegación, menú `.commands`, atajos, `listStyle(.sidebar)` y WCAG de `navegacion-usuarios.md` **no se tocan**.

---

## 2. Norte estético (y lo que no es)

**Sí**: master-detail de escritorio; sidebar material de sistema; detalle con ficha de persona; SF Symbols; Dynamic Type; Dark Mode; Increase Contrast; Reduce Transparency.

**No**: dashboard web (KPI, grids de 12 columnas, cards de métricas); neumorphism; sombras > 8 pt; fuentes custom; iconos bitmap; `TabView`; `NavigationStack` raíz; animaciones bounce; iOS compact stacked; acento usado como único indicador de selección.

---

## 3. Tokens de diseño

Namespace de implementación sugerido: `TemaUsuarios` en Presentation (constantes Swift, no Domain).

### 3.1 Color — acento (obligatorio en el asset)

Hoy `AccentColor.colorset/Contents.json` **no tiene componentes** (acento vacío → cae al azul de sistema, no es un token de producto).

| Token | Light | Dark | Increase Contrast Light | Increase Contrast Dark |
|-------|-------|------|-------------------------|------------------------|
| `DS-ACCENT` | `#0B6E75` | `#5EC8C0` | `#084F54` | `#8EDED6` |

Espacio: **sRGB**, alpha `1.0`. No Display P3 distinto (evita sorpresas de contraste).

**Uso permitido del acento**

| Superficie | Light | Dark |
|------------|-------|------|
| Relleno de avatar / botón `borderedProminent` / icono de empty-well | `#0B6E75` + texto/icono **blanco** `#FFFFFF` | Relleno `#5EC8C0` + texto/icono **`#1C1C1E`** (nunca blanco sobre `#5EC8C0`) |
| Glifo sobre fondo de ventana / tarjeta | `#0B6E75` sobre blanco/window | `#5EC8C0` sobre `#1E1E1E` / `#1C1C1E` |
| Texto de cuerpo, labels, secundaria de lista | **Prohibido**. Usar `Color.primary` / `Color.secondary` | igual |
| Selección de fila del `List` | Nativo (sistema). No pintar la fila con acento a mano | igual |

**Contraste verificado** (WCAG 2.2 1.4.3, fórmula relativa-luminance sRGB, 2026-09-19):

| Par | Ratio | Umbral |
|-----|------:|--------|
| `#FFFFFF` sobre `#0B6E75` | **6,00:1** | AA texto ≥ 4,5:1 |
| `#FFFFFF` sobre `#084F54` (IC) | **9,31:1** | AA |
| `#1C1C1E` sobre `#5EC8C0` | **8,51:1** | AA |
| `#5EC8C0` sobre `#1E1E1E` | **8,33:1** | AA (glifo / texto de acento) |
| `#1C1C1E` sobre `#8EDED6` (IC dark) | **10,99:1** | AA |
| `#FFFFFF` sobre `#5EC8C0` | **2,00:1** | **FAIL — prohibido** |
| `#5EC8C0` sobre `#F5F5F7` | **1,84:1** | **FAIL — no usar acento Dark en Light** |

`AccentColor.colorset` debe declarar las 4 apariencias (`luminosity` light/dark × `contrast` default/high). Valores de componentes (0–255):

| Apariencia | R | G | B |
|------------|--:|--:|--:|
| Light default | 11 | 110 | 117 |
| Dark default | 94 | 200 | 192 |
| Light + high contrast | 8 | 79 | 84 |
| Dark + high contrast | 142 | 222 | 214 |

### 3.2 Color — superficies y texto (sistema primero)

| Token | SwiftUI / AppKit | Light de referencia | Dark de referencia | Notas |
|-------|------------------|---------------------|--------------------|--------|
| `DS-TEXT` | `Color.primary` | ≈ `#1C1C1E` sobre `#F5F5F7` **15,63:1** | ≈ `#F5F5F7` sobre `#1C1C1E` **15,63:1** | Cuerpo, títulos, valores |
| `DS-TEXT-SEC` | `Color.secondary` | ≈ `#6C6C70` sobre blanco **5,23:1** | ≈ `#98989D` sobre `#1E1E1E` **5,81:1** | Secundaria de fila, labels de tarjeta. **Nunca** sobre el banner |
| `DS-WINDOW` | `Color(nsColor: .windowBackgroundColor)` | sistema | sistema | Lienzo del detalle |
| `DS-CARD` | `Color(nsColor: .controlBackgroundColor)` | ≈ blanco | ≈ `#2C2C2E` | Relleno opaco de tarjetas |
| `DS-SEP` | `Color(nsColor: .separatorColor)` | sistema | sistema | Divisor interno de tarjeta 0,5 pt |
| `DS-ERROR` | `Color.red` (sistema) | sistema | sistema | Solo con icono `exclamationmark.circle` (A11Y-06) |
| `DS-FOCUS` | anillo de foco de sistema | — | — | Prohibido `focusEffect(.hidden)` |

No introducir grises hex para texto (`#999`, `#666`, etc.).

### 3.3 Color — banner de recarga (remplaza el amarillo 25 %)

Hallazgo actual: `ListaUsuariosVista` usa `.background(.yellow.opacity(0.25))`. El fondo resultante **no es un token**; en Dark + `secondary` el contraste deja de ser predecible (riesgo 1.4.3).

| Token | Light | Dark | IC Light | IC Dark |
|-------|-------|------|----------|---------|
| `DS-BANNER-BG` | `#F5E6B8` | `#3A3420` | `#F8E09A` | `#2A2414` |
| `DS-BANNER-FG` | `Color.primary` | `Color.primary` | `Color.primary` | `Color.primary` |
| `DS-BANNER-ICON` | `#A12A00` | `#FF9F0A` | `#8A2400` | `#FFB340` |
| `DS-BANNER-STROKE` | `#A12A00` @ 0,35 | `#FF9F0A` @ 0,40 | `#8A2400` @ 0,70 | `#FFB340` @ 0,70 |

| Par | Ratio |
|-----|------:|
| `#1C1C1E` sobre `#F5E6B8` | **13,69:1** |
| `#F5F5F7` sobre `#3A3420` | **11,40:1** |
| `#A12A00` sobre `#F5E6B8` (icono) | **5,93:1** |
| `#FF9F0A` sobre `#3A3420` (icono) | **6,04:1** |
| `#98989D` sobre `#3A3420` | **4,32:1 FAIL texto** → **prohibido** `Color.secondary` dentro del banner |

Prohibido: `.yellow.opacity`, `.orange.opacity` como fondo, `Color.orange` de sistema sobre el fondo Light (el naranja de sistema ~`#FF9500` no llega a 3:1 estable sobre crema).

### 3.4 Color — paleta de avatares (iniciales blancas)

Ocho rellenos **idénticos en Light y Dark** (no aclarar en Dark: rompería el blanco de las iniciales). Todos ≥ 4,5:1 con `#FFFFFF`:

| Índice | Hex | Ratio blanco |
|-------:|-----|-------------:|
| 0 | `#0B6E75` | 6,00 |
| 1 | `#125EAB` | 6,53 |
| 2 | `#3D4A9E` | 7,86 |
| 3 | `#6B3FA0` | 7,38 |
| 4 | `#9B2D5A` | 7,20 |
| 5 | `#B85A00` | 4,67 |
| 6 | `#1F7A4D` | 5,32 |
| 7 | `#4A5568` | 7,53 |

Iniciales: siempre `#FFFFFF`. En Increase Contrast no cambiar la paleta (ya cumplen).

### 3.5 Tipografía (Dynamic Type, sin fuentes custom)

| Token | `Font` SwiftUI | Uso |
|-------|----------------|-----|
| `DS-TYPE-DISPLAY` | `.title.weight(.semibold)` | Nombre en hero del detalle |
| `DS-TYPE-TITLE` | `.headline` | Títulos de empty state, título del sheet, sección «Usuarios» |
| `DS-TYPE-BODY` | `.body` | Valores de ficha, copy de empty/error, texto de banner |
| `DS-TYPE-ROW` | `.body.weight(.semibold)` | Nombre en fila de lista |
| `DS-TYPE-ROW-SEC` | `.subheadline` | `@{username} · {email}` |
| `DS-TYPE-LABEL` | `.caption` | Labels de fila dentro de tarjeta («Teléfono») |
| `DS-TYPE-BADGE` | `.caption.monospacedDigit()` | `ID {n}` |
| `DS-TYPE-AVATAR-SM` | `.caption.weight(.semibold)` | Iniciales lista 28 pt |
| `DS-TYPE-AVATAR-LG` | `.title.weight(.semibold)` | Iniciales detalle 80 pt |
| `DS-TYPE-AVATAR-MD` | `.headline.weight(.semibold)` | Iniciales sheet 36 pt |
| `DS-TYPE-ERROR` | `.callout` | Mensaje de validación (ya existe) |

Alineación: **leading** en lista, detalle y form. Empty states: **center**. No truncar labels de formulario (A11Y-08). Nombre de fila y de hero: `lineLimit(1)` + `truncationMode(.tail)`. Secundaria de fila: `lineLimit(1)`.

### 3.6 Spacing (pt)

| Token | pt | Uso |
|-------|---:|-----|
| `DS-SPACE-2` | 2 | Gap entre nombre y secundaria en fila |
| `DS-SPACE-4` | 4 | Gap nombre / @username en hero; padding vertical extra de fila |
| `DS-SPACE-6` | 6 | Gap label–error en form (ya 6) |
| `DS-SPACE-8` | 8 | Padding interno banner; inset banner respecto al List |
| `DS-SPACE-10` | 10 | Gap avatar↔texto en fila |
| `DS-SPACE-12` | 12 | Padding horizontal interno banner; gap icono↔texto banner |
| `DS-SPACE-16` | 16 | Gap avatar↔bloque de texto en hero; padding interno de tarjeta |
| `DS-SPACE-20` | 20 | Gap entre tarjetas; padding vertical del detalle; padding del sheet |
| `DS-SPACE-24` | 24 | Padding horizontal del detalle |
| `DS-SPACE-32` | 32 | Gap título↔cuerpo en empty state si se customiza |

No usar spacing 0 entre avatar y texto. `VStack` raíz lista/banner: `spacing: 0` (el banner tiene su propio inset).

### 3.7 Radios (pt)

| Token | pt | Forma |
|-------|---:|-------|
| `DS-RADIUS-AVATAR` | 999 (círculo) | `Circle()` |
| `DS-RADIUS-CARD` | 10 | Tarjetas de detalle |
| `DS-RADIUS-BANNER` | 8 | Banner recarga |
| `DS-RADIUS-WELL` | 36 (círculo 72/2) | Fondo del SF Symbol en empty states |
| `DS-RADIUS-BADGE` | 4 | Cápsula `ID {n}` |

Sin `shadow` > `radius 8, y 1, opacity 0.12` y **solo** en Light sobre `DS-CARD` si el controlBackground no se separa del windowBackground. Preferible: **cero sombra** + stroke `DS-SEP` 0,5 pt + Increase Contrast stroke (véase §8). Estética Contactos, no elevación Material Design.

### 3.8 Materiales

| Zona | Receta |
|------|--------|
| Sidebar | La que ya aplica `NavigationSplitView` + `.listStyle(.sidebar)`. No pintar color sólido custom |
| Lienzo detalle | `windowBackgroundColor` (default). No `ultraThinMaterial` a pantalla completa |
| Tarjetas | **Opacas** `controlBackgroundColor`. No glass / liquid-glass custom |
| Sheet | Material de sheet de sistema |
| Banner | Relleno sólido `DS-BANNER-BG` (sin blur, sin opacity < 1) |

`Reduce Transparency` (Ajustes del Sistema): al ser opacos, las tarjetas y el banner **no dependen** del blur. No añadir `.background(.ultraThinMaterial)`.

### 3.9 Tamaños de componente (pt)

| Pieza | Tamaño |
|-------|--------|
| Avatar lista | **28 × 28** |
| Avatar sheet (header) | **36 × 36** |
| Avatar detalle (hero) | **80 × 80** |
| Well empty state | **72 × 72**, SF Symbol **32** |
| Icono de fila de tarjeta | **14 × 14** |
| Icono banner | **16 × 16** |
| Icono validación | tamaño de `.callout` (sistema) |
| Hit target toolbar / botones nativos | sistema (≥ 24, A11Y-21) |
| Ancho máximo columna de tarjetas | **560** |
| Sheet crear | **420** de ancho (sin cambio), padding **20**, altura intrínseca |
| Sidebar / ventana | sin cambio: 220–320 / min 760×480 / default 960×640 |

La columna de 560 se alinea **leading** (no centrada tipo landing web) con padding horizontal 24. Si el detalle mide 400 pt (mínimo), la tarjeta usa el ancho disponible (`frame(maxWidth: 560)`).

---

## 4. Avatar de iniciales

Nuevo componente de Presentation, p. ej. `AvatarUsuarioVista`. **Decorativo**: `.accessibilityHidden(true)`. El nombre accesible sigue en la fila combinada o en el título de detalle.

### 4.1 Iniciales

Entrada: `usuario.nombre` (no el username). Grapheme clusters (`String.prefix`, no `Character` ASCII).

1. Partir por espacios en blanco; descartar vacíos.  
2. 0 palabras → `"?"`.  
3. 1 palabra → primer grafema, `uppercased()`. Ejemplo: `"Bret"` → `"B"`.  
4. 2+ palabras → primer grafema de la **primera** + primer grafema de la **última**. Ejemplo: `"Leanne Graham"` → `"LG"`; `"Ada Lovelace"` → `"AL"`.

No usar fotos, no `AsyncImage`, no iniciales de email.

### 4.2 Color (estable entre lanzamientos)

**No** usar `hashValue` (no es estable).

```
suma = Σ codePoint de cada Unicode scalar de nombreUsuario
indice = suma % 8
si nombreUsuario vacío → indice = 7 (slate)
```

El color sigue al **username** para que editar el nombre no recolocee el círculo.

### 4.3 Layout interno

| Tamaño | Fuente iniciales | Tracking |
|--------|------------------|----------|
| 28 | `DS-TYPE-AVATAR-SM` | 0; si 2 letras, permitir que quepan sin comprimir < 0,8 scale |
| 36 | `DS-TYPE-AVATAR-MD` | 0 |
| 80 | `DS-TYPE-AVATAR-LG` | −0,5 pt si hay 2 letras |

Texto centrado. Fondo `Circle` relleno paleta. Sin borde. Sin sombra.

VoiceOver de fila: **no** anunciar «LG» ni «imagen». Conservar `accessibilityLabel` actual `"{name}, {username}, {email}"` y `children: .combine`.

---

## 5. Receta por pantalla

Identifiers existentes (`lista.*`, `detalle.id|nombre|username|email`, `form.*`, `toolbar.*`, `estado.*`) **no se renombran ni se duplican**. Los nuevos son aditivos (§9).

### 5.1 `S-LIST` — filas con identidad

```
HStack(alignment: .center, spacing: 10) {
    Avatar 28×28          // hidden
    VStack(alignment: .leading, spacing: 2) {
        Text(nombre)      // DS-TYPE-ROW + Color.primary, lineLimit 1
        Text(COPY-ROW-SEC)// DS-TYPE-ROW-SEC + Color.secondary, lineLimit 1, truncationMode .tail
    }
    Spacer(minLength: 0)
}
.padding(.vertical, 4)
.tag(id)
```

- `.listStyle(.sidebar)` se **mantiene**.  
- Altura de fila ≈ 28 + 8 = **36 pt** (≥ 24).  
- Header de sección y footer de conteo: sin cambio de copy. Footer: `DS-TYPE-LABEL` + `Color.secondary`.  
- Selección: nativa.  
- `accessibilityIdentifier`: `lista.usuario.{id}` en el contenedor de la fila (como ahora).

Jerarquía: el semibold del nombre es el ancla; la secundaria no compite (peso regular, estilo secondary). Si Accessibility Inspector midiera la secundaria < 4,5:1 en un contexto concreto, promocionar **solo esa línea** a `Color.primary` (regla ya en A11Y-C-01) — no inventar un gris hex.

### 5.2 Banner recarga (`estado.error.banner`)

Sustituir el `HStack` + amarillo 25 % por:

```
HStack(alignment: .center, spacing: 8) {
    Image(systemName: "exclamationmark.triangle.fill")  // 16 pt, foreground DS-BANNER-ICON
        .accessibilityHidden(true)
    Text(COPY-BANNER)  // DS-TYPE-BODY + Color.primary
    Spacer(minLength: 8)
    Button(COPY-RETRY) { … }  // .buttonStyle(.bordered), identifier estado.error.reintentar
}
.padding(.horizontal, 12)
.padding(.vertical, 8)
.background(DS-BANNER-BG, in: RoundedRectangle(8, style: .continuous))
.overlay(RoundedRectangle(8, style: .continuous).strokeBorder(DS-BANNER-STROKE, lineWidth: 1))
.padding(.horizontal, 8)
.padding(.top, 8)
```

- El identifier `estado.error.banner` permanece en el contenedor combinado.  
- Label combinado: sin cambio de contrato.  
- Botón Reintentar: texto visible (no icon-only).  
- No tapar el campo enfocado (A11Y-19): el banner empuja la lista hacia abajo; no es overlay absoluto.

### 5.3 Empty states gráficos

Conservar `ContentUnavailableView` (acciones y copy §8 de navegación). Envolver el Label en un **well** para que no sea un glifo huérfano:

```
ZStack {
    Circle().fill(wellFill).frame(72)
    Image(systemName: …).font(.system(size: 32)).foregroundStyle(wellGlyph)
}
```

| Estado | Symbol | Well fill Light | Well fill Dark | Glyph |
|--------|--------|-----------------|----------------|-------|
| `S-EMPTY-SEL` | `person.crop.rectangle.stack` | `#E6F3F3` | `#1A2E2D` | `DS-ACCENT` |
| `S-EMPTY-LIST` | `person.crop.rectangle.stack` | igual | igual | `DS-ACCENT` |
| `S-EMPTY-SEARCH` | `magnifyingglass` | igual | igual | `DS-ACCENT` |
| `S-ERROR` sin cache | `wifi.exclamationmark` | `#F5E6B8` / `#3A3420` | — | `DS-BANNER-ICON` |

Contraste glifo acento sobre well Light `#E6F3F3`: **5,28:1**. Dark `#5EC8C0` sobre `#1A2E2D`: **7,13:1**.

- `S-EMPTY-SEL`: sin botones (el alta vive en sidebar/menú). Identifier `detalle.vacio` en el `ContentUnavailableView`.  
- `S-EMPTY-LIST` / búsqueda / error: botones nativos **Nuevo usuario** / **Recargar** / **Limpiar búsqueda** / **Reintentar** — estilo `.bordered` secundaria, el primario de alta `.borderedProminent` (acento).  
- Cuerpo de empty: `Color.secondary` (sí cumple AA sobre window; no es el banner). Ancho de texto máximo **280 pt**, centrado.  
- Loading: `ProgressView` + `COPY-LOAD` centrado; **sin** skeleton bounce (A11Y-CON-03 / Reduce Motion).

### 5.4 `S-DETAIL` — ficha de perfil (no Form gris)

**Contenedor**: `ScrollView` > `VStack(alignment: .leading, spacing: 20)` > padding `24` horizontal, `20` vertical > `frame(maxWidth: 560, alignment: .leading)`. Fondo de columna: window background.

**No** usar `Form` / `LabeledContent` en lectura.

#### Bloque A — Hero (siempre)

```
HStack(alignment: .center, spacing: 16) {
    Avatar 80×80
    VStack(alignment: .leading, spacing: 4) {
        Text(nombre)           // DS-TYPE-DISPLAY, identifier detalle.nombre, traits .isHeader
        Text("@" + username)   // DS-TYPE-BODY + secondary, identifier detalle.username
        Text(email)            // DS-TYPE-BODY + primary, identifier detalle.email, textSelection(.enabled)
        Text("ID \(id)")       // DS-TYPE-BADGE, identifier detalle.id, padding 4×8, radius 4
                               // fill Color.secondary.opacity(0.18), texto Color.primary
    }
}
.padding(16)
.frame(maxWidth: .infinity, alignment: .leading)
.background(DS-CARD, in: RoundedRectangle(10, style: .continuous))
```

El label visible «Identificador» de v1 se sustituye por el badge `ID {n}`. El **nombre accesible** del badge debe seguir conteniendo «Identificador» (2.5.3): `accessibilityLabel("Identificador, \(id)")`. Copy de label `COPY-L-ID` no se borra.

Email: `textSelection(.enabled)`; **no** `Link` / no abrir Mail.app (igual que navegación §5.3).

Toolbar lectura: **Editar** `square.and.pencil`, identifier `toolbar.editar` — sin cambio de colocación.

#### Bloque B — Contacto (si hay teléfono o sitio web no vacíos)

Tarjeta con encabezado `COPY-SECTION-CONTACT` (`DS-TYPE-TITLE` o `subheadline.semibold` + secondary, trait `.isHeader`).

Filas internas (icono 14 pt `Color.secondary` + `.accessibilityHidden(true)` | label caption | valor body + `textSelection`):

| Campo | Symbol | Identifier nuevo | Se oculta si |
|-------|--------|------------------|--------------|
| Teléfono | `phone` | `detalle.telefono` | `telefono` vacío |
| Sitio web | `link` | `detalle.sitioWeb` | `sitioWeb` vacío |

Sitio web: **no** `Link` a Safari (mismo criterio que email). Icono `link`, no `globe` (evita colisión semántica con el `globe` de la plantilla Hello World, A11Y-VO-05).

Separador entre filas: `DS-SEP` 0,5 pt, inset leading 30 pt (alineado al texto, no al icono).

#### Bloque C — Dirección (si la dirección no es `.vacia`)

Encabezado `COPY-SECTION-ADDRESS`. Un solo bloque de valor, identifier `detalle.direccion`:

```
{calle}, {apartamento}
{ciudad}  {codigoPostal}
```

Si `apartamento` vacío: una sola línea `{calle}`. No mostrar lat/lng (no es Contactos; no aporta). Icono de encabezado `map` hidden.

#### Bloque D — Empresa (si `empresa.nombre` no vacío)

Encabezado `COPY-SECTION-COMPANY`. Identifier `detalle.empresa` en el contenedor.

| Label | Valor | ¿Nuevo identifier de valor? |
|-------|-------|------------------------------|
| `COPY-L-COMPANY` | `empresa.nombre` | no; vive bajo `detalle.empresa` |
| `COPY-L-SLOGAN` | `empresa.eslogan` | ocultar fila si vacío |
| `COPY-L-RUBRO` | `empresa.rubro` | ocultar fila si vacío |

Los strings de eslogan/rubro de JSONPlaceholder vienen en inglés: se muestran **como dato**, no como chrome de UI.

Usuario **recién creado** (dirección/empresa vacías): solo hero. No renderizar tarjetas vacías (ST-03: vacío ≠ placeholder de “sin datos” ruidoso).

Jerarquía visual: **80 pt avatar + `.title` nombre** = ancla. Las tarjetas B–D son secundarias (caption labels, body values). No repetir nombre/email en B.

### 5.5 `S-EDIT` — formulario in-place

Sigue **`Form` `.formStyle(.grouped)`** (entrada de datos nativa). Encima del Form, **dentro de la columna detalle**, una franja de identidad de 16 pt de padding:

```
HStack(spacing: 12) {
    Avatar 36×36  // mismas iniciales/color que lectura
    Text(COPY-NAV-EDIT)  // ya es el navigationTitle; no duplicar en grande
}
```

Si el `navigationTitle` ya muestra `Editar — {name}`, la franja puede ser **solo el avatar 36** leading, para no duplicar el título. Preferir: avatar 36 + Form; título de columna intacto.

Campos, orden de foco, identifiers `form.*`, errores con icono + `Color.red`: **sin cambio**.

Botones Guardar / Cancelar: **una sola instancia** con `form.guardar` / `form.cancelar`. Preferir moverlos a la **toolbar** de la columna detalle (NAV-11) con `Guardar` = `.borderedProminent` y `Cancelar` = `.bordered` / rol cancel. Si se mueven, **quitarlos** del pie del Form para no duplicar identifiers.

Ancho: el grouped Form usa el ancho de la columna (correcto en macOS). No forzar 560 aquí: el Form grouped ya tiene márgenes de sistema.

### 5.6 `S-CREATE` — sheet 420 pt

```
VStack(alignment: .leading, spacing: 16) {
    HStack(alignment: .center, spacing: 12) {
        Avatar 36×36  // iniciales del borrador.nombre en vivo; si nombre vacío, "?"
        Text(COPY-SHEET-NEW).font(.headline)  // .isHeader
    }
    FormularioUsuarioVista(…)  // Form grouped existente
}
.frame(width: 420)
.padding(20)
```

- Foco inicial: `form.nombre` (A11Y-FOCUS-01).  
- Guardar: `.borderedProminent`. Cancelar: a la izquierda de Guardar, mismo orden de foco §7.3.  
- El avatar del header es decorativo (hidden).  
- No full-screen. No cambiar 420 pt.

### 5.7 Toolbar

| Columna / modo | Ítems | Symbol | Style visual |
|----------------|-------|--------|----------------|
| Sidebar | Nuevo usuario, Recargar (+ `ProgressView` small si recarga) | `plus`, `arrow.clockwise` | Icon-only nativo de toolbar + `accessibilityLabel` y `help` existentes |
| Detalle lectura | Editar | `square.and.pencil` | igual |
| Detalle edición | Cancelar, Guardar | — (texto) | Guardar prominent |

No añadir botones de compartir, favorito, delete. No `labelStyle` custom que oculte el nombre accesible. Los identifiers `toolbar.nuevo`, `toolbar.recargar`, `toolbar.editar` **no se mueven de control**.

---

## 6. Catálogo SF Symbols (cerrado para v1 visual)

| ID | Symbol | Rendering | Dónde | A11y |
|----|--------|-----------|-------|------|
| `SYM-NEW` | `plus` | monochrome | toolbar / menú | label `COPY-NEW` |
| `SYM-RELOAD` | `arrow.clockwise` | monochrome | toolbar / menú | label `COPY-RELOAD` |
| `SYM-EDIT` | `square.and.pencil` | monochrome | toolbar detalle | label `COPY-EDIT` |
| `SYM-PEOPLE` | `person.crop.rectangle.stack` | monochrome | empty sel / lista vacía | hidden si hay título visible junto al icono (el Label de ContentUnavailableView ya nombra) |
| `SYM-SEARCH` | `magnifyingglass` | monochrome | búsqueda vacía | igual |
| `SYM-WIFI` | `wifi.exclamationmark` | monochrome | error sin cache | igual |
| `SYM-WARN` | `exclamationmark.triangle.fill` | monochrome | banner | hidden; el texto COPY-BANNER nombra |
| `SYM-VAL` | `exclamationmark.circle` | monochrome | error de campo | hidden; el campo anuncia el error |
| `SYM-PHONE` | `phone` | monochrome | tarjeta contacto | hidden |
| `SYM-WEB` | `link` | monochrome | tarjeta contacto | hidden |
| `SYM-MAP` | `map` | monochrome | tarjeta dirección | hidden |
| `SYM-ORG` | `building.2` | monochrome | tarjeta empresa | hidden |

Peso: **regular** en contenido; toolbar deja el peso de sistema. Escala: toolbar sistema; wells 32 pt; filas de tarjeta 14 pt.

**Prohibido**: `globe` decorativo de plantilla; `sparkles`; symbols multicolor `.palette` en lista; assets bitmap.

---

## 7. Copy extra (solo lo añadido)

El catálogo de `navegacion-usuarios.md` §8 sigue vigente. Developer **no improvisa**. Añadir en `TextosUsuarios` y, si aplica, anunciar a VoiceOver con el texto visible.

| ID | Contexto | String |
|----|----------|--------|
| `COPY-SECTION-CONTACT` | Encabezado tarjeta B | Contacto |
| `COPY-SECTION-ADDRESS` | Encabezado tarjeta C | Dirección |
| `COPY-SECTION-COMPANY` | Encabezado tarjeta D | Empresa |
| `COPY-L-PHONE` | Label | Teléfono |
| `COPY-L-WEB` | Label | Sitio web |
| `COPY-L-SLOGAN` | Label | Eslogan |
| `COPY-L-RUBRO` | Label | Rubro |
| `COPY-ID-BADGE` | Badge visible | `ID {n}` |
| `COPY-ID-A11Y` | Label del badge | `Identificador, {n}` |

No hace falta copy nuevo para empty states ni banner. `COPY-L-ID`, `COPY-L-COMPANY` (si se usó «Empresa» como sección, el label de nombre de empresa **reutiliza** el mismo «Empresa» solo en la fila de valor si hay eslogan/rubro; si solo hay nombre, el encabezado de sección basta y la fila no duplica el label).

Regla anti-duplicación: si la tarjeta Empresa tiene **solo** `nombre`, mostrar el nombre como `.body` sin label «Empresa» debajo del header. Si hay eslogan o rubro, sí usar labels.

Tono: el de COPY-01 / COPY-02 (tuteo neutro, sin “Oops”).

---

## 8. Dark Mode + Increase Contrast + Reduce Transparency

| Entorno | Qué debe pasar |
|---------|----------------|
| Light | Acento `#0B6E75`, avatares paleta §3.4, tarjetas `controlBackgroundColor`, banner `#F5E6B8` + texto `primary` |
| Dark | Acento `#5EC8C0` **solo** como glifo o relleno con texto `#1C1C1E`. Avatares **misma paleta oscura** (blanco de iniciales). Banner `#3A3420` + texto `primary` |
| Increase Contrast (`@Environment(\.colorSchemeContrast) == .increased`) | Asset AccentColor high-contrast. Stroke de tarjeta **1 pt** `Color.primary.opacity(0.45)`. Stroke banner opacity 0,70. No bajar `secondary` a hex. Secondary de sistema ya se endurece |
| Differentiate Without Color | Selección de lista nativa (no solo tinte). Error = icono + texto. Banner = icono + texto + stroke, no solo crema |
| Reduce Transparency | Ya cubierto: cero materiales translúcidos de producto |
| Reduce Motion | Sheet y lista = transiciones de sistema. Prohibido scale bounce en avatar / well |

Checklist visual extra (se suma a §9 de navegación):

- [ ] `A11Y-C-05` Banner: texto `primary` sobre `DS-BANNER-BG` en Light **y** Dark (Inspector Contrast ≥ 4,5:1).  
- [ ] `A11Y-C-06` Iniciales blancas sobre cada uno de los 8 rellenos (muestrear 2 índices basta en Inspector; el resto está calculado).  
- [ ] `A11Y-C-07` Botón Guardar `borderedProminent`: en Dark el label **no** es blanco sobre `#5EC8C0` si el sistema no invierte; si el label nativo fallara AA, usar `.foregroundStyle(Color(red: 28/255, green: 28/255, blue: 30/255))` solo en Dark sobre prominent.  
- [ ] `A11Y-C-08` Increase Contrast: stroke de tarjetas visible; empty-well no se come el glifo.

`A11Y-C-05` es **bloqueante** G10 (el banner actual es el riesgo real). `A11Y-C-06`–`C-08` son no bloqueantes (CONDITIONAL).

---

## 9. Identifiers de a11y

### 9.1 Invariantes (UITests actuales)

`lista.busqueda`, `lista.usuario.{id}`, `lista.titulo`, `toolbar.nuevo`, `toolbar.recargar`, `toolbar.editar`, `detalle.vacio`, `detalle.id`, `detalle.nombre`, `detalle.username`, `detalle.email`, `form.nombre`, `form.username`, `form.email`, `form.guardar`, `form.cancelar`, `estado.cargando`, `estado.listaVacia`, `estado.busquedaVacia`, `estado.error.reintentar`, `estado.error.banner`.

Tras el rediseño, `detalle.nombre` vive en el `Text` del hero (no en `LabeledContent`). `testToolbarNuevoAbreFormularioNombre` no debe romperse: el sheet sigue montando `form.nombre`.

### 9.2 Aditivos (opcionales para QA; no usados aún por UITests)

| Identifier | Elemento |
|------------|----------|
| `detalle.telefono` | Valor teléfono |
| `detalle.sitioWeb` | Valor sitio web |
| `detalle.direccion` | Bloque de dirección |
| `detalle.empresa` | Contenedor empresa |

No identifier en el avatar (hidden). No `lista.avatar.{id}`.

---

## 10. Hallazgos visuales / a11y (estado actual)

| Sev. | Hallazgo | Evidencia | WCAG | Remediación (este DS) |
|------|----------|-----------|------|------------------------|
| Medium | Banner `.yellow.opacity(0.25)` contraste no tokenizado | `ListaUsuariosVista.swift` fondo del banner | 1.4.3 | Tokens `DS-BANNER-*` |
| Medium | `AccentColor` vacío | `AccentColor.colorset/Contents.json` sin `components` | 1.4.1 (no único medio) + identidad | Rellenar asset §3.1 |
| Low | Detalle `Form` grouped parece inspector vacío | `DetalleUsuarioVista.swift` | Usabilidad (no fallo WCAG) | ScrollView + hero 80 pt |
| Low | Filas sin identidad visual | `ListaUsuariosVista.swift` dos `Text` | Usabilidad | Avatar 28 pt |
| Info | `Direccion` / `Empresa` / teléfono / web en Domain, ocultos | `Usuario.swift` vs detalle | — | Tarjetas B–D si hay datos |
| Info | Empty states = `ContentUnavailableView` plano | lista + detalle | 1.1.1 OK (tienen Label) | Well 72 pt |

Teclado, labels, identifiers y menú de `navegacion-usuarios.md` **no se reabren** aquí: siguen siendo el contrato. Este DS no introduce trampas de foco ni iconos de toolbar huérfanos.

---

## 11. Gate G10 — verdict

### 11.1 Esta entrega (spec visual, sin código de producción)

| Gate | Status | Evidencia | Notas |
|------|--------|-----------|-------|
| G0 Context | PASS | Handoff EE-UX-20260919-2 | Swift 5 / SwiftUI / macOS 27; JSONPlaceholder; identifiers vigentes |
| G10 Accessibility | CONDITIONAL | `degraded: revisión manual WCAG` — contrastes **calculados** (tabla §3) sobre hex de tokens; **no** hay captura de Accessibility Inspector ni axe (no aplica a AppKit) | PASS real solo tras implementar + Inspector Light/Dark/IC + checklist §8 `A11Y-C-05` |

Máximo en degradado: **CONDITIONAL** (quality-gates.md).

### 11.2 Previsto tras implementación

- **PASS** si: tokens en asset + recetas §5 + identifiers invariantes verdes en UITests + `A11Y-C-05` medido en Inspector.  
- **CONDITIONAL** si: bloqueantes de navegación + banner OK, pero faltan tarjetas B–D o wells.  
- **FAIL** si: se pierde un identifier, se usa blanco sobre `#5EC8C0`, se vuelve al amarillo 25 %, o se cambia la navegación.

**Backlog tooling** (no bloquea): CI con UITests de identifiers; guía README de Accessibility Inspector (ya en navegación §10).

---

## 12. Handoff hacia Developer

## Handoff: @ux-accessibility-agent → @senior-fullstack-developer-agent
**Handoff-ID**: UX-DEV-20260919-2  
**Prioridad**: P0

### Contexto detectado
- Stack: Swift 5 / SwiftUI / macOS 27 (NO iOS)
- Arquitectura: ADR-001 Clean Architecture (Domain/Data/Presentation). NO cambiar capas.
- DB/ORM: JSONPlaceholder REST
- Build: `xcodebuild -scheme GestionUsuarios -destination 'platform=macOS'`
- Test: Swift Testing + XCTest UI (identifiers `lista.*`, `detalle.*`, `form.*`, `toolbar.*` DEBEN conservarse)
- Lint: no detectado
- CI: no detectado
- Constraints: App Sandbox; HIG macOS; español; menú `.commands` ya existe; WCAG 2.2 A/AA de `docs/ux/navegacion-usuarios.md` no se relaja; `Color.primary/secondary` de sistema para texto; Dark Mode; no TabView; no NavigationStack raíz

### Alcance
- **Incluye**: aplicar este design system **solo en Presentation** + `AccentColor.colorset`; avatar; hero de detalle; banner tokenizado; empty wells; copy `COPY-*` nuevos; identifiers aditivos opcionales; mostrar teléfono/web/dirección/empresa en detalle si hay datos
- **Excluye**: Domain/Data; validación del form; campos nuevos de alta/edición; cambiar atajos o `NavigationSplitView`; iconos bitmap; iOS; animaciones bounce; código fuera de Presentation/Assets
- **Archivos afectados** (tocar estos; no Domain/Data):
  - `GestionUsuarios/Assets.xcassets/AccentColor.colorset/Contents.json` — 4 apariencias §3.1
  - `GestionUsuarios/Presentation/Usuarios/Lista/ListaUsuariosVista.swift` — fila avatar; banner tokens
  - `GestionUsuarios/Presentation/Usuarios/Detalle/DetalleUsuarioVista.swift` — reemplazar Form de lectura por ScrollView + hero + tarjetas
  - `GestionUsuarios/Presentation/Usuarios/Formulario/FormularioUsuarioVista.swift` — Guardar prominent; si se mueven botones a toolbar, **una** instancia de identifiers
  - `GestionUsuarios/Presentation/Usuarios/RaizUsuariosVista.swift` — chrome del sheet (header avatar 36 + padding 20); toolbar de edición si se alinean botones a NAV-11
  - `GestionUsuarios/Presentation/Navegacion/TextosUsuarios.swift` — strings §7 + identifiers aditivos
  - **Nuevo** `GestionUsuarios/Presentation/Tema/TemaUsuarios.swift` — spacing, radios, paleta, banner colors
  - **Nuevo** `GestionUsuarios/Presentation/Componentes/AvatarUsuarioVista.swift` — iniciales + paleta
  - UITests: no romper `toolbar.nuevo` / `form.nombre`; no hace falta test nuevo de avatar

### Artefactos entregados
- `docs/ux/design-system-usuarios.md` (tokens, recetas, contraste, copy, G10, este handoff)

### Decisiones tomadas
| Decisión | Justificación | Alternativa descartada |
|----------|---------------|------------------------|
| Acento teal `#0B6E75` / `#5EC8C0` | Ficha de personas (Contactos), no azul Mail genérico; blanco sobre Light 6,00:1 | Dejar AccentColor vacío; blanco sobre acento Dark (2,00:1 FAIL) |
| Detalle = ScrollView + tarjetas, Form solo en edición/alta | El Form grouped de lectura es el “inspector vacío”; el Form sigue siendo idiomático para editar | Rediseñar también el form como cards de inputs (menos nativo, más web) |
| Avatar 28 / 36 / 80, paleta 8 hex fijos | Identidad sin fotos ni red; contraste de iniciales calculado | Color.accentColor en todos (filas indistinguibles); hashValue (inestable) |
| Banner sólido crema/oliva + `primary` | 1.4.3 predecible | `.yellow.opacity(0.25)` |
| Extra Domain en detalle, no en form | Enriquecimiento visual sin cambiar validación ni API | Pedir teléfono en el alta (fuera de alcance) |
| Columna de ficha max 560 pt leading | Contactos/Mail, no dashboard a todo el ancho | Grid de 2 columnas tipo Settings web |
| G10 CONDITIONAL | Contraste calculado; Inspector no ejecutado | PASS sin evidencia de runtime |

### Riesgos abiertos
| Riesgo | Severidad | Requiere validación de |
|--------|-----------|------------------------|
| `borderedProminent` en Dark pone label blanco sobre `#5EC8C0` | Media | Developer + Inspector (`A11Y-C-07`) |
| `Color.secondary` en fila sidebar < 4,5:1 en IC raro | Baja | Inspector (`A11Y-C-01` existente) |
| UITest frágil si `detalle.nombre` deja de existir en el árbol | Media | Mantener identifier en el `Text` del hero |
| Sheet 420 + avatar header recorta en Dynamic Type XXXL | Baja | QA: ventana / type size; scroll del Form |

### Criterio de éxito
- [ ] `AccentColor` con los 4 hex de §3.1 (no asset vacío)
- [ ] Filas con avatar 28 pt e iniciales; identifier `lista.usuario.{id}` intacto
- [ ] Detalle tipo ficha (hero 80 pt + tarjetas), no Form de lectura; `detalle.nombre|username|email|id` presentes
- [ ] Banner sin `.yellow.opacity`; texto `primary` sobre `DS-BANNER-BG`
- [ ] Form alta/edición sigue 3 campos; sheet 420 pt
- [ ] UITests existentes verdes; build `xcodebuild` macOS verde
- [ ] Light + Dark: sin blanco sobre `#5EC8C0`

### Gates pendientes
| Gate | Esperado |
|------|----------|
| G10 | CONDITIONAL (Inspector) o PASS con `A11Y-C-05` |
| G2 | Tras código: `xcodebuild` build sin errores |
| G6 | UITests identifiers invariantes |
| G3 | Review post-implementación |
| G1 | SKIP (no hay cambio de capas; ADR-001 intacto) |

### Comandos de verificación
- Build: `xcodebuild -scheme GestionUsuarios -destination 'platform=macOS' build`
- Test: `xcodebuild -scheme GestionUsuarios -destination 'platform=macOS' test`
- Lint: no detectado
- A11y: Accessibility Inspector → Audit + Contrast en Light, Dark e Increase Contrast (manual; `degraded`)

---

## Referencias

- `docs/ux/navegacion-usuarios.md` — IA, menú, WCAG, copy base, identifiers
- `docs/adr/ADR-001-clean-architecture-usuarios.md` — capas (no modificar)
- Apple HIG — macOS (sidebars, inspectors vs content, toolbars, materials)
- WCAG 2.2 §1.4.3, §1.4.11, §1.4.1, §2.5.3
- AgentesAI quality-gates G10
