import XCTest

final class GestionUsuariosUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = lanzar()
        XCTAssertTrue(
            app.descendants(matching: .any)[IdentificadorAccesibilidadUI.loginUsuario]
                .waitForExistence(timeout: 10),
            "El arranque debe mostrar login.usuario"
        )
    }

    @MainActor
    func testToolbarNuevoAbreFormularioNombre() throws {
        let app = lanzar()
        autenticar(app)

        let usuarios = app.descendants(matching: .any)[IdentificadorAccesibilidadUI.shellUsuarios]
        if usuarios.waitForExistence(timeout: 5) {
            usuarios.click()
        }

        let nuevo = app.descendants(matching: .any)[IdentificadorAccesibilidadUI.toolbarNuevo]
        XCTAssertTrue(nuevo.waitForExistence(timeout: 10), "Debe existir toolbar.nuevo")
        nuevo.click()

        let nombre = app.descendants(matching: .any)[IdentificadorAccesibilidadUI.formNombre]
        XCTAssertTrue(nombre.waitForExistence(timeout: 5), "Debe existir form.nombre")
    }

    @MainActor
    func testLogoutVuelveALoginUsuario() throws {
        let app = lanzar()
        autenticar(app)

        let logout = app.descendants(matching: .any)[IdentificadorAccesibilidadUI.toolbarLogout]
        XCTAssertTrue(logout.waitForExistence(timeout: 10), "Debe existir toolbar.logout")
        logout.click()

        XCTAssertTrue(
            app.descendants(matching: .any)[IdentificadorAccesibilidadUI.loginUsuario]
                .waitForExistence(timeout: 10),
            "Tras logout debe existir login.usuario"
        )
    }

    @MainActor
    func testInicioMuestraKpiUsuariosSinHomeTotal() throws {
        let app = lanzar()
        autenticar(app)

        let kpi = app.descendants(matching: .any)[IdentificadorAccesibilidadUI.homeKpiUsuarios]
        XCTAssertTrue(
            kpi.waitForExistence(timeout: 12),
            "Tras login debe existir home.kpi.usuarios"
        )
        XCTAssertFalse(
            app.descendants(matching: .any)["home.total"].exists,
            "home.total debe estar retirado"
        )
    }

    @MainActor
    private func lanzar() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        app.activate()
        let login = app.descendants(matching: .any)[IdentificadorAccesibilidadUI.loginUsuario]
        XCTAssertTrue(login.waitForExistence(timeout: 15), "Debe existir login.usuario")
        return app
    }

    @MainActor
    private func autenticar(_ app: XCUIApplication) {
        let usuario = app.descendants(matching: .any)[IdentificadorAccesibilidadUI.loginUsuario]
        XCTAssertTrue(usuario.waitForExistence(timeout: 10), "Debe existir login.usuario")
        usuario.click()
        usuario.typeText("waldofeliz")

        let clave = app.descendants(matching: .any)[IdentificadorAccesibilidadUI.loginClave]
        XCTAssertTrue(clave.waitForExistence(timeout: 5), "Debe existir login.clave")
        clave.click()
        clave.typeText("123456")

        let entrar = app.descendants(matching: .any)[IdentificadorAccesibilidadUI.loginEntrar]
        XCTAssertTrue(entrar.waitForExistence(timeout: 5), "Debe existir login.entrar")
        entrar.click()

        let home = app.descendants(matching: .any)[IdentificadorAccesibilidadUI.homeSaludo]
        let shellUsuarios = app.descendants(matching: .any)[IdentificadorAccesibilidadUI.shellUsuarios]
        let homeOK = home.waitForExistence(timeout: 12)
        let shellOK = shellUsuarios.waitForExistence(timeout: 2)
        XCTAssertTrue(homeOK || shellOK, "Tras login debe existir home.saludo o shell.usuarios")
    }
}

private enum IdentificadorAccesibilidadUI {
    static let loginUsuario = "login.usuario"
    static let loginClave = "login.clave"
    static let loginEntrar = "login.entrar"
    static let homeSaludo = "home.saludo"
    static let homeKpiUsuarios = "home.kpi.usuarios"
    static let shellUsuarios = "shell.usuarios"
    static let toolbarNuevo = "toolbar.nuevo"
    static let toolbarLogout = "toolbar.logout"
    static let formNombre = "form.nombre"
}
