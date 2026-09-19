import Foundation

nonisolated enum EndpointsJSONPlaceholder: Sendable {
    static let base = URL(string: "https://jsonplaceholder.typicode.com")!

    static var users: URL {
        base.appending(path: "users")
    }

    static func user(id: UsuarioID) -> URL {
        users.appending(path: String(id.valor))
    }
}
