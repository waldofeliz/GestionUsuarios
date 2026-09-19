import Foundation

nonisolated struct UsuarioRepositorioRemoto: UsuarioRepositorio {
    private let fuente: any FuenteUsuariosRemota

    init(fuente: any FuenteUsuariosRemota) {
        self.fuente = fuente
    }

    func listar() async throws -> [Usuario] {
        let dtos = try await fuente.listarRemotos()
        return try dtos.map { try UsuarioMapeador.dominio(desde: $0) }
    }

    func obtener(id: UsuarioID) async throws -> Usuario {
        let dto = try await fuente.obtenerRemoto(id: id)
        return try UsuarioMapeador.dominio(desde: dto)
    }

    func crear(_ alta: UsuarioNuevo) async throws -> Usuario {
        let dto = try await fuente.crearRemoto(UsuarioMapeador.dto(desde: alta))
        return try UsuarioMapeador.dominio(desde: dto)
    }

    func actualizar(_ usuario: Usuario) async throws -> Usuario {
        let dto = try await fuente.actualizarRemoto(
            id: usuario.id,
            cuerpo: UsuarioMapeador.dto(desde: usuario)
        )
        return try UsuarioMapeador.dominio(desde: dto)
    }
}
