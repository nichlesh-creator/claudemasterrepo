import SwiftUI

struct ContentView: View {
    @State private var showNotInstalledAlert = false

    // Outlook deep-link URL scheme registered by the official Microsoft Outlook app
    private let outlookSchemeURL = URL(string: "ms-outlook://")!
    // App Store page for Microsoft Outlook
    private let appStoreURL = URL(string: "https://apps.apple.com/app/microsoft-outlook/id951937596")!

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Image(systemName: "envelope.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(.white)
                .padding(28)
                .background(Color(red: 0, green: 0.47, blue: 0.84))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: Color(red: 0, green: 0.47, blue: 0.84).opacity(0.4), radius: 16, y: 6)

            VStack(spacing: 8) {
                Text("Outlook Launcher")
                    .font(.title.bold())
                Text("Tap to open Microsoft Outlook")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button(action: openOutlook) {
                Text("Open Outlook")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(red: 0, green: 0.47, blue: 0.84))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .alert("Outlook Not Installed", isPresented: $showNotInstalledAlert) {
            Button("Get Outlook") { UIApplication.shared.open(appStoreURL) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Microsoft Outlook isn't installed on this device. Would you like to download it from the App Store?")
        }
    }

    private func openOutlook() {
        if UIApplication.shared.canOpenURL(outlookSchemeURL) {
            UIApplication.shared.open(outlookSchemeURL)
        } else {
            showNotInstalledAlert = true
        }
    }
}

#Preview {
    ContentView()
}
