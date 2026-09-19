import Foundation
import Testing
@testable import GestionUsuarios

struct ValidadorUsuarioTests {
    @Test func nombreVacio() {
        let informe = ValidadorUsuario.validar(
            nombre: "  ",
            nombreUsuario: "ada_lovelace",
            correo: "ada@example.com",
            existentes: [],
            excepto: nil
        )
        #expect(informe.errores[.nombre] == ClaveValidacionUsuario.nombreRequerido.rawValue)
    }

    @Test func nombreCorto() {
        let informe = ValidadorUsuario.validar(
            nombre: "A",
            nombreUsuario: "ada_lovelace",
            correo: "ada@example.com",
            existentes: [],
            excepto: nil
        )
        #expect(informe.errores[.nombre] == ClaveValidacionUsuario.nombreLongitud.rawValue)
    }

    @Test func usernameFormato() {
        let informe = ValidadorUsuario.validar(
            nombre: "Ada Lovelace",
            nombreUsuario: "ab",
            correo: "ada@example.com",
            existentes: [],
            excepto: nil
        )
        #expect(informe.errores[.nombreUsuario] == ClaveValidacionUsuario.nombreUsuarioFormato.rawValue)
    }

    @Test func correoFormato() {
        let informe = ValidadorUsuario.validar(
            nombre: "Ada Lovelace",
            nombreUsuario: "ada_lovelace",
            correo: "ada@",
            existentes: [],
            excepto: nil
        )
        #expect(informe.errores[.correo] == ClaveValidacionUsuario.correoFormato.rawValue)
    }

    @Test func unicidadUsernameYCorreo() {
        let informe = ValidadorUsuario.validar(
            nombre: "Otra",
            nombreUsuario: "bret",
            correo: "sincere@april.biz",
            existentes: [FixturesUsuario.leanne],
            excepto: nil
        )
        #expect(informe.errores[.nombreUsuario] == ClaveValidacionUsuario.nombreUsuarioDuplicado.rawValue)
        #expect(informe.errores[.correo] == ClaveValidacionUsuario.correoDuplicado.rawValue)
    }

    @Test func unicidadIgnoraElMismoIDAlEditar() {
        let informe = ValidadorUsuario.validar(
            nombre: "Leanne Graham",
            nombreUsuario: "Bret",
            correo: "Sincere@april.biz",
            existentes: [FixturesUsuario.leanne],
            excepto: UsuarioID(1)
        )
        #expect(informe.esValido)
    }
}

struct CrearUsuarioServicioTests {
    @Test func validacionAntesDeRed() async {
        let repo = RepositorioUsuariosMemoria(usuarios: [FixturesUsuario.leanne])
        let servicio = CrearUsuarioServicio(repositorio: repo)
        let alta = UsuarioNuevo(nombre: " ", nombreUsuario: "ada_lovelace", correo: "ada@example.com")

        await #expect(throws: ErrorUsuario.validacion(ClaveValidacionUsuario.nombreRequerido.rawValue)) {
            _ = try await servicio.ejecutar(alta)
        }
        #expect(repo.llamadasListar == 0)
        #expect(repo.llamadasCrear == 0)
    }

    @Test func usernameInvalido() async {
        let repo = RepositorioUsuariosMemoria()
        let servicio = CrearUsuarioServicio(repositorio: repo)
        let alta = UsuarioNuevo(nombre: "Ada Lovelace", nombreUsuario: "ab", correo: "ada@example.com")

        await #expect(throws: ErrorUsuario.validacion(ClaveValidacionUsuario.nombreUsuarioFormato.rawValue)) {
            _ = try await servicio.ejecutar(alta)
        }
    }

    @Test func duplicadoConsultaLista() async {
        let repo = RepositorioUsuariosMemoria(usuarios: [FixturesUsuario.leanne])
        let servicio = CrearUsuarioServicio(repositorio: repo)
        let alta = UsuarioNuevo(nombre: "Ada Lovelace", nombreUsuario: "Bret", correo: "ada@example.com")

        await #expect(throws: ErrorUsuario.validacion(ClaveValidacionUsuario.nombreUsuarioDuplicado.rawValue)) {
            _ = try await servicio.ejecutar(alta)
        }
        #expect(repo.llamadasListar == 1)
        #expect(repo.llamadasCrear == 0)
    }

    @Test func altaValidaLlamaCrear() async throws {
        let repo = RepositorioUsuariosMemoria(usuarios: [FixturesUsuario.leanne])
        let servicio = CrearUsuarioServicio(repositorio: repo)
        let creado = try await servicio.ejecutar(FixturesUsuario.altaValida)
        #expect(creado.nombre == "Ada Lovelace")
        #expect(repo.llamadasCrear == 1)
    }
}

struct ActualizarUsuarioServicioTests {
    @Test func conservaAgregadoYValida() async throws {
        let original = FixturesUsuario.leanne
        let repo = RepositorioUsuariosMemoria(usuarios: [original])
        let servicio = ActualizarUsuarioServicio(repositorio: repo)
        let cambiado = original.actualizado(
            nombre: "Leanne Nueva",
            nombreUsuario: "Bret",
            correo: "Sincere@april.biz"
        )
        let guardado = try await servicio.ejecutar(cambiado)
        #expect(guardado.nombre == "Leanne Nueva")
        #expect(guardado.direccion.calle == "Kulas Light")
        #expect(guardado.empresa.nombre == "Romaguera-Crona")
    }

    @Test func correoInvalidoNoActualiza() async {
        let repo = RepositorioUsuariosMemoria(usuarios: [FixturesUsuario.leanne])
        let servicio = ActualizarUsuarioServicio(repositorio: repo)
        let cambiado = FixturesUsuario.leanne.actualizado(
            nombre: "Leanne Graham",
            nombreUsuario: "Bret",
            correo: "ada@"
        )
        await #expect(throws: ErrorUsuario.validacion(ClaveValidacionUsuario.correoFormato.rawValue)) {
            _ = try await servicio.ejecutar(cambiado)
        }
    }
}
