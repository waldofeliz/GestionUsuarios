import SwiftUI

struct AvatarUsuarioVista: View {
    let nombre: String
    let nombreUsuario: String
    let tamano: CGFloat

    var body: some View {
        let letras = Self.iniciales(de: nombre)
        Text(letras)
            .font(TemaUsuarios.fuenteAvatar(tamano: tamano))
            .tracking(TemaUsuarios.trackingAvatar(tamano: tamano, letras: letras.count))
            .foregroundStyle(TemaUsuarios.inicialesAvatar)
            .minimumScaleFactor(tamano <= TemaUsuarios.avatarLista ? 0.8 : 1)
            .lineLimit(1)
            .frame(width: tamano, height: tamano)
            .background(TemaUsuarios.colorAvatar(nombreUsuario: nombreUsuario), in: Circle())
            .accessibilityHidden(true)
    }

    static func iniciales(de nombre: String) -> String {
        let palabras = nombre.split { $0.isWhitespace }.map(String.init)
        switch palabras.count {
        case 0:
            return "?"
        case 1:
            return String(palabras[0].prefix(1)).uppercased()
        default:
            let primera = String(palabras[0].prefix(1))
            let ultima = String(palabras[palabras.count - 1].prefix(1))
            return (primera + ultima).uppercased()
        }
    }
}
