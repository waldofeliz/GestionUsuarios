import Foundation
import Testing
@testable import GestionUsuarios

struct MapeadorErrorRedTests {
    @Test func sinConexion() {
        #expect(
            MapeadorErrorRed.mapear(URLError(.notConnectedToInternet)) == .red(.sinConexion)
        )
        #expect(MapeadorErrorRed.mapear(URLError(.cannotFindHost)) == .red(.sinConexion))
        #expect(MapeadorErrorRed.mapear(URLError(.dnsLookupFailed)) == .red(.sinConexion))
    }

    @Test func tiempoAgotado() {
        #expect(MapeadorErrorRed.mapear(URLError(.timedOut)) == .red(.tiempoAgotado))
    }

    @Test func cancelado() {
        #expect(MapeadorErrorRed.mapear(CancellationError()) == .red(.cancelado))
        #expect(MapeadorErrorRed.mapear(URLError(.cancelled)) == .red(.cancelado))
    }

    @Test func inesperadoSiNoEsURLError() {
        struct ErrorLocal: Error {}
        #expect(MapeadorErrorRed.mapear(ErrorLocal()) == .inesperado)
    }

    @Test func propagaErrorUsuario() {
        #expect(MapeadorErrorRed.mapear(ErrorUsuario.decodificacion) == .decodificacion)
    }
}

struct APIUsuariosJSONPlaceholderTests {
    @Test func listarDecodificaUsuarios() async throws {
        let cliente = ClienteHTTPStub { _ in
            let lista = "[" + String(data: FixturesUsuario.jsonUsuarioCompleto, encoding: .utf8)! + "]"
            return RespuestaHTTP(codigo: 200, cuerpo: Data(lista.utf8))
        }
        let api = APIUsuariosJSONPlaceholder(cliente: cliente)
        let dtos = try await api.listarRemotos()
        #expect(dtos.count == 1)
        #expect(dtos.first?.username == "Bret")
    }

    @Test func http404SeMapeaANoEncontrado() async {
        let cliente = ClienteHTTPStub { _ in
            RespuestaHTTP(codigo: 404, cuerpo: Data("{}".utf8))
        }
        let api = APIUsuariosJSONPlaceholder(cliente: cliente)
        await #expect(throws: ErrorUsuario.noEncontrado(UsuarioID(1))) {
            _ = try await api.obtenerRemoto(id: UsuarioID(1))
        }
    }

    @Test func http500SeMapeaAHttp() async {
        let cliente = ClienteHTTPStub { _ in
            RespuestaHTTP(codigo: 500, cuerpo: Data("error".utf8))
        }
        let api = APIUsuariosJSONPlaceholder(cliente: cliente)
        await #expect(throws: ErrorUsuario.http(codigo: 500)) {
            _ = try await api.listarRemotos()
        }
    }

    @Test func cuerpoInvalidoEsDecodificacion() async {
        let cliente = ClienteHTTPStub { _ in
            RespuestaHTTP(codigo: 200, cuerpo: Data("no-json".utf8))
        }
        let api = APIUsuariosJSONPlaceholder(cliente: cliente)
        await #expect(throws: ErrorUsuario.decodificacion) {
            _ = try await api.listarRemotos()
        }
    }
}
