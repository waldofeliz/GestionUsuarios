import Foundation

nonisolated enum RutaUsuarios: Hashable, Sendable {
    case lista
    case detalle(UsuarioID)
    case alta
    case edicion(UsuarioID)
}

enum ModoDetalle: Equatable {
    case lectura
    case edicion
}

enum SeccionApp: Hashable {
    case inicio
    case usuarios
}

enum PendienteNavegacion: Equatable {
    case ninguna
    case seleccionar(UsuarioID?)
    case verDetalle
    case recargar
    case cancelarEdicion
    case cerrarAlta
    case cerrarSesion
    case cambiarSeccion(SeccionApp)
}
