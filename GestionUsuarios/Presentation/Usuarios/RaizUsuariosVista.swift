import SwiftUI

struct DetalleUsuariosColumna: View {
    @Bindable var modelo: UsuariosVistaModelo
    @Environment(\.colorScheme) private var esquema

    var body: some View {
        Group {
            if modelo.coordinador.modoDetalle == .edicion, let usuario = modelo.usuarioSeleccionado {
                VStack(alignment: .leading, spacing: 0) {
                    AvatarUsuarioVista(
                        nombre: usuario.nombre,
                        nombreUsuario: usuario.nombreUsuario,
                        tamano: TemaUsuarios.avatarSheet
                    )
                    .padding(TemaUsuarios.espacio16)
                    FormularioUsuarioVista(
                        borrador: $modelo.borradorEdicion,
                        errores: modelo.erroresEdicion,
                        titulo: TextosUsuarios.tituloEdicion(usuario.nombre),
                        onGuardar: { modelo.guardarActivo() },
                        onCancelar: { modelo.intentarCancelarEdicion() },
                        campoFoco: $modelo.campoFocoEdicion,
                        onCambioCampo: {
                            if modelo.validacionEnVivoEdicion {
                                modelo.revalidarEdicion()
                            }
                        },
                        muestraAcciones: false
                    )
                }
            } else {
                DetalleUsuarioVista(usuario: modelo.usuarioSeleccionado)
            }
        }
        .toolbar {
            if modelo.coordinador.modoDetalle == .lectura, modelo.usuarioSeleccionado != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        modelo.entrarEdicion()
                    } label: {
                        Label(TextosUsuarios.editar, systemImage: "square.and.pencil")
                    }
                    .help(TextosUsuarios.helpEditar)
                    .accessibilityLabel(TextosUsuarios.editar)
                    .accessibilityIdentifier(IdentificadorAccesibilidad.toolbarEditar)
                }
            } else if modelo.coordinador.modoDetalle == .edicion,
                      modelo.usuarioSeleccionado != nil,
                      !modelo.coordinador.mostrandoAlta {
                ToolbarItem(placement: .cancellationAction) {
                    Button(TextosUsuarios.cancelar, role: .cancel) {
                        modelo.intentarCancelarEdicion()
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier(IdentificadorAccesibilidad.formCancelar)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { modelo.guardarActivo() }) {
                        Text(TextosUsuarios.guardar)
                            .foregroundStyle(TemaUsuarios.tintaEtiquetaProminent(esquema: esquema))
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier(IdentificadorAccesibilidad.formGuardar)
                }
            }
        }
    }
}
