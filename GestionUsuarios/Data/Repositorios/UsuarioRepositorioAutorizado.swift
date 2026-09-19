import Foundation

nonisolated struct UsuarioRepositorioAutorizado: UsuarioRepositorio {
    private let base: any UsuarioRepositorio
    private let proveedor: any ProveedorSesionActiva

    init(base: any UsuarioRepositorio, proveedor: any ProveedorSesionActiva) {
        self.base = base
        self.proveedor = proveedor
    }

    func listar() async throws -> [Usuario] {
        try await exigirSesion()
        return try await base.listar()
    }

    func obtener(id: UsuarioID) async throws -> Usuario {
        try await exigirSesion()
        return try await base.obtener(id: id)
    }

    func crear(_ alta: UsuarioNuevo) async throws -> Usuario {
        try await exigirSesion()
        return try await base.crear(alta)
    }

    func actualizar(_ usuario: Usuario) async throws -> Usuario {
        try await exigirSesion()
        return try await base.actualizar(usuario)
    }

    private func exigirSesion() async throws {
        guard await proveedor.haySesion() else {
            throw ErrorAutenticacion.sesionRequerida
        }
    }
}
