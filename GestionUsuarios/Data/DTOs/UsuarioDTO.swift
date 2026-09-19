import Foundation

nonisolated struct GeoDTO: Codable, Sendable {
    var lat: String
    var lng: String
}

nonisolated struct DireccionDTO: Codable, Sendable {
    var street: String
    var suite: String
    var city: String
    var zipcode: String
    var geo: GeoDTO?
}

nonisolated struct EmpresaDTO: Codable, Sendable {
    var name: String
    var catchPhrase: String
    var bs: String
}

nonisolated struct UsuarioDTO: Codable, Sendable {
    var id: Int?
    var name: String
    var username: String
    var email: String
    var address: DireccionDTO?
    var phone: String?
    var website: String?
    var company: EmpresaDTO?
}
