import AppKit
import SwiftUI

struct RaizCondicionalVista: View {
    let contenedor: ContenedorApp
    @Binding var sesion: Sesion?

    var body: some View {
        Group {
            if sesion == nil {
                LoginVista(contenedor: contenedor, sesion: $sesion)
            } else {
                RaizAppVista(contenedor: contenedor, sesion: $sesion)
                    .id(identidadSesion)
            }
        }
        .onAppear {
            for ventana in NSApplication.shared.windows {
                ventana.makeKeyAndOrderFront(nil)
            }
        }
    }

    private var identidadSesion: String {
        guard let sesion else { return "login" }
        return "\(sesion.nombreUsuario)-\(sesion.iniciadaEn.timeIntervalSince1970)"
    }
}
