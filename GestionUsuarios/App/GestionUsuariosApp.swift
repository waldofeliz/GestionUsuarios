import SwiftUI

@main
struct GestionUsuariosApp: App {
    @State private var contenedor = ContenedorApp()
    @State private var sesion: Sesion?

    var body: some Scene {
        WindowGroup {
            RaizCondicionalVista(contenedor: contenedor, sesion: $sesion)
                .environment(\.contenedorDependencias, contenedor)
                .frame(minWidth: sesion == nil ? 760 : 880, minHeight: sesion == nil ? 480 : 520)
        }
        .defaultSize(width: 1040, height: 680)
        .windowResizability(.contentMinSize)
        .commands {
            ComandosUsuarios()
            ComandosSesion()
            SidebarCommands()
        }
    }
}
