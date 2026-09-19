import Foundation

nonisolated protocol FuenteUsuariosRemota: Sendable {
    func listarRemotos() async throws -> [UsuarioDTO]
    func obtenerRemoto(id: UsuarioID) async throws -> UsuarioDTO
    func crearRemoto(_ cuerpo: UsuarioDTO) async throws -> UsuarioDTO
    func actualizarRemoto(id: UsuarioID, cuerpo: UsuarioDTO) async throws -> UsuarioDTO
}

nonisolated struct APIUsuariosJSONPlaceholder: FuenteUsuariosRemota {
    private let cliente: any ClienteHTTP
    private let codificador: JSONEncoder
    private let decodificador: JSONDecoder

    init(cliente: any ClienteHTTP) {
        self.cliente = cliente
        self.codificador = JSONEncoder()
        self.decodificador = JSONDecoder()
    }

    func listarRemotos() async throws -> [UsuarioDTO] {
        let respuesta = try await cliente.enviar(
            SolicitudHTTP(metodo: .get, url: EndpointsJSONPlaceholder.users, cuerpo: nil)
        )
        try validar(respuesta, id: nil)
        return try decodificar([UsuarioDTO].self, desde: respuesta.cuerpo)
    }

    func obtenerRemoto(id: UsuarioID) async throws -> UsuarioDTO {
        let respuesta = try await cliente.enviar(
            SolicitudHTTP(metodo: .get, url: EndpointsJSONPlaceholder.user(id: id), cuerpo: nil)
        )
        try validar(respuesta, id: id)
        return try decodificar(UsuarioDTO.self, desde: respuesta.cuerpo)
    }

    func crearRemoto(_ cuerpo: UsuarioDTO) async throws -> UsuarioDTO {
        let datos = try encodificar(cuerpo)
        let respuesta = try await cliente.enviar(
            SolicitudHTTP(metodo: .post, url: EndpointsJSONPlaceholder.users, cuerpo: datos)
        )
        try validar(respuesta, id: nil)
        return try decodificar(UsuarioDTO.self, desde: respuesta.cuerpo)
    }

    func actualizarRemoto(id: UsuarioID, cuerpo: UsuarioDTO) async throws -> UsuarioDTO {
        let datos = try encodificar(cuerpo)
        let respuesta = try await cliente.enviar(
            SolicitudHTTP(metodo: .put, url: EndpointsJSONPlaceholder.user(id: id), cuerpo: datos)
        )
        try validar(respuesta, id: id)
        return try decodificar(UsuarioDTO.self, desde: respuesta.cuerpo)
    }

    private func validar(_ respuesta: RespuestaHTTP, id: UsuarioID?) throws {
        if respuesta.codigo == 404 {
            throw ErrorUsuario.noEncontrado(id ?? UsuarioID(0))
        }
        if !respuesta.esExitosa {
            throw ErrorUsuario.http(codigo: respuesta.codigo)
        }
        if respuesta.cuerpo.isEmpty {
            throw ErrorUsuario.decodificacion
        }
    }

    private func encodificar(_ dto: UsuarioDTO) throws -> Data {
        do {
            return try codificador.encode(dto)
        } catch {
            throw ErrorUsuario.decodificacion
        }
    }

    private func decodificar<T: Decodable>(_ tipo: T.Type, desde datos: Data) throws -> T {
        do {
            return try decodificador.decode(tipo, from: datos)
        } catch {
            throw ErrorUsuario.decodificacion
        }
    }
}
