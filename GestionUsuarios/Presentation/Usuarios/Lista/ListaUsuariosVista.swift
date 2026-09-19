import SwiftUI

struct ListaUsuariosVista: View {
    @Bindable var modelo: UsuariosVistaModelo
    @Environment(\.colorScheme) private var esquema
    @Environment(\.colorSchemeContrast) private var contraste

    var body: some View {
        VStack(spacing: 0) {
            if let banner = modelo.bannerRecarga {
                bannerRecarga(banner)
            }
            contenido
        }
        .navigationTitle(TextosUsuarios.sidebar)
        .searchable(
            text: $modelo.consulta,
            isPresented: Binding(
                get: { modelo.coordinador.busquedaPresentada },
                set: { modelo.coordinador.busquedaPresentada = $0 }
            ),
            placement: .sidebar,
            prompt: Text(TextosUsuarios.busqueda)
        )
        .accessibilityIdentifier(IdentificadorAccesibilidad.listaBusqueda)
        .onChange(of: modelo.consulta) { _, _ in
            modelo.consultaCambio()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    modelo.abrirAlta()
                } label: {
                    Label(TextosUsuarios.nuevoUsuario, systemImage: "plus")
                }
                .help(TextosUsuarios.helpNuevo)
                .accessibilityLabel(TextosUsuarios.nuevoUsuario)
                .accessibilityIdentifier(IdentificadorAccesibilidad.toolbarNuevo)
                .disabled(!modelo.puedeNuevo)
            }
            ToolbarItemGroup(placement: .automatic) {
                if modelo.recargando {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityLabel(TextosUsuarios.recargando)
                }
                Button {
                    modelo.recargar()
                } label: {
                    Label(TextosUsuarios.recargar, systemImage: "arrow.clockwise")
                }
                .help(TextosUsuarios.helpRecargar)
                .accessibilityLabel(TextosUsuarios.recargar)
                .accessibilityIdentifier(IdentificadorAccesibilidad.toolbarRecargar)
                .disabled(!modelo.puedeRecargar)
            }
        }
    }

    @ViewBuilder
    private var contenido: some View {
        switch modelo.estado {
        case .cargando where modelo.usuarios.isEmpty:
            ProgressView(TextosUsuarios.cargando)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier(IdentificadorAccesibilidad.estadoCargando)
        case .error(let error) where modelo.usuarios.isEmpty:
            vistaError(error)
        case .listo where modelo.usuarios.isEmpty:
            listaVacia
        default:
            if modelo.usuarios.isEmpty {
                listaVacia
            } else if modelo.usuariosFiltrados.isEmpty {
                busquedaVacia
            } else {
                lista
            }
        }
    }

    private var lista: some View {
        List(selection: modelo.bindingSeleccion) {
            Section {
                ForEach(modelo.usuariosFiltrados) { usuario in
                    HStack(alignment: .center, spacing: TemaUsuarios.espacio10) {
                        AvatarUsuarioVista(
                            nombre: usuario.nombre,
                            nombreUsuario: usuario.nombreUsuario,
                            tamano: TemaUsuarios.avatarLista
                        )
                        VStack(alignment: .leading, spacing: TemaUsuarios.espacio2) {
                            Text(usuario.nombre)
                                .font(TemaUsuarios.tipoFila)
                                .foregroundStyle(Color.primary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Text(TextosUsuarios.secundaria(
                                nombreUsuario: usuario.nombreUsuario,
                                correo: usuario.correo
                            ))
                            .font(TemaUsuarios.tipoFilaSec)
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, TemaUsuarios.espacio4)
                    .tag(usuario.id)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(TextosUsuarios.filaAccesible(
                        nombre: usuario.nombre,
                        nombreUsuario: usuario.nombreUsuario,
                        correo: usuario.correo
                    ))
                    .accessibilityIdentifier(IdentificadorAccesibilidad.filaUsuario(usuario.id))
                }
            } header: {
                Text(TextosUsuarios.sidebar)
                    .font(TemaUsuarios.tipoTitulo)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier(IdentificadorAccesibilidad.listaTitulo)
            } footer: {
                Text(TextosUsuarios.contador(modelo.usuariosFiltrados.count))
                    .font(TemaUsuarios.tipoLabel)
                    .foregroundStyle(Color.secondary)
            }
        }
        .listStyle(.sidebar)
    }

    private var listaVacia: some View {
        ContentUnavailableView {
            EtiquetaWellUsuarios(
                titulo: TextosUsuarios.vacioTitulo,
                systemName: "person.crop.rectangle.stack"
            )
        } description: {
            Text(TextosUsuarios.vacioCuerpo)
                .descripcionEmptyUsuarios()
        } actions: {
            Button(action: { modelo.abrirAlta() }) {
                Text(TextosUsuarios.nuevoUsuario)
                    .foregroundStyle(TemaUsuarios.tintaEtiquetaProminent(esquema: esquema))
            }
            .buttonStyle(.borderedProminent)
            Button(TextosUsuarios.recargar) { modelo.recargar() }
                .buttonStyle(.bordered)
        }
        .accessibilityIdentifier(IdentificadorAccesibilidad.estadoListaVacia)
    }

    private var busquedaVacia: some View {
        ContentUnavailableView {
            EtiquetaWellUsuarios(
                titulo: TextosUsuarios.sinResultadosTitulo,
                systemName: "magnifyingglass"
            )
        } description: {
            Text(TextosUsuarios.sinResultadosCuerpo(modelo.consulta))
                .descripcionEmptyUsuarios()
        } actions: {
            Button(TextosUsuarios.limpiarBusqueda) { modelo.limpiarBusqueda() }
                .buttonStyle(.bordered)
        }
        .accessibilityIdentifier(IdentificadorAccesibilidad.estadoBusquedaVacia)
    }

    private func vistaError(_ error: ErrorUsuario) -> some View {
        ContentUnavailableView {
            EtiquetaWellUsuarios(
                titulo: MensajesErrorLista.titulo(error),
                systemName: "wifi.exclamationmark",
                esError: true
            )
        } description: {
            Text(MensajesErrorLista.cuerpo(error))
                .descripcionEmptyUsuarios()
        } actions: {
            Button(TextosUsuarios.reintentar) { modelo.reintentarCarga() }
                .buttonStyle(.bordered)
                .accessibilityIdentifier(IdentificadorAccesibilidad.estadoErrorReintentar)
        }
    }

    private func bannerRecarga(_ error: ErrorUsuario) -> some View {
        let forma = RoundedRectangle(cornerRadius: TemaUsuarios.radioBanner, style: .continuous)
        return HStack(alignment: .center, spacing: TemaUsuarios.espacio8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: TemaUsuarios.iconoBanner))
                .foregroundStyle(TemaUsuarios.bannerIcono(esquema: esquema, contraste: contraste))
                .accessibilityHidden(true)
            Text(TextosUsuarios.banner)
                .font(TemaUsuarios.tipoCuerpo)
                .foregroundStyle(Color.primary)
            Spacer(minLength: TemaUsuarios.espacio8)
            Button(TextosUsuarios.reintentar) { modelo.reintentarCarga() }
                .buttonStyle(.bordered)
                .accessibilityIdentifier(IdentificadorAccesibilidad.estadoErrorReintentar)
        }
        .padding(.horizontal, TemaUsuarios.espacio12)
        .padding(.vertical, TemaUsuarios.espacio8)
        .background(TemaUsuarios.bannerFondo(esquema: esquema, contraste: contraste), in: forma)
        .overlay {
            forma.strokeBorder(
                TemaUsuarios.bannerTrazo(esquema: esquema, contraste: contraste),
                lineWidth: 1
            )
        }
        .padding(.horizontal, TemaUsuarios.espacio8)
        .padding(.top, TemaUsuarios.espacio8)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(IdentificadorAccesibilidad.estadoErrorBanner)
        .accessibilityLabel("\(TextosUsuarios.banner) \(MensajesErrorLista.titulo(error))")
    }
}
