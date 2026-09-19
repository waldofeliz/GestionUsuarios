import SwiftUI

enum TemaUsuarios {
    static let espacio2: CGFloat = 2
    static let espacio4: CGFloat = 4
    static let espacio6: CGFloat = 6
    static let espacio8: CGFloat = 8
    static let espacio10: CGFloat = 10
    static let espacio12: CGFloat = 12
    static let espacio16: CGFloat = 16
    static let espacio20: CGFloat = 20
    static let espacio24: CGFloat = 24
    static let espacio32: CGFloat = 32

    static let radioTarjeta: CGFloat = 10
    static let radioBanner: CGFloat = 8
    static let radioBadge: CGFloat = 4
    static let wellEmpty: CGFloat = 72

    static let avatarLista: CGFloat = 28
    static let avatarSheet: CGFloat = 36
    static let avatarDetalle: CGFloat = 80
    static let iconoTarjeta: CGFloat = 14
    static let iconoBanner: CGFloat = 16
    static let iconoWell: CGFloat = 32
    static let maxAnchoFicha: CGFloat = 560
    static let maxAnchoInicio: CGFloat = 960
    static let maxAnchoEmpty: CGFloat = 280
    static let anchoSheet: CGFloat = 420
    static let insetSeparadorTarjeta: CGFloat = 30
    static let minAnchoKPI: CGFloat = 160
    static let altoGrafico: CGFloat = 220
    static let radioKPI: CGFloat = 10
    static let barraDestinoAncho: CGFloat = 3
    static let barraDestinoAnchoIC: CGFloat = 4
    static let barraDestinoAlto: CGFloat = 18

    static let tipoDisplay: Font = .title.weight(.semibold)
    static let tipoTitulo: Font = .headline
    static let tipoCuerpo: Font = .body
    static let tipoFila: Font = .body.weight(.semibold)
    static let tipoFilaSec: Font = .subheadline
    static let tipoLabel: Font = .caption
    static let tipoBadge: Font = .caption.monospacedDigit()
    static let tipoAvatarSM: Font = .caption.weight(.semibold)
    static let tipoAvatarMD: Font = .headline.weight(.semibold)
    static let tipoAvatarLG: Font = .title.weight(.semibold)
    static let tipoError: Font = .callout
    static let tipoSeccion: Font = .subheadline.weight(.semibold)
    static let tipoKPIValor: Font = .title2.monospacedDigit()
    static let tipoKPILabel: Font = .caption

    static let kpiTexto = Color.white
    static let texto = Color.primary
    static let textoSec = Color.secondary
    static let ventana = Color(nsColor: .windowBackgroundColor)
    static let tarjeta = Color(nsColor: .controlBackgroundColor)
    static let separador = Color(nsColor: .separatorColor)
    static let error = Color.red
    static let inicialesAvatar = Color.white

    static func tintaEtiquetaProminent(esquema: ColorScheme) -> Color {
        esquema == .dark ? srgb(28, 28, 30) : Color.white
    }

    static func colorAvatar(nombreUsuario: String) -> Color {
        paletaAvatar[indicePaleta(nombreUsuario: nombreUsuario)]
    }

    static func indicePaleta(nombreUsuario: String) -> Int {
        if nombreUsuario.isEmpty { return 7 }
        let suma = nombreUsuario.unicodeScalars.reduce(0) { parcial, scalar in
            parcial + Int(scalar.value)
        }
        return suma % paletaAvatar.count
    }

    static func bannerFondo(esquema: ColorScheme, contraste: ColorSchemeContrast) -> Color {
        switch (esquema, contraste == .increased) {
        case (.dark, true): return srgb(42, 36, 20)
        case (.dark, false): return srgb(58, 52, 32)
        case (_, true): return srgb(248, 224, 154)
        default: return srgb(245, 230, 184)
        }
    }

    static func bannerIcono(esquema: ColorScheme, contraste: ColorSchemeContrast) -> Color {
        switch (esquema, contraste == .increased) {
        case (.dark, true): return srgb(255, 179, 64)
        case (.dark, false): return srgb(255, 159, 10)
        case (_, true): return srgb(138, 36, 0)
        default: return srgb(161, 42, 0)
        }
    }

    static func bannerTrazo(esquema: ColorScheme, contraste: ColorSchemeContrast) -> Color {
        switch (esquema, contraste == .increased) {
        case (.dark, true): return srgb(255, 179, 64, alpha: 0.70)
        case (.dark, false): return srgb(255, 159, 10, alpha: 0.40)
        case (_, true): return srgb(138, 36, 0, alpha: 0.70)
        default: return srgb(161, 42, 0, alpha: 0.35)
        }
    }

    static func wellRelleno(esquema: ColorScheme, contraste: ColorSchemeContrast, esError: Bool) -> Color {
        if esError {
            return bannerFondo(esquema: esquema, contraste: contraste)
        }
        switch esquema {
        case .dark: return srgb(26, 46, 45)
        default: return srgb(230, 243, 243)
        }
    }

    static func kpiCyan(esquema: ColorScheme, contraste: ColorSchemeContrast) -> Color {
        switch (esquema, contraste == .increased) {
        case (.dark, true): return srgb(6, 63, 67)
        case (.dark, false): return srgb(8, 82, 88)
        case (_, true): return srgb(8, 79, 84)
        default: return srgb(11, 110, 117)
        }
    }

    static func kpiNaranja(esquema: ColorScheme, contraste: ColorSchemeContrast) -> Color {
        switch (esquema, contraste == .increased) {
        case (.dark, true): return srgb(92, 44, 0)
        case (.dark, false): return srgb(138, 67, 0)
        case (_, true): return srgb(122, 58, 0)
        default: return srgb(184, 90, 0)
        }
    }

    static func kpiVerde(esquema: ColorScheme, contraste: ColorSchemeContrast) -> Color {
        switch (esquema, contraste == .increased) {
        case (.dark, true): return srgb(14, 64, 40)
        case (.dark, false): return srgb(22, 92, 58)
        case (_, true): return srgb(18, 84, 52)
        default: return srgb(31, 122, 77)
        }
    }

    static func kpiAzul(esquema: ColorScheme, contraste: ColorSchemeContrast) -> Color {
        switch (esquema, contraste == .increased) {
        case (.dark, true): return srgb(10, 50, 90)
        case (.dark, false): return srgb(14, 70, 128)
        case (_, true): return srgb(12, 62, 112)
        default: return srgb(18, 94, 171)
        }
    }

    static func shellFondo(esquema: ColorScheme) -> Color {
        esquema == .dark ? srgb(18, 32, 34) : srgb(232, 244, 244)
    }

    static func shellRellenoActivo(esquema: ColorScheme, contraste: ColorSchemeContrast) -> Color {
        if contraste == .increased { return .clear }
        return Color.accentColor.opacity(esquema == .dark ? 0.22 : 0.14)
    }

    static func fuenteAvatar(tamano: CGFloat) -> Font {
        switch tamano {
        case avatarDetalle: return tipoAvatarLG
        case avatarSheet: return tipoAvatarMD
        default: return tipoAvatarSM
        }
    }

    static func trackingAvatar(tamano: CGFloat, letras: Int) -> CGFloat {
        tamano >= avatarDetalle && letras >= 2 ? -0.5 : 0
    }

    private static let paletaAvatar: [Color] = [
        srgb(11, 110, 117),
        srgb(18, 94, 171),
        srgb(61, 74, 158),
        srgb(107, 63, 160),
        srgb(155, 45, 90),
        srgb(184, 90, 0),
        srgb(31, 122, 77),
        srgb(74, 85, 104)
    ]

    private static func srgb(_ r: Int, _ g: Int, _ b: Int, alpha: Double = 1) -> Color {
        Color(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: alpha)
    }
}

struct SimboloWellUsuarios: View {
    let systemName: String
    var esError = false

    @Environment(\.colorScheme) private var esquema
    @Environment(\.colorSchemeContrast) private var contraste

    var body: some View {
        ZStack {
            Circle()
                .fill(TemaUsuarios.wellRelleno(esquema: esquema, contraste: contraste, esError: esError))
                .frame(width: TemaUsuarios.wellEmpty, height: TemaUsuarios.wellEmpty)
            Image(systemName: systemName)
                .font(.system(size: TemaUsuarios.iconoWell, weight: .regular))
                .foregroundStyle(
                    esError
                        ? TemaUsuarios.bannerIcono(esquema: esquema, contraste: contraste)
                        : Color.accentColor
                )
        }
        .accessibilityHidden(true)
    }
}

struct EtiquetaWellUsuarios: View {
    let titulo: String
    let systemName: String
    var esError = false

    var body: some View {
        Label {
            Text(titulo)
                .font(TemaUsuarios.tipoTitulo)
        } icon: {
            SimboloWellUsuarios(systemName: systemName, esError: esError)
        }
    }
}

extension View {
    func estiloTarjetaUsuarios(contraste: ColorSchemeContrast) -> some View {
        let forma = RoundedRectangle(cornerRadius: TemaUsuarios.radioTarjeta, style: .continuous)
        return background(TemaUsuarios.tarjeta, in: forma)
            .overlay {
                forma.strokeBorder(
                    contraste == .increased
                        ? Color.primary.opacity(0.45)
                        : TemaUsuarios.separador,
                    lineWidth: contraste == .increased ? 1 : 0.5
                )
            }
    }

    func descripcionEmptyUsuarios() -> some View {
        font(TemaUsuarios.tipoCuerpo)
            .foregroundStyle(Color.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: TemaUsuarios.maxAnchoEmpty)
    }
}
