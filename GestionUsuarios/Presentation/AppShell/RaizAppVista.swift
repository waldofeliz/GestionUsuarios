import SwiftUI

struct RaizAppVista: View {
    @State private var modelo: ShellVistaModelo
    @Binding var sesion: Sesion?
    @Environment(\.colorScheme) private var esquema

    init(contenedor: ContenedorApp, sesion: Binding<Sesion?>) {
        _sesion = sesion
        _modelo = State(initialValue: ShellVistaModelo(contenedor: contenedor))
    }

    var body: some View {
        NavigationSplitView(columnVisibility: Binding(
            get: { modelo.usuarios.coordinador.visibilidadColumnas },
            set: { modelo.usuarios.coordinador.visibilidadColumnas = $0 }
        )) {
            sidebar
        } detail: {
            detalle
                .frame(minWidth: 400)
        }
        .navigationSplitViewStyle(.balanced)
        .navigationTitle(modelo.tituloVentana)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    modelo.intentarCerrarSesion()
                } label: {
                    Label(TextosUsuarios.cerrarSesion, systemImage: "rectangle.portrait.and.arrow.right")
                }
                .help(TextosUsuarios.helpCerrarSesion)
                .accessibilityLabel(TextosUsuarios.cerrarSesion)
                .accessibilityIdentifier(IdentificadorAccesibilidad.toolbarLogout)
            }
        }
        .focusedSceneValue(\.modeloUsuarios, modelo.usuarios)
        .focusedSceneValue(\.shellApp, modelo)
        .onChange(of: modelo.cierreSolicitado) { _, solicitado in
            if solicitado {
                sesion = nil
            }
        }
        .task {
            await modelo.usuarios.cargarInicial()
        }
        .sheet(isPresented: Binding(
            get: { modelo.usuarios.coordinador.mostrandoAlta },
            set: { nuevo in
                if nuevo {
                    modelo.usuarios.coordinador.mostrandoAlta = true
                } else {
                    modelo.usuarios.intentarCerrarAlta()
                }
            }
        )) {
            sheetAlta
                .interactiveDismissDisabled(modelo.usuarios.hayCambiosAlta)
        }
        .alert(TextosUsuarios.descartarTitulo, isPresented: Binding(
            get: { modelo.usuarios.coordinador.alertaDescartar },
            set: { modelo.usuarios.coordinador.alertaDescartar = $0 }
        )) {
            Button(TextosUsuarios.descartarSi, role: .destructive) {
                modelo.confirmarDescartar()
            }
            Button(TextosUsuarios.descartarNo, role: .cancel) {
                modelo.usuarios.cancelarDescartar()
            }
        } message: {
            Text(TextosUsuarios.descartarCuerpo)
        }
        .alert(TextosUsuarios.guardarFalloTitulo, isPresented: $modelo.usuarios.alertaGuardar) {
            Button(TextosUsuarios.reintentar) {
                modelo.usuarios.guardarActivo()
            }
            Button(TextosUsuarios.cerrar, role: .cancel) {}
        } message: {
            Text(TextosUsuarios.guardarFalloCuerpo)
        }
    }

    @ViewBuilder
    private var sidebar: some View {
        switch modelo.coordinador.seccion {
        case .inicio:
            ListaSeccionesAppVista(modelo: modelo)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 220)
        case .usuarios:
            VStack(spacing: 0) {
                Button {
                    modelo.intentarIrA(.inicio)
                } label: {
                    FilaDestinoShell(
                        titulo: TextosUsuarios.shellInicio,
                        systemImage: "house",
                        activo: false
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, TemaUsuarios.espacio12)
                .padding(.vertical, TemaUsuarios.espacio8)
                .accessibilityIdentifier(IdentificadorAccesibilidad.shellInicio)
                ListaUsuariosVista(modelo: modelo.usuarios)
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        }
    }

    @ViewBuilder
    private var detalle: some View {
        switch modelo.coordinador.seccion {
        case .inicio:
            InicioVista(modelo: modelo)
        case .usuarios:
            DetalleUsuariosColumna(modelo: modelo.usuarios)
        }
    }

    private var sheetAlta: some View {
        VStack(alignment: .leading, spacing: TemaUsuarios.espacio16) {
            HStack(alignment: .center, spacing: TemaUsuarios.espacio12) {
                AvatarUsuarioVista(
                    nombre: modelo.usuarios.borradorAlta.nombre,
                    nombreUsuario: modelo.usuarios.borradorAlta.nombreUsuario,
                    tamano: TemaUsuarios.avatarSheet
                )
                Text(TextosUsuarios.sheetNuevo)
                    .font(TemaUsuarios.tipoTitulo)
                    .accessibilityAddTraits(.isHeader)
            }
            FormularioUsuarioVista(
                borrador: $modelo.usuarios.borradorAlta,
                errores: modelo.usuarios.erroresAlta,
                titulo: TextosUsuarios.sheetNuevo,
                onGuardar: { modelo.usuarios.guardarActivo() },
                onCancelar: { modelo.usuarios.intentarCerrarAlta() },
                campoFoco: $modelo.usuarios.campoFocoAlta,
                onCambioCampo: {
                    if modelo.usuarios.validacionEnVivoAlta {
                        modelo.usuarios.revalidarAlta()
                    }
                }
            )
        }
        .frame(width: TemaUsuarios.anchoSheet)
        .padding(TemaUsuarios.espacio20)
    }
}

struct ListaSeccionesAppVista: View {
    @Bindable var modelo: ShellVistaModelo
    @Environment(\.colorScheme) private var esquema

    var body: some View {
        List(selection: Binding<SeccionApp?>(
            get: { modelo.coordinador.seccion },
            set: { nuevo in
                if let nuevo {
                    modelo.intentarIrA(nuevo)
                }
            }
        )) {
            fila(.inicio)
            fila(.usuarios)
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(TemaUsuarios.shellFondo(esquema: esquema))
        .accessibilityIdentifier(IdentificadorAccesibilidad.shellSidebar)
    }

    private func fila(_ seccion: SeccionApp) -> some View {
        let activo = modelo.coordinador.seccion == seccion
        return FilaDestinoShell(
            titulo: seccion == .inicio ? TextosUsuarios.shellInicio : TextosUsuarios.shellUsuarios,
            systemImage: seccion == .inicio ? "house" : "person.crop.rectangle.stack",
            activo: activo
        )
        .tag(seccion)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(
            top: TemaUsuarios.espacio4,
            leading: TemaUsuarios.espacio8,
            bottom: TemaUsuarios.espacio4,
            trailing: TemaUsuarios.espacio8
        ))
        .accessibilityIdentifier(
            seccion == .inicio
                ? IdentificadorAccesibilidad.shellInicio
                : IdentificadorAccesibilidad.shellUsuarios
        )
    }
}

struct FilaDestinoShell: View {
    let titulo: String
    let systemImage: String
    let activo: Bool

    @Environment(\.colorScheme) private var esquema
    @Environment(\.colorSchemeContrast) private var contraste

    var body: some View {
        HStack(spacing: TemaUsuarios.espacio8) {
            Capsule()
                .fill(activo ? Color.accentColor : Color.clear)
                .frame(
                    width: contraste == .increased
                        ? TemaUsuarios.barraDestinoAnchoIC
                        : TemaUsuarios.barraDestinoAncho,
                    height: TemaUsuarios.barraDestinoAlto
                )
                .accessibilityHidden(true)
            Label(titulo, systemImage: systemImage)
                .font(activo ? TemaUsuarios.tipoTitulo : TemaUsuarios.tipoCuerpo)
                .foregroundStyle(Color.primary)
            Spacer(minLength: 0)
        }
        .padding(TemaUsuarios.espacio8)
        .background {
            RoundedRectangle(cornerRadius: TemaUsuarios.radioBanner, style: .continuous)
                .fill(TemaUsuarios.shellRellenoActivo(esquema: esquema, contraste: contraste).opacity(activo ? 1 : 0))
        }
        .overlay {
            if activo && contraste == .increased {
                RoundedRectangle(cornerRadius: TemaUsuarios.radioBanner, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.45), lineWidth: 1)
            }
        }
    }
}

struct ShellAppFocusedKey: FocusedValueKey {
    typealias Value = ShellVistaModelo
}

extension FocusedValues {
    var shellApp: ShellVistaModelo? {
        get { self[ShellAppFocusedKey.self] }
        set { self[ShellAppFocusedKey.self] = newValue }
    }
}
