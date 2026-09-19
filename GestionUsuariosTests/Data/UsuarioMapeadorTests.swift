import Foundation
import Testing
@testable import GestionUsuarios

struct UsuarioMapeadorTests {
    @Test func mapeaDTOCompletoADominio() throws {
        let dto = try JSONDecoder().decode(UsuarioDTO.self, from: FixturesUsuario.jsonUsuarioCompleto)
        let usuario = try UsuarioMapeador.dominio(desde: dto)

        #expect(usuario.id == UsuarioID(1))
        #expect(usuario.nombre == "Leanne Graham")
        #expect(usuario.nombreUsuario == "Bret")
        #expect(usuario.correo == "Sincere@april.biz")
        #expect(usuario.telefono == "1-770-736-8031 x56442")
        #expect(usuario.direccion.calle == "Kulas Light")
        #expect(usuario.direccion.coordenada?.latitud == -37.3159)
        #expect(usuario.empresa.nombre == "Romaguera-Crona")
    }

    @Test func geoNoNumericaNoTumbaAlUsuario() throws {
        let dto = try JSONDecoder().decode(UsuarioDTO.self, from: FixturesUsuario.jsonUsuarioGeoInvalida)
        let usuario = try UsuarioMapeador.dominio(desde: dto)

        #expect(usuario.id == UsuarioID(2))
        #expect(usuario.nombre == "Ervin Howell")
        #expect(usuario.direccion.coordenada == nil)
    }

    @Test func dtoDeAltaNoIncluyeID() {
        let dto = UsuarioMapeador.dto(desde: FixturesUsuario.altaValida)
        #expect(dto.id == nil)
        #expect(dto.name == "Ada Lovelace")
        #expect(dto.username == "ada_lovelace")
        #expect(dto.email == "ada@example.com")
    }

    @Test func dtoDeUsuarioConservaAgregadoParaPUT() {
        let dto = UsuarioMapeador.dto(desde: FixturesUsuario.leanne)
        #expect(dto.id == 1)
        #expect(dto.address?.street == "Kulas Light")
        #expect(dto.company?.name == "Romaguera-Crona")
        #expect(dto.phone == "1-770-736-8031 x56442")
    }
}
