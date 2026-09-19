import Foundation
@testable import GestionUsuarios

nonisolated enum FixturesUsuario {
    static let leanne = Usuario(
        id: UsuarioID(1),
        nombre: "Leanne Graham",
        nombreUsuario: "Bret",
        correo: "Sincere@april.biz",
        telefono: "1-770-736-8031 x56442",
        sitioWeb: "hildegard.org",
        direccion: Direccion(
            calle: "Kulas Light",
            apartamento: "Apt. 556",
            ciudad: "Gwenborough",
            codigoPostal: "92998-3874",
            coordenada: Coordenada(latitud: -37.3159, longitud: 81.1496)
        ),
        empresa: Empresa(
            nombre: "Romaguera-Crona",
            eslogan: "Multi-layered client-server neural-net",
            rubro: "harness real-time e-markets"
        )
    )

    static let altaValida = UsuarioNuevo(
        nombre: "Ada Lovelace",
        nombreUsuario: "ada_lovelace",
        correo: "ada@example.com"
    )

    static let jsonUsuarioCompleto = """
    {
      "id": 1,
      "name": "Leanne Graham",
      "username": "Bret",
      "email": "Sincere@april.biz",
      "address": {
        "street": "Kulas Light",
        "suite": "Apt. 556",
        "city": "Gwenborough",
        "zipcode": "92998-3874",
        "geo": { "lat": "-37.3159", "lng": "81.1496" }
      },
      "phone": "1-770-736-8031 x56442",
      "website": "hildegard.org",
      "company": {
        "name": "Romaguera-Crona",
        "catchPhrase": "Multi-layered client-server neural-net",
        "bs": "harness real-time e-markets"
      }
    }
    """.data(using: .utf8)!

    static let jsonUsuarioGeoInvalida = """
    {
      "id": 2,
      "name": "Ervin Howell",
      "username": "Antonette",
      "email": "Shanna@melissa.tv",
      "address": {
        "street": "Victor Plains",
        "suite": "Suite 879",
        "city": "Wisokyburgh",
        "zipcode": "90566-7771",
        "geo": { "lat": "no-num", "lng": "abc" }
      },
      "phone": "010-692-6593 x09125",
      "website": "anastasia.net",
      "company": {
        "name": "Deckow-Crist",
        "catchPhrase": "Proactive didactic contingency",
        "bs": "synergize scalable supply-chains"
      }
    }
    """.data(using: .utf8)!
}

nonisolated final class RepositorioUsuariosMemoria: UsuarioRepositorio, @unchecked Sendable {
    var usuarios: [Usuario]
    var creadoConID = UsuarioID(11)
    var llamadasCrear = 0
    var llamadasListar = 0

    init(usuarios: [Usuario] = []) {
        self.usuarios = usuarios
    }

    func listar() async throws -> [Usuario] {
        llamadasListar += 1
        return usuarios
    }

    func obtener(id: UsuarioID) async throws -> Usuario {
        guard let usuario = usuarios.first(where: { $0.id == id }) else {
            throw ErrorUsuario.noEncontrado(id)
        }
        return usuario
    }

    func crear(_ alta: UsuarioNuevo) async throws -> Usuario {
        llamadasCrear += 1
        return Usuario(id: creadoConID, alta: alta)
    }

    func actualizar(_ usuario: Usuario) async throws -> Usuario {
        if let indice = usuarios.firstIndex(where: { $0.id == usuario.id }) {
            usuarios[indice] = usuario
        } else {
            usuarios.append(usuario)
        }
        return usuario
    }
}

nonisolated struct ClienteHTTPStub: ClienteHTTP {
    var manejador: @Sendable (SolicitudHTTP) async throws -> RespuestaHTTP

    func enviar(_ solicitud: SolicitudHTTP) async throws -> RespuestaHTTP {
        try await manejador(solicitud)
    }
}
