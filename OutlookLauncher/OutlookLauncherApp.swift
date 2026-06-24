import SwiftUI
import MSAL
import UserNotifications

// Allows notification banners to appear while the app is in the foreground
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification,
                                 withCompletionHandler handler: @escaping (UNNotificationPresentationOptions) -> Void) {
        handler([.banner, .sound])
    }
}

@main
struct OutlookLauncherApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

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
                    guard !clientId.isEmpty, !tenantId.isEmpty else { return }
                    try? authService.configure(clientId: clientId, tenantId: tenantId)
                    await authService.signIn()
                }
        }
    }
}
