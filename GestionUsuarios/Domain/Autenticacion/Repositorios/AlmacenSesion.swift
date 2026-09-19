import Foundation

nonisolated protocol AlmacenSesion: Sendable {
    func actual() async -> Sesion?
    func guardar(_ sesion: Sesion) async
    func borrar() async
}

nonisolated protocol ProveedorSesionActiva: Sendable {
    func haySesion() async -> Bool
}
