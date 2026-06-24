import SwiftUI

struct SetupView: View {
    @EnvironmentObject var authService: AuthService

    @AppStorage("azureClientId") private var clientId = ""
    @AppStorage("azureTenantId") private var tenantId = ""
    @AppStorage("anthropicApiKey") private var anthropicKey = ""

    @State private var isSigningIn = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Client ID (Application ID)", text: $clientId)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    TextField("Tenant ID (Directory ID)", text: $tenantId)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Azure App Registration")
                } footer: {
                    Text("Register an app in Microsoft Entra ID, grant Mail.ReadWrite permission, and add msauth.<BundleID>://auth as a redirect URI.")
                }

                Section {
                    SecureField("API Key  (sk-ant-…)", text: $anthropicKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Anthropic Claude API")
                } footer: {
                    Text("Used to generate draft replies. Your key is stored on-device only.")
                }

                if let error = authService.error {
                    Section {
                        Text(error).foregroundStyle(.red).font(.footnote)
                    }
                }

                Section {
                    Button {
                        Task { await signIn() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSigningIn {
                                ProgressView()
                            } else {
                                Text("Sign in with Microsoft")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(clientId.isEmpty || tenantId.isEmpty || isSigningIn)
                }
            }
            .navigationTitle("Setup")
        }
    }

    private func signIn() async {
        isSigningIn = true
        do {
            try authService.configure(clientId: clientId, tenantId: tenantId)
            await authService.signIn()
        } catch {
            authService.error = error.localizedDescription
        }
        isSigningIn = false
    }
}
