import Foundation

nonisolated protocol ListarUsuariosCasoUso: Sendable {
    func ejecutar() async throws -> [Usuario]
}

nonisolated struct ListarUsuariosServicio: ListarUsuariosCasoUso {
    private let repositorio: any UsuarioRepositorio

    init(repositorio: any UsuarioRepositorio) {
        self.repositorio = repositorio
    }

    func ejecutar() async throws -> [Usuario] {
        try await repositorio.listar()
    }
}
