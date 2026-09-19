import Foundation

nonisolated struct CerrarSesionCompuesto: CerrarSesionCasoUso {
    private let dominio: any CerrarSesionCasoUso
    private let overlay: any ReiniciableOverlayUsuarios

    init(dominio: any CerrarSesionCasoUso, overlay: any ReiniciableOverlayUsuarios) {
        self.dominio = dominio
        self.overlay = overlay
    }

    func ejecutar() async {
        await dominio.ejecutar()
        await overlay.reiniciar()
    }
}
