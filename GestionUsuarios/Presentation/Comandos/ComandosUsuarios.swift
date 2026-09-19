import SwiftUI

struct ModeloUsuariosFocusedKey: FocusedValueKey {
    typealias Value = UsuariosVistaModelo
}

extension FocusedValues {
    var modeloUsuarios: UsuariosVistaModelo? {
        get { self[ModeloUsuariosFocusedKey.self] }
        set { self[ModeloUsuariosFocusedKey.self] = newValue }
    }
}

struct ComandosUsuarios: Commands {
    @FocusedValue(\.modeloUsuarios) private var modelo
    @FocusedValue(\.shellApp) private var shell

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button(TextosUsuarios.nuevoUsuario) {
                modelo?.abrirAlta()
            }
            .keyboardShortcut("n", modifiers: .command)
            .disabled(!(modelo?.puedeNuevo ?? false) || shell == nil)
        }
        CommandGroup(after: .newItem) {
            Button(TextosUsuarios.guardar) {
                modelo?.guardarActivo()
            }
            .keyboardShortcut("s", modifiers: .command)
            .disabled(!enUsuarios || !(modelo?.puedeGuardar ?? false))
        }
        CommandGroup(after: .pasteboard) {
            Button(TextosUsuarios.actualizarUsuario) {
                modelo?.entrarEdicion()
            }
            .keyboardShortcut("e", modifiers: .command)
            .disabled(!enUsuarios || !(modelo?.puedeEditar ?? false))
        }
        CommandMenu(TextosUsuarios.visualizacion) {
            Button(TextosUsuarios.verDetalle) {
                modelo?.verDetalle()
            }
            .keyboardShortcut("i", modifiers: .command)
            .disabled(!enUsuarios || !(modelo?.puedeVerDetalle ?? false))
            Button(TextosUsuarios.recargar) {
                modelo?.recargar()
            }
            .keyboardShortcut("r", modifiers: .command)
            .disabled(!(modelo?.puedeRecargar ?? false) || shell == nil)
            Button(TextosUsuarios.buscar) {
                modelo?.enfocarBusqueda()
            }
            .keyboardShortcut("f", modifiers: .command)
            .disabled(!enUsuarios)
        }
    }

    private var enUsuarios: Bool {
        shell?.coordinador.seccion == .usuarios
    }
}

struct ComandosSesion: Commands {
    @FocusedValue(\.shellApp) private var shell

    var body: some Commands {
        CommandMenu(TextosUsuarios.menuCuenta) {
            Button(TextosUsuarios.cerrarSesion) {
                shell?.intentarCerrarSesion()
            }
            .disabled(shell == nil)
            .accessibilityIdentifier(IdentificadorAccesibilidad.menuLogout)
        }
    }
}
