import SwiftUI
import MSAL

@main
struct OutlookLauncherApp: App {
    @StateObject private var authService = AuthService()

    @AppStorage("azureClientId") private var clientId = ""
    @AppStorage("azureTenantId") private var tenantId = ""

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                // MSAL needs to intercept its redirect URI on return from the browser
                .onOpenURL { url in
                    MSALPublicClientApplication.handleMSALResponse(url, sourceApplication: nil)
                }
                .task {
                    // Attempt a silent token refresh on startup if credentials are saved
                    guard !clientId.isEmpty, !tenantId.isEmpty else { return }
                    try? authService.configure(clientId: clientId, tenantId: tenantId)
                    await authService.signIn()
                }
        }
    }
}
