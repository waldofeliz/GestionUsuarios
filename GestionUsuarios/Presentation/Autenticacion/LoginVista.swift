import SwiftUI

struct LoginVista: View {
    @State private var modelo: LoginVistaModelo
    @FocusState private var foco: CampoLogin?
    @Environment(\.colorScheme) private var esquema
    @Environment(\.colorSchemeContrast) private var contraste

    @Binding var sesion: Sesion?

    init(contenedor: ContenedorApp, sesion: Binding<Sesion?>) {
        _sesion = sesion
        _modelo = State(initialValue: LoginVistaModelo(contenedor: contenedor))
    }

    var body: some View {
        tarjeta
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                lienzo
            }
            .navigationTitle(TextosUsuarios.app)
            .onChange(of: modelo.sesionObtenida) { _, nueva in
                if let nueva {
                    sesion = nueva
                }
            }
            .onAppear {
                foco = .usuario
            }
            .onChange(of: modelo.foco) { _, nuevo in
                foco = nuevo
            }
            .onChange(of: foco) { _, nuevo in
                if let nuevo {
                    modelo.foco = nuevo
                }
            }
            .onChange(of: modelo.nombreUsuario) { _, _ in
                modelo.campoCambio()
            }
            .onChange(of: modelo.clave) { _, _ in
                modelo.campoCambio()
            }
    }

    private var tarjeta: some View {
        VStack(alignment: .leading, spacing: TemaUsuarios.espacio16) {
            encabezado
            Text(TextosUsuarios.loginEntornoDemo)
                .font(TemaUsuarios.tipoLabel)
                .foregroundStyle(Color.secondary)
                .accessibilityIdentifier(IdentificadorAccesibilidad.loginEntornoDemo)
            Text(TextosUsuarios.loginHint)
                .font(TemaUsuarios.tipoLabel)
                .foregroundStyle(Color.secondary)
                .accessibilityIdentifier(IdentificadorAccesibilidad.loginHint)
            campoUsuario
            campoClave
            TimelineView(.periodic(from: .now, by: 1)) { contexto in
                VStack(alignment: .leading, spacing: TemaUsuarios.espacio16) {
                    estados(ahora: contexto.date)
                    botonEntrar(ahora: contexto.date)
                }
            }
        }
        .padding(TemaUsuarios.espacio20)
        .frame(width: TemaUsuarios.anchoSheet, alignment: .leading)
        .estiloTarjetaUsuarios(contraste: contraste)
        .overlay {
            if esquema == .dark {
                RoundedRectangle(cornerRadius: TemaUsuarios.radioTarjeta, style: .continuous)
                    .strokeBorder(Color.primary.opacity(contraste == .increased ? 0.45 : 0.35), lineWidth: 1)
            }
        }
    }

    private var lienzo: some View {
        Group {
            if contraste == .increased {
                Color(nsColor: .systemBlue)
            } else {
                LinearGradient(
                    colors: [Color(nsColor: .systemBlue), Color(nsColor: .systemIndigo)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var encabezado: some View {
        HStack(alignment: .center, spacing: TemaUsuarios.espacio12) {
            SimboloWellUsuarios(systemName: "person.crop.circle")
            VStack(alignment: .leading, spacing: TemaUsuarios.espacio4) {
                Text(TextosUsuarios.loginTitulo)
                    .font(TemaUsuarios.tipoTitulo)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier(IdentificadorAccesibilidad.loginTituloId)
                Text(TextosUsuarios.loginSubtitulo)
                    .font(TemaUsuarios.tipoCuerpo)
                    .foregroundStyle(Color.secondary)
            }
        }
    }

    private var campoUsuario: some View {
        VStack(alignment: .leading, spacing: TemaUsuarios.espacio6) {
            Text(TextosUsuarios.loginLabelUsuario)
                .font(TemaUsuarios.tipoLabel)
            TextField(
                TextosUsuarios.loginLabelUsuario,
                text: $modelo.nombreUsuario,
                prompt: Text(TextosUsuarios.loginPlaceholderUsuario)
            )
            .textFieldStyle(.roundedBorder)
            .focused($foco, equals: .usuario)
            .labelsHidden()
            .accessibilityLabel(TextosUsuarios.loginLabelUsuario)
            .accessibilityIdentifier(IdentificadorAccesibilidad.loginUsuario)
            .onSubmit {
                Task { await modelo.enviar() }
            }
            if let error = modelo.errorUsuario {
                Label(error, systemImage: "exclamationmark.circle")
                    .font(TemaUsuarios.tipoError)
                    .foregroundStyle(Color.red)
                    .accessibilityHidden(true)
            }
        }
    }

    private var campoClave: some View {
        VStack(alignment: .leading, spacing: TemaUsuarios.espacio6) {
            Text(TextosUsuarios.loginLabelClave)
                .font(TemaUsuarios.tipoLabel)
            SecureField(TextosUsuarios.loginLabelClave, text: $modelo.clave)
                .textFieldStyle(.roundedBorder)
                .focused($foco, equals: .clave)
                .labelsHidden()
                .accessibilityLabel(TextosUsuarios.loginLabelClave)
                .accessibilityValue(TextosUsuarios.loginClaveOculta)
                .accessibilityIdentifier(IdentificadorAccesibilidad.loginClave)
                .onSubmit {
                    Task { await modelo.enviar() }
                }
            if let error = modelo.errorClave {
                Label(error, systemImage: "exclamationmark.circle")
                    .font(TemaUsuarios.tipoError)
                    .foregroundStyle(Color.red)
                    .accessibilityHidden(true)
            }
        }
    }

    @ViewBuilder
    private func estados(ahora: Date) -> some View {
        if let restantes = modelo.segundosBloqueo(ahora: ahora) {
            Label(TextosUsuarios.loginLockout(restantes), systemImage: "exclamationmark.circle")
                .font(TemaUsuarios.tipoError)
                .foregroundStyle(Color.primary)
                .accessibilityIdentifier(IdentificadorAccesibilidad.loginLockout)
        } else if let error = modelo.errorCredenciales {
            Label(error, systemImage: "exclamationmark.circle")
                .font(TemaUsuarios.tipoError)
                .foregroundStyle(Color.primary)
                .accessibilityIdentifier(IdentificadorAccesibilidad.loginError)
        }
    }

    private func botonEntrar(ahora: Date) -> some View {
        Button {
            Task { await modelo.enviar() }
        } label: {
            Text(TextosUsuarios.loginEntrar)
                .frame(maxWidth: .infinity)
                .foregroundStyle(TemaUsuarios.tintaEtiquetaProminent(esquema: esquema))
        }
        .buttonStyle(.borderedProminent)
        .keyboardShortcut(.defaultAction)
        .disabled(modelo.segundosBloqueo(ahora: ahora) != nil || modelo.enviando)
        .accessibilityLabel(TextosUsuarios.loginEntrar)
        .accessibilityIdentifier(IdentificadorAccesibilidad.loginEntrar)
    }
}

#Preview {
    LoginVista(contenedor: ContenedorApp(), sesion: .constant(nil))
}
