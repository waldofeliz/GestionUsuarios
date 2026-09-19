import Foundation
import Testing
@testable import GestionUsuarios

struct UsuarioRepositorioSesionTests {
    @Test func crearApareceAlListarConIdSintetico() async throws {
        let remoto = RepositorioUsuariosMemoria(usuarios: [FixturesUsuario.leanne])
        let sesion = UsuarioRepositorioSesion(remoto: remoto)

        let creado = try await sesion.crear(FixturesUsuario.altaValida)

        #expect(creado.id.valor >= UsuarioRepositorioSesion.idSinteticoMinimo)
        #expect(creado.id != UsuarioID(11))
        #expect(creado.nombre == "Ada Lovelace")

        let lista = try await sesion.listar()
        #expect(lista.contains(where: { $0.id == creado.id }))
        #expect(lista.contains(where: { $0.id == UsuarioID(1) }))
        #expect(remoto.llamadasCrear == 1)
    }

    @Test func noUsaElIdOnceDelPOST() async throws {
        let remoto = RepositorioUsuariosMemoria(usuarios: [])
        remoto.creadoConID = UsuarioID(11)
        let sesion = UsuarioRepositorioSesion(remoto: remoto)

        let primero = try await sesion.crear(FixturesUsuario.altaValida)
        let segundo = try await sesion.crear(
            UsuarioNuevo(nombre: "Grace Hopper", nombreUsuario: "ghopper", correo: "grace@example.com")
        )

        #expect(primero.id.valor == 10_000)
        #expect(segundo.id.valor == 10_001)
        let lista = try await sesion.listar()
        #expect(lista.map(\.id.valor).sorted() == [10_000, 10_001])
        #expect(!lista.contains(where: { $0.id == UsuarioID(11) }))
    }

    @Test func edicionPersisteTrasListar() async throws {
        let remoto = RepositorioUsuariosMemoria(usuarios: [FixturesUsuario.leanne])
        let sesion = UsuarioRepositorioSesion(remoto: remoto)
        let editado = FixturesUsuario.leanne.actualizado(
            nombre: "Leanne Editada",
            nombreUsuario: "Bret",
            correo: "Sincere@april.biz"
        )

        _ = try await sesion.actualizar(editado)
        let lista = try await sesion.listar()
        #expect(lista.first?.nombre == "Leanne Editada")
        #expect(lista.first?.direccion.calle == "Kulas Light")
    }

    @Test func getDeRedNoBorraAltas() async throws {
        let remoto = RepositorioUsuariosMemoria(usuarios: [FixturesUsuario.leanne])
        let sesion = UsuarioRepositorioSesion(remoto: remoto)
        let creado = try await sesion.crear(FixturesUsuario.altaValida)
        remoto.usuarios = [FixturesUsuario.leanne]

        let lista = try await sesion.listar()
        #expect(lista.count == 2)
        #expect(lista.contains(where: { $0.id == creado.id }))
    }
}
