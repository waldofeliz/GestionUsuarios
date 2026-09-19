import Foundation

nonisolated enum UsuarioMapeador {
    static func dominio(desde dto: UsuarioDTO) throws -> Usuario {
        guard let idRemoto = dto.id else {
            throw ErrorUsuario.decodificacion
        }
        return Usuario(
            id: UsuarioID(idRemoto),
            nombre: dto.name,
            nombreUsuario: dto.username,
            correo: dto.email,
            telefono: dto.phone ?? "",
            sitioWeb: dto.website ?? "",
            direccion: direccion(desde: dto.address),
            empresa: empresa(desde: dto.company)
        )
    }

    static func dto(desde usuario: Usuario) -> UsuarioDTO {
        UsuarioDTO(
            id: usuario.id.valor,
            name: usuario.nombre,
            username: usuario.nombreUsuario,
            email: usuario.correo,
            address: dto(desde: usuario.direccion),
            phone: usuario.telefono,
            website: usuario.sitioWeb,
            company: dto(desde: usuario.empresa)
        )
    }

    static func dto(desde alta: UsuarioNuevo) -> UsuarioDTO {
        UsuarioDTO(
            id: nil,
            name: alta.nombre,
            username: alta.nombreUsuario,
            email: alta.correo,
            address: dto(desde: alta.direccion),
            phone: alta.telefono,
            website: alta.sitioWeb,
            company: dto(desde: alta.empresa)
        )
    }

    private static func direccion(desde dto: DireccionDTO?) -> Direccion {
        guard let dto else { return .vacia }
        return Direccion(
            calle: dto.street,
            apartamento: dto.suite,
            ciudad: dto.city,
            codigoPostal: dto.zipcode,
            coordenada: coordenada(desde: dto.geo)
        )
    }

    private static func coordenada(desde dto: GeoDTO?) -> Coordenada? {
        guard let dto else { return nil }
        guard let latitud = Double(dto.lat), let longitud = Double(dto.lng) else {
            return nil
        }
        return Coordenada(latitud: latitud, longitud: longitud)
    }

    private static func empresa(desde dto: EmpresaDTO?) -> Empresa {
        guard let dto else { return .vacia }
        return Empresa(nombre: dto.name, eslogan: dto.catchPhrase, rubro: dto.bs)
    }

    private static func dto(desde direccion: Direccion) -> DireccionDTO {
        DireccionDTO(
            street: direccion.calle,
            suite: direccion.apartamento,
            city: direccion.ciudad,
            zipcode: direccion.codigoPostal,
            geo: direccion.coordenada.map {
                GeoDTO(lat: String($0.latitud), lng: String($0.longitud))
            }
        )
    }

    private static func dto(desde empresa: Empresa) -> EmpresaDTO {
        EmpresaDTO(name: empresa.nombre, catchPhrase: empresa.eslogan, bs: empresa.rubro)
    }
}
