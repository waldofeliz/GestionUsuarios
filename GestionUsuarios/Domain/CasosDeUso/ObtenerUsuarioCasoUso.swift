import Foundation

nonisolated protocol ObtenerUsuarioCasoUso: Sendable {
    func ejecutar(id: UsuarioID) async throws -> Usuario
}

nonisolated struct ObtenerUsuarioServicio: ObtenerUsuarioCasoUso {
    private let repositorio: any UsuarioRepositorio

    init(repositorio: any UsuarioRepositorio) {
        self.repositorio = repositorio
    }

    func ejecutar(id: UsuarioID) async throws -> Usuario {
        try await repositorio.obtener(id: id)
    }
}
