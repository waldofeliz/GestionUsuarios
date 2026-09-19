import Foundation
import SwiftUI

enum CampoLogin: Hashable {
    case usuario
    case clave
}

@Observable
@MainActor
final class LoginVistaModelo {
    var nombreUsuario = ""
    var clave = ""
    var errorUsuario: String?
    var errorClave: String?
    var errorCredenciales: String?
    var validacionEnVivo = false
    var enviando = false
    var foco: CampoLogin = .usuario
    var bloqueoHasta: Date?
    var sesionObtenida: Sesion?

    private let contenedor: ContenedorApp

    init(contenedor: ContenedorApp) {
        self.contenedor = contenedor
    }

    func segundosBloqueo(ahora: Date = .now) -> Int? {
        guard let hasta = bloqueoHasta else { return nil }
        let resto = hasta.timeIntervalSince(ahora)
        guard resto > 0 else { return nil }
        return Int(ceil(resto))
    }

    var estaBloqueado: Bool {
        segundosBloqueo() != nil
    }

    func enviar() async {
        errorCredenciales = nil
        validacionEnVivo = true
        revalidarCampos()

        if errorUsuario != nil {
            foco = .usuario
            anunciar(TextosUsuarios.valLoginUsuario)
            return
        }
        if errorClave != nil {
            foco = .clave
            anunciar(TextosUsuarios.valLoginClave)
            return
        }

        if let restantes = segundosBloqueo() {
            foco = .clave
            anunciar(TextosUsuarios.loginLockout(restantes))
            return
        }

        enviando = true
        defer { enviando = false }

        do {
            _ = try await contenedor.iniciarSesion.ejecutar(
                CredencialesInicio(nombreUsuario: nombreUsuario, clave: clave)
            )
            clave = ""
            await contenedor.refrescarSesion()
            sesionObtenida = contenedor.sesion
            anunciar(TextosUsuarios.loginOk)
        } catch let error as ErrorAutenticacion {
            clave = ""
            switch error {
            case .cuentaBloqueada(let segundos):
                bloqueoHasta = Date.now.addingTimeInterval(TimeInterval(segundos))
                foco = .clave
                anunciar(TextosUsuarios.loginLockout(segundos))
            case .credencialesInvalidas, .sesionYaIniciada, .sesionRequerida:
                errorCredenciales = TextosUsuarios.loginError
                foco = .clave
                anunciar(TextosUsuarios.loginError)
            }
        } catch {
            clave = ""
            errorCredenciales = TextosUsuarios.loginError
            foco = .clave
            anunciar(TextosUsuarios.loginError)
        }
    }

    func campoCambio() {
        guard validacionEnVivo else { return }
        revalidarCampos()
    }

    private func revalidarCampos() {
        let usuarioVacio = nombreUsuario.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        errorUsuario = usuarioVacio ? TextosUsuarios.valLoginUsuario : nil
        errorClave = clave.isEmpty ? TextosUsuarios.valLoginClave : nil
    }

    private func anunciar(_ mensaje: String) {
        AccessibilityNotification.Announcement(mensaje).post()
    }
}
