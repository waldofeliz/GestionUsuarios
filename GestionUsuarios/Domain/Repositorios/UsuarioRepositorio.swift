import Foundation

nonisolated protocol UsuarioRepositorio: Sendable {
    func listar() async throws -> [Usuario]
    func obtener(id: UsuarioID) async throws -> Usuario
    func crear(_ alta: UsuarioNuevo) async throws -> Usuario
    func actualizar(_ usuario: Usuario) async throws -> Usuario
}
