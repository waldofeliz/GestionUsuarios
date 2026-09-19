import SwiftUI

@Observable
final class CoordinadorUsuarios {
    var seleccion: UsuarioID?
    var modoDetalle: ModoDetalle = .lectura
    var mostrandoAlta = false
    var visibilidadColumnas: NavigationSplitViewVisibility = .all
    var busquedaPresentada = false
    var alertaDescartar = false
    var pendiente: PendienteNavegacion = .ninguna
    var focoDetalle = false

    var ruta: RutaUsuarios {
        if mostrandoAlta { return .alta }
        guard let seleccion else { return .lista }
        return modoDetalle == .edicion ? .edicion(seleccion) : .detalle(seleccion)
    }

    var hayDialogoBloqueante: Bool {
        mostrandoAlta || alertaDescartar
    }
}
