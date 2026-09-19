# Threat Model: Gestión de usuarios (cliente macOS)

**Handoff-ID**: ARCH-SEC-20260919-1  
**Fecha**: 2026-09-19  
**Owner**: `@security-specialist-agent`  
**Alcance**: STRIDE + OWASP Mobile/MASVS cliente. Sin backend propio. **No se reescribió la app.**

## Scope

- **Componentes**: app SwiftUI macOS (`com.devapp.GestionUsuarios`); capas Domain / Data / Presentation; Composition Root `ContenedorApp`; egress HTTPS a JSONPlaceholder.
- **Data classification**: dataset público fake; **correo y teléfono se tratan como PII** en logs y almacenamiento (política del ADR-001).
- **Trust boundaries**:
  1. Proceso sandbox (usuario local) → red (ATS + `network.client`).
  2. App → host `jsonplaceholder.typicode.com` (terceros, API pública sin auth).
  3. Overlay de sesión en memoria (`UsuarioRepositorioSesion`) **no** es control de seguridad: solo corrige persistencia ilusoria.

## Assets

| Asset | Sensitivity | Location |
|-------|-------------|----------|
| Nombre, username, correo (formulario / lista) | PII (tratar como Confidential) | Memoria de proceso; cuerpo JSON en tránsito HTTPS; UI |
| Teléfono / sitio web (DTO remoto) | PII / Internal | Respuesta GET; no se editan en el formulario actual |
| `UsuarioID` (`Int`) | Public | Path `/users/{id}` |
| Overlay altas/ediciones de sesión | Internal + PII | RAM del `actor`; se pierde al cerrar la app |
| Secrets / tokens / API keys | N/A | No hay |
| Certificado TLS del host remoto | High (integridad del canal) | Trust store del sistema (ATS) |

## Superficie verificada

| Elemento | Evidencia | Resultado |
|----------|-----------|-----------|
| Egress | `EndpointsJSONPlaceholder.swift:4` `https://jsonplaceholder.typicode.com` | Host constante HTTPS |
| Endpoints | GET/POST `/users`; GET/PUT `/users/{id}` | Sin DELETE; verbos acotados |
| Path id | `EndpointsJSONPlaceholder.swift:10-11` `appending(path: String(id.valor))` con `UsuarioID.valor: Int` | Sin concatenación sucia; no SSRF |
| Entitlements file | `GestionUsuarios.entitlements:5-8` sandbox + `network.client` | Mínimo en el plist |
| Entitlements Xcode | `project.pbxproj:377-378` / `:411-412` `ENABLE_APP_SANDBOX=YES`, `ENABLE_HARDENED_RUNTIME=YES` | Sandbox + Hardened Runtime |
| Extra Xcode | `project.pbxproj:380` y `:414` `ENABLE_USER_SELECTED_FILES = readonly` | **Least privilege** (Low) |
| ATS | `GENERATE_INFOPLIST_FILE=YES`; **cero** `NSAllowsArbitraryLoads` / excepciones ATS en repo | ATS por defecto |
| Sesión HTTP | `ContenedorApp.swift:38-42` `URLSessionConfiguration.ephemeral`, timeout 15 s, `waitsForConnectivity = false` | Sin caché/cookies en disco |
| Logs | `ClienteHTTPURLSession.swift:41-49` `#if DEBUG`; status code `privacy: .public`; error sin cuerpo | Sin PII en logs |
| Parser | `UsuarioDTO.swift` + `JSONDecoder`/`JSONEncoder` | Codable; no `eval`; no `JSONSerialization` suelto |
| Secrets | Grep + SAST | Ninguno |
| Auth | API pública | Fuera de alcance (documentado) |

## STRIDE Analysis

| Threat | Category | Component | Description | Mitigation | Status |
|--------|----------|-----------|-------------|------------|--------|
| MITM / host spoofing | Spoofing | Canal TLS | Atacante en red local se hace pasar por JSONPlaceholder | ATS (HTTPS + CA de sistema); host fijo; sin HTTP cleartext | Mitigated (residual: sin pinning) |
| JSON remoto alterado | Tampering | `APIUsuariosJSONPlaceholder` + mapper | Cuerpo malicioso o truncado | `JSONDecoder` estricto; geo inválida → `nil` (`UsuarioMapeador.swift:57-62`); HTTP no 2xx → `ErrorUsuario` | Mitigated |
| Path `/users/{id}` | Tampering | `EndpointsJSONPlaceholder` | Inyección `../` o query en id | `UsuarioID` es `Int`; `URL.appending(path:)` | Mitigated |
| Overlay ≠ servidor | Tampering / Repudiation | `UsuarioRepositorioSesion` | Usuario cree que el alta es persistente | Overlay documentado; no es control de integridad remota | Accepted (producto) |
| Negar acciones CRUD | Repudiation | Cliente | Sin auditoría de quién editó | App local de un usuario; sin cuentas | Accepted |
| PII en logs / caché | Information Disclosure | `ClienteHTTPURLSession`, `URLSession` | Email/teléfono en os_log o URLCache | Logs DEBUG sin cuerpo; sesión ephemeral | Mitigated |
| PII a tercero | Information Disclosure | POST/PUT | Formulario envía nombre/correo a typicode | API de demo; HTTPS; no persistencia real del host | Residual Low |
| Timeout / flood | Denial of Service | Cliente HTTP | Colgar UI o reintentos infinitos | Timeout 15 s; 1 reintento solo GET (`ClienteHTTPURLSession.swift:20-21`); POST/PUT sin retry | Mitigated |
| Payload enorme en correo | Denial of Service | `ValidadorUsuario` | Campo correo sin tope de longitud | Nombre 2–80; username 3–20; correo solo formato | Open Low |
| Escalada de privilegio | Elevation of Privilege | App | Roles, IPC, server incoming | Sin roles; sin `network.server`; un usuario local | N/A |
| Archivos de usuario | Elevation of Privilege | Sandbox Xcode | `ENABLE_USER_SELECTED_FILES=readonly` inyecta capacidad no usada (no hay `NSOpenPanel`) | Quitar el setting (fix Developer) | Open Low |

## STRIDE Categories Reference

- **S**poofing — falsificar identidad
- **T**ampering — modificar datos
- **R**epudiation — negar acciones
- **I**nformation Disclosure — exposición de datos
- **D**enial of Service — indisponibilidad
- **E**levation of Privilege — escalamiento de permisos

## OWASP Mobile / cliente (mapeo)

| Control | Resultado |
|---------|-----------|
| M1 Credential Usage | N/A — sin credenciales |
| M2 Supply chain | Sin SPM/CocoaPods; solo SDK Apple. SCA Snyk: sin manifiestos |
| M3 AuthN/AuthZ | N/A por diseño (API pública) |
| M4 Input/Output | Validación de dominio + Codable |
| M5 Insecure Communication | HTTPS + ATS; pinning no exigido en demo |
| M6 Privacy | Logs OK; egress a tercero residual |
| M7 Binary protection | Hardened Runtime ON |
| M8 Misconfiguration | Extra `user-selected files` en pbxproj |
| M9 Insecure storage | Ephemeral + overlay RAM; no Keychain/UserDefaults de PII |
| M10 Crypto | N/A (TLS del sistema) |

## Attack Scenarios

1. **MITM con CA corporativa/rogue**: el atacante intercepta GET `/users` y sustituye correos → la UI muestra PII falsa. Impacto: integridad de visualización. Mitigación actual: ATS. Residual: pinning no implementado (aceptado para demo).
2. **Inyección en id**: input de UI no construye la URL; el id sale de `UsuarioID` (`Int`) y de la lista remota. No hay concatenación de strings de usuario al path.
3. **Dump de logs Release**: no hay `Logger` en Release; en DEBUG solo status HTTP y “Fallo de transporte”.
4. **Forzar HTTP**: ATS bloquea cleartext; no hay excepciones en Info.plist generado.
5. **SSRF de cliente**: base URL constante; el usuario no configura host.

## Hallazgos (file:line)

| ID | Sev | OWASP | Ubicación | Descripción |
|----|-----|-------|-----------|-------------|
| SEC-001 | Low | M8 | `GestionUsuarios.xcodeproj/project.pbxproj:380` y `:414` | `ENABLE_USER_SELECTED_FILES = readonly` amplia el sandbox respecto al ADR (solo `network.client`). El plist de entitlements está correcto; Xcode puede inyectar `files.user-selected.read-only` al firmar. La app no abre archivos. |
| SEC-002 | Low | M5 | Residual de diseño | Sin certificate pinning. ATS + host fijo mitigan MITM genérico; un proxy con CA de confianza del sistema sigue siendo posible. Aceptable en demo pública. |
| SEC-003 | Low | M6 | `CrearUsuarioCasoUso` / POST `APIUsuariosJSONPlaceholder.swift:37-43` | Correo y nombre tecleados salen hacia un host de terceros. Dataset fake; falta copy de privacidad (no es fuga por logs). |
| SEC-004 | Low | M4 | `ValidadorUsuario.swift:91-98` | Correo sin longitud máxima (sí hay formato). Riesgo local de payload grande, no RCE. |

**Critical: 0 · High: 0 · Medium: 0 · Low: 4 (1 code/config + 3 residuales)**

Controles confirmados (no son hallazgos):

- Entitlements mínimos en archivo: `GestionUsuarios.entitlements:5-8`.
- ATS sin arbitrary loads.
- Id `Int` en `EndpointsJSONPlaceholder.swift:10-11`.
- Logs sin cuerpos: `ClienteHTTPURLSession.swift:41-49`.
- Codable: `UsuarioDTO.swift:22-31`, `APIUsuariosJSONPlaceholder.swift:75-80`.
- Sin secrets en código.

## Fix recomendado (no implementado — alcance de auditoría)

1. **SEC-001 (Developer)**: en Debug y Release, `ENABLE_USER_SELECTED_FILES = Disabled` (o eliminar la clave) para alinear pbxproj con el plist.
2. **SEC-002**: no exigir pinning mientras el host sea JSONPlaceholder de demo. Reevaluar si hay API propia.
3. **SEC-003 (UX/PM)**: una línea en UI de que los datos viajan a un servicio de prueba público.
4. **SEC-004 (Developer)**: tope de longitud de correo (p. ej. 254) en `ValidadorUsuario`.

## Scan

| Tool | Resultado |
|------|-----------|
| Snyk Code (`snyk_code_scan`) path `/Users/waldofeliz/Desktop/Project/Apple/GestionUsuarios` | **success, issueCount: 0** (Snyk MCP 1.1307.3) |
| Snyk Secrets | `degraded: feature not enabled` (SNYK-CLI-0016, org sin Snyk Secrets). Revisión manual: 0 coincidencias de keys/tokens/PEM |
| Snyk SCA | N/A — sin `Package.swift` / lockfiles; solo frameworks de Apple. No hay SBOM de terceros |

## Security Requirements

- [x] App Sandbox ON + solo cliente de red en el archivo `.entitlements`
- [x] ATS sin `NSAllowsArbitraryLoads`
- [x] URL base constante HTTPS; id numérico
- [x] Codable estricto; sin `eval`
- [x] Logs Release sin cuerpos PII
- [x] Sin secrets
- [ ] Least privilege Xcode: sin `ENABLE_USER_SELECTED_FILES` (SEC-001)
- [ ] Snyk Secrets habilitado en la org (tooling)

## Residual Risk

| Risk | Severity | Accept? | Compensating control |
|------|----------|---------|---------------------|
| MITM vía CA de confianza (sin pinning) | Low | Y (demo) | ATS + host fijo |
| PII de formulario a JSONPlaceholder | Low | Y (API fake) | HTTPS; overlay no persiste en disco |
| `ENABLE_USER_SELECTED_FILES` | Low | N (cerrar en backlog) | App no usa Open/Save |
| Correo sin max length | Low | Y corto plazo | Regex + trim |
| Overlay interpretado como integridad | Low | Y | Comentario en `UsuarioRepositorioSesion.swift:3-4` |
| Snyk Secrets no disponible | Tooling | N | Grep manual en esta auditoría |

## Quality Gate G4

| Campo | Valor |
|-------|-------|
| Verdict | **CONDITIONAL** |
| Critical/High abiertos | 0 |
| Evidencia | este archivo + Snyk Code 0 issues |
| Degraded | `degraded: Snyk Secrets feature disabled (SNYK-CLI-0016)`; SCA N/A (sin manifiestos) |

CONDITIONAL por observaciones Low + Secrets MCP degradado. **No hay FAIL**: cero Critical/High.

## Backlog

| ID | Prioridad | Acción | Owner |
|----|-----------|--------|-------|
| SEC-001 | P2 | Desactivar `ENABLE_USER_SELECTED_FILES` | `@senior-fullstack-developer-agent` |
| SEC-004 | P3 | Max length correo | Developer |
| SEC-003 | P3 | Copy de privacidad / destino de datos | PM + UX |
| TOOL-001 | P2 | Habilitar Snyk Secrets en la org | DevOps / plataforma |
| TOOL-002 | P3 | SBOM cuando existan deps SPM | DevOps |
| SEC-002 | P3 | Pinning solo si hay API propia | Architect + Security |

## References

- ADR-001: `docs/adr/ADR-001-clean-architecture-usuarios.md`
- Handoff ARCH-SEC-20260919-1
- Plantilla: AgentesAI `skills/_shared/threat-model-template.md`
- JSONPlaceholder Users: https://jsonplaceholder.typicode.com/users
