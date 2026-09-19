import Foundation
import SwiftUI

@Observable
@MainActor
final class ShellVistaModelo {
    var usuarios: UsuariosVistaModelo
    let coordinador = CoordinadorApp()
    private let contenedor: ContenedorApp
    var cierreSolicitado = false

    init(contenedor: ContenedorApp) {
        self.contenedor = contenedor
        self.usuarios = UsuariosVistaModelo(contenedor: contenedor)
        self.usuarios.alCrearUsuario = { [weak self] in
            self?.coordinador.seccion = .usuarios
        }
    }

    var sesionActiva: Bool {
        contenedor.sesion != nil
    }

    var nombreSesion: String {
        contenedor.sesion?.nombreUsuario ?? ""
    }

    var tituloVentana: String {
        switch coordinador.seccion {
        case .inicio:
            return TextosUsuarios.tituloVentanaInicio
        case .usuarios:
            return usuarios.tituloVentana
        }
    }

    var resumen: ResumenDashboard {
        contenedor.resumenUsuarios.ejecutar(usuarios.usuarios)
    }

    var altasDeSesion: Int {
        usuarios.usuarios.reduce(0) { parcial, usuario in
            parcial + (usuario.id.valor >= UmbralOverlayUsuarios.idSintetico ? 1 : 0)
        }
    }

    var enUsuarios: Bool {
        coordinador.seccion == .usuarios
    }

    func intentarIrA(_ seccion: SeccionApp) {
        guard seccion != coordinador.seccion else { return }
        if usuarios.hayCambiosEdicion || usuarios.hayCambiosAlta {
            usuarios.coordinador.pendiente = .cambiarSeccion(seccion)
            usuarios.coordinador.alertaDescartar = true
            return
        }
        coordinador.seccion = seccion
    }

    func irAUsuarios() {
        intentarIrA(.usuarios)
    }

    func abrirAltaDesdeInicio() {
        usuarios.abrirAlta()
    }

    func intentarCerrarSesion() {
        if usuarios.hayCambiosEdicion || usuarios.hayCambiosAlta {
            usuarios.coordinador.pendiente = .cerrarSesion
            usuarios.coordinador.alertaDescartar = true
            return
        }
        Task { await ejecutarCerrarSesion() }
    }

    func confirmarDescartar() {
        let pendiente = usuarios.coordinador.pendiente
        switch pendiente {
        case .cerrarSesion:
            usuarios.descartarEstadoLocal()
            Task { await ejecutarCerrarSesion() }
        case .cambiarSeccion(let seccion):
            usuarios.descartarEstadoLocal()
            coordinador.seccion = seccion
        default:
            usuarios.confirmarDescartar()
        }
    }

    func alCrearUsuario() {
        coordinador.seccion = .usuarios
    }

    private func ejecutarCerrarSesion() async {
        await contenedor.cerrarSesion.ejecutar()
        await contenedor.refrescarSesion()
        cierreSolicitado = true
    }
}
