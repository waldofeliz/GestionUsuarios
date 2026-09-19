import Foundation

nonisolated protocol ActualizarUsuarioCasoUso: Sendable {
    func ejecutar(_ usuario: Usuario) async throws -> Usuario
}

nonisolated struct ActualizarUsuarioServicio: ActualizarUsuarioCasoUso {
    private let repositorio: any UsuarioRepositorio

    init(repositorio: any UsuarioRepositorio) {
        self.repositorio = repositorio
    }

    func ejecutar(_ usuario: Usuario) async throws -> Usuario {
        let recortado = ValidadorUsuario.recortar(usuario)
        let local = ValidadorUsuario.validar(
            nombre: recortado.nombre,
            nombreUsuario: recortado.nombreUsuario,
            correo: recortado.correo,
            existentes: [],
            excepto: recortado.id
        )
        if let primero = local.primero {
            throw ErrorUsuario.validacion(primero.1)
        }
        let existentes = try await repositorio.listar()
        let completo = ValidadorUsuario.validar(
            nombre: recortado.nombre,
            nombreUsuario: recortado.nombreUsuario,
            correo: recortado.correo,
            existentes: existentes,
            excepto: recortado.id
        )
        if let primero = completo.primero {
            throw ErrorUsuario.validacion(primero.1)
        }
        return try await repositorio.actualizar(recortado)
    }
}
