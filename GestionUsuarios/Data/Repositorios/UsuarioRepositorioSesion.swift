import Foundation

/// Overlay de sesión: JSONPlaceholder no persiste POST/PUT.
/// Las altas usan ids sintéticos ≥ 10_000; el `id` 11 típico del POST no se usa como clave.
actor UsuarioRepositorioSesion: UsuarioRepositorio, ReiniciableOverlayUsuarios {
    static let idSinteticoMinimo = 10_000

    private let remoto: any UsuarioRepositorio
    private var altas: [UsuarioID: Usuario] = [:]
    private var ediciones: [UsuarioID: Usuario] = [:]
    private var siguienteID = UsuarioRepositorioSesion.idSinteticoMinimo

    init(remoto: any UsuarioRepositorio) {
        self.remoto = remoto
    }

    func listar() async throws -> [Usuario] {
        let remotos = try await remoto.listar()
        return fusionar(remotos: remotos)
    }

    func obtener(id: UsuarioID) async throws -> Usuario {
        if let local = overlay(id: id) {
            return local
        }
        if id.valor >= Self.idSinteticoMinimo {
            throw ErrorUsuario.noEncontrado(id)
        }
        let remotoObtenido = try await remoto.obtener(id: id)
        return ediciones[id] ?? remotoObtenido
    }

    func crear(_ alta: UsuarioNuevo) async throws -> Usuario {
        _ = try await remoto.crear(alta)
        let id = UsuarioID(siguienteID)
        siguienteID += 1
        let usuario = Usuario(id: id, alta: alta)
        altas[id] = usuario
        return usuario
    }

    func actualizar(_ usuario: Usuario) async throws -> Usuario {
        if usuario.id.valor < Self.idSinteticoMinimo {
            _ = try await remoto.actualizar(usuario)
        }
        ediciones[usuario.id] = usuario
        if altas[usuario.id] != nil {
            altas[usuario.id] = usuario
        }
        return usuario
    }

    func reiniciar() async {
        altas = [:]
        ediciones = [:]
        siguienteID = Self.idSinteticoMinimo
    }

    private func overlay(id: UsuarioID) -> Usuario? {
        if let editado = ediciones[id] {
            return editado
        }
        return altas[id]
    }

    private func fusionar(remotos: [Usuario]) -> [Usuario] {
        var porID: [UsuarioID: Usuario] = [:]
        for usuario in remotos {
            porID[usuario.id] = ediciones[usuario.id] ?? usuario
        }
        for (id, alta) in altas {
            porID[id] = ediciones[id] ?? alta
        }
        return porID.values.sorted { $0.id.valor < $1.id.valor }
    }
}
