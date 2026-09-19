import Foundation

nonisolated protocol CrearUsuarioCasoUso: Sendable {
    func ejecutar(_ alta: UsuarioNuevo) async throws -> Usuario
}

nonisolated struct CrearUsuarioServicio: CrearUsuarioCasoUso {
    private let repositorio: any UsuarioRepositorio

    init(repositorio: any UsuarioRepositorio) {
        self.repositorio = repositorio
    }

    func ejecutar(_ alta: UsuarioNuevo) async throws -> Usuario {
        let recortada = ValidadorUsuario.recortar(alta)
        let local = ValidadorUsuario.validar(
            nombre: recortada.nombre,
            nombreUsuario: recortada.nombreUsuario,
            correo: recortada.correo,
            existentes: [],
            excepto: nil
        )
        if let primero = local.primero {
            throw ErrorUsuario.validacion(primero.1)
        }
        let existentes = try await repositorio.listar()
        let completo = ValidadorUsuario.validar(
            nombre: recortada.nombre,
            nombreUsuario: recortada.nombreUsuario,
            correo: recortada.correo,
            existentes: existentes,
            excepto: nil
        )
        if let primero = completo.primero {
            throw ErrorUsuario.validacion(primero.1)
        }
        return try await repositorio.crear(recortada)
    }
}
