import Foundation

/// Overlay y sesión de login viven en RAM; este actor no persiste el flag.
actor AlmacenSesionMemoria: AlmacenSesion, ProveedorSesionActiva {
    private var sesion: Sesion?

    func actual() async -> Sesion? {
        sesion
    }

    func guardar(_ sesion: Sesion) async {
        self.sesion = sesion
    }

    func borrar() async {
        sesion = nil
    }

    func haySesion() async -> Bool {
        sesion != nil
    }
}
