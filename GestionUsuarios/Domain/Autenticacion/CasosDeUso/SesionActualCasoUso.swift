import Foundation

nonisolated protocol SesionActualCasoUso: Sendable {
    func ejecutar() async -> Sesion?
}

nonisolated struct SesionActualServicio: SesionActualCasoUso {
    private let almacen: any AlmacenSesion

    init(almacen: any AlmacenSesion) {
        self.almacen = almacen
    }

    func ejecutar() async -> Sesion? {
        await almacen.actual()
    }
}
