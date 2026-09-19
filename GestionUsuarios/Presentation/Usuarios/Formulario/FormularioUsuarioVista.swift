import AppKit
import SwiftUI

struct FormularioUsuarioVista: View {
    @Binding var borrador: BorradorUsuario
    var errores: [CampoUsuario: String]
    var titulo: String
    var onGuardar: () -> Void
    var onCancelar: () -> Void
    @Binding var campoFoco: CampoUsuario?
    var onCambioCampo: () -> Void
    var muestraAcciones = true

    @FocusState private var foco: CampoUsuario?
    @Environment(\.colorScheme) private var esquema

    var body: some View {
        Form {
            campo(
                titulo: TextosUsuarios.labelNombre,
                placeholder: TextosUsuarios.placeholderNombre,
                texto: $borrador.nombre,
                campo: .nombre,
                identificador: IdentificadorAccesibilidad.formNombre,
                contentType: .name
            )
            campo(
                titulo: TextosUsuarios.labelUsuario,
                placeholder: TextosUsuarios.placeholderUsuario,
                texto: $borrador.nombreUsuario,
                campo: .nombreUsuario,
                identificador: IdentificadorAccesibilidad.formUsername,
                contentType: .username
            )
            campo(
                titulo: TextosUsuarios.labelCorreo,
                placeholder: TextosUsuarios.placeholderCorreo,
                texto: $borrador.correo,
                campo: .correo,
                identificador: IdentificadorAccesibilidad.formEmail,
                contentType: .emailAddress
            )
            if muestraAcciones {
                HStack {
                    Spacer()
                    Button(TextosUsuarios.cancelar, role: .cancel, action: onCancelar)
                        .buttonStyle(.bordered)
                        .keyboardShortcut(.cancelAction)
                        .accessibilityIdentifier(IdentificadorAccesibilidad.formCancelar)
                    Button(action: onGuardar) {
                        Text(TextosUsuarios.guardar)
                            .foregroundStyle(TemaUsuarios.tintaEtiquetaProminent(esquema: esquema))
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier(IdentificadorAccesibilidad.formGuardar)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(titulo)
        .onAppear {
            foco = campoFoco ?? .nombre
        }
        .onChange(of: campoFoco) { _, nuevo in
            if let nuevo {
                foco = nuevo
            }
        }
        .onChange(of: foco) { _, nuevo in
            campoFoco = nuevo
        }
    }

    @ViewBuilder
    private func campo(
        titulo: String,
        placeholder: String,
        texto: Binding<String>,
        campo: CampoUsuario,
        identificador: String,
        contentType: NSTextContentType
    ) -> some View {
        let mensaje = errores[campo].map(MensajesValidacion.texto)
        VStack(alignment: .leading, spacing: TemaUsuarios.espacio6) {
            TextField(titulo, text: texto, prompt: Text(placeholder))
                .textContentType(contentType)
                .focused($foco, equals: campo)
                .accessibilityIdentifier(identificador)
                .accessibilityValue(valorAccesible(texto.wrappedValue, error: mensaje))
                .onChange(of: texto.wrappedValue) { _, _ in
                    onCambioCampo()
                }
            if let mensaje {
                Label(mensaje, systemImage: "exclamationmark.circle")
                    .font(TemaUsuarios.tipoError)
                    .foregroundStyle(Color.red)
                    .accessibilityHidden(true)
            }
        }
    }

    private func valorAccesible(_ texto: String, error: String?) -> String {
        if let error {
            return "\(texto), \(error), inválido"
        }
        return texto
    }
}
