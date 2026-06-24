import Foundation
import MSAL
import UIKit

@MainActor
class AuthService: ObservableObject {
    @Published var isSignedIn = false
    @Published var accessToken: String?
    @Published var error: String?

    private var msalApp: MSALPublicClientApplication?
    private let scopes = ["https://graph.microsoft.com/Mail.ReadWrite"]

    func configure(clientId: String, tenantId: String) throws {
        let authorityURL = URL(string: "https://login.microsoftonline.com/\(tenantId)")!
        let authority = try MSALAADAuthority(url: authorityURL)
        let config = MSALPublicClientApplicationConfig(clientId: clientId,
                                                       redirectUri: nil,
                                                       authority: authority)
        msalApp = try MSALPublicClientApplication(configuration: config)
    }

    func signIn() async {
        guard let msalApp else {
            error = "Not configured — enter your Azure credentials first."
            return
        }

        // Try silent token refresh before showing the browser
        if let account = try? msalApp.allAccounts().first {
            let params = MSALSilentTokenParameters(scopes: scopes, account: account)
            do {
                let result = try await withCheckedThrowingContinuation { cont in
                    msalApp.acquireTokenSilent(with: params) { res, err in
                        if let err { cont.resume(throwing: err) }
                        else if let res { cont.resume(returning: res) }
                    }
                }
                accessToken = result.accessToken
                isSignedIn = true
                error = nil
                return
            } catch { /* silent failed — fall through to interactive */ }
        }

        // Interactive sign-in
        guard let rootVC = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { $0.isKeyWindow })?.rootViewController else {
            error = "Could not find a view controller for sign-in."
            return
        }

        let webParams = MSALWebviewParameters(authPresentationViewController: rootVC)
        let params = MSALInteractiveTokenParameters(scopes: scopes, webviewParameters: webParams)

        do {
            let result = try await withCheckedThrowingContinuation { cont in
                msalApp.acquireToken(with: params) { res, err in
                    if let err { cont.resume(throwing: err) }
                    else if let res { cont.resume(returning: res) }
                }
            }
            accessToken = result.accessToken
            isSignedIn = true
            error = nil
        } catch let e {
            self.error = e.localizedDescription
        }
    }

    func signOut() {
        guard let msalApp else { return }
        let accounts = (try? msalApp.allAccounts()) ?? []
        accounts.forEach { try? msalApp.remove($0) }
        accessToken = nil
        isSignedIn = false
    }
}
