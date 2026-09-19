import Foundation

nonisolated struct UsuarioID: Hashable, Sendable, Equatable, Codable {
    let valor: Int

    init(_ valor: Int) {
        self.valor = valor
    }
}

nonisolated struct UsuarioNuevo: Sendable, Equatable {
    var nombre: String
    var nombreUsuario: String
    var correo: String
    var telefono: String
    var sitioWeb: String
    var direccion: Direccion
    var empresa: Empresa

    init(
        nombre: String,
        nombreUsuario: String,
        correo: String,
        telefono: String = "",
        sitioWeb: String = "",
        direccion: Direccion = .vacia,
        empresa: Empresa = .vacia
    ) {
        self.nombre = nombre
        self.nombreUsuario = nombreUsuario
        self.correo = correo
        self.telefono = telefono
        self.sitioWeb = sitioWeb
        self.direccion = direccion
        self.empresa = empresa
    }
}

nonisolated struct Usuario: Identifiable, Sendable, Equatable, Hashable {
    let id: UsuarioID
    var nombre: String
    var nombreUsuario: String
    var correo: String
    var telefono: String
    var sitioWeb: String
    var direccion: Direccion
    var empresa: Empresa

    init(
        id: UsuarioID,
        nombre: String,
        nombreUsuario: String,
        correo: String,
        telefono: String = "",
        sitioWeb: String = "",
        direccion: Direccion = .vacia,
        empresa: Empresa = .vacia
    ) {
        self.id = id
        self.nombre = nombre
        self.nombreUsuario = nombreUsuario
        self.correo = correo
        self.telefono = telefono
        self.sitioWeb = sitioWeb
        self.direccion = direccion
        self.empresa = empresa
    }

    init(id: UsuarioID, alta: UsuarioNuevo) {
        self.init(
            id: id,
            nombre: alta.nombre,
            nombreUsuario: alta.nombreUsuario,
            correo: alta.correo,
            telefono: alta.telefono,
            sitioWeb: alta.sitioWeb,
            direccion: alta.direccion,
            empresa: alta.empresa
        )
    }

    func actualizado(nombre: String, nombreUsuario: String, correo: String) -> Usuario {
        var copia = self
        copia.nombre = nombre
        copia.nombreUsuario = nombreUsuario
        copia.correo = correo
        return copia
    }
}
