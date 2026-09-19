import Foundation

nonisolated protocol CerrarSesionCasoUso: Sendable {
    func ejecutar() async
}

nonisolated struct CerrarSesionServicio: CerrarSesionCasoUso {
    private let almacen: any AlmacenSesion

    init(almacen: any AlmacenSesion) {
        self.almacen = almacen
    }

    func ejecutar() async {
        await almacen.borrar()
    }
}
