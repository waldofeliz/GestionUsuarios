import Foundation

nonisolated enum ErrorUsuario: Error, Sendable, Equatable {
    enum Red: Sendable, Equatable {
        case sinConexion
        case tiempoAgotado
        case cancelado
    }

    case red(Red)
    case decodificacion
    case noEncontrado(UsuarioID)
    case validacion(String)
    case http(codigo: Int)
    case inesperado
}

nonisolated enum ClaveValidacionUsuario: String, Sendable {
    case nombreRequerido = "nombre.requerido"
    case nombreLongitud = "nombre.longitud"
    case nombreUsuarioRequerido = "username.requerido"
    case nombreUsuarioFormato = "username.formato"
    case nombreUsuarioDuplicado = "username.duplicado"
    case correoRequerido = "correo.requerido"
    case correoFormato = "correo.formato"
    case correoDuplicado = "correo.duplicado"
}

nonisolated enum CampoUsuario: String, Sendable, CaseIterable, Hashable {
    case nombre
    case nombreUsuario
    case correo
}
