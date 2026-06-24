# OutlookLauncher

An iOS app that reads your last 12 hours of Outlook email via the **Microsoft Graph API**, generates draft replies using **Claude AI**, and saves them back to your Outlook Drafts folder — it never sends automatically.

## App Flow

1. Enter your Azure App Registration credentials and Anthropic API key on the setup screen
2. Sign in with your Microsoft work/school account
3. The app loads emails from the past 12 hours
4. Tap an email → tap **Generate with Claude** → edit the draft if needed → tap **Save Draft**
5. The draft appears in your Outlook Drafts folder, ready to review and send

---

## Setup Instructions

### 1. Register an App in Microsoft Entra ID

1. Go to [portal.azure.com](https://portal.azure.com) → **Microsoft Entra ID → App registrations → New registration**
2. Name: anything (e.g. `OutlookLauncherApp`)
3. Supported account types: **Accounts in this organizational directory only** (single tenant)
4. Redirect URI: choose **Public client/native (mobile & desktop)**, enter:
   ```
   msauth.YOUR_BUNDLE_ID://auth
   ```
   Replace `YOUR_BUNDLE_ID` with your Xcode bundle identifier (e.g. `com.yourname.OutlookLauncher`)
5. After creation, note the **Application (client) ID** and **Directory (tenant) ID** from the Overview page
6. Go to **API permissions → Add a permission → Microsoft Graph → Delegated → Mail.ReadWrite** → Grant admin consent

### 2. Get an Anthropic API Key

1. Sign up or log in at [console.anthropic.com](https://console.anthropic.com)
2. Go to **API Keys → Create Key**
3. Copy the key (starts with `sk-ant-…`)

### 3. Create an Xcode Project

1. Open Xcode → **File → New → Project → iOS → App**
2. Set:
   - **Product Name**: `OutlookLauncher`
   - **Bundle Identifier**: the same value you used as `YOUR_BUNDLE_ID` above
   - **Interface**: SwiftUI  |  **Language**: Swift
   - **Minimum Deployments**: iOS 17.0

### 4. Add MSAL via Swift Package Manager

1. In Xcode: **File → Add Package Dependencies**
2. Enter URL: `https://github.com/AzureAD/microsoft-authentication-library-for-objc`
3. Select the **MSAL** library target and add it to your app target

### 5. Add Source Files

Drag all files from this folder into your Xcode project, replacing the generated stubs:

```
OutlookLauncherApp.swift
ContentView.swift
Models/GraphEmail.swift
Services/AuthService.swift
Services/GraphEmailService.swift
Services/ClaudeService.swift
Views/SetupView.swift
Views/EmailListView.swift
Views/EmailDetailView.swift
```

### 6. Configure Info.plist

Replace your project's `Info.plist` with `Resources/Info.plist`, then **replace `YOUR_BUNDLE_ID`** with your actual bundle identifier in the `CFBundleURLSchemes` entry.

### 7. Build and Run

Connect your iPhone, select it as the run destination, and build. The Microsoft sign-in flow only works on a **real device** (not the simulator).

On first launch: enter your **Client ID**, **Tenant ID**, and **Anthropic API key**, then tap **Sign in with Microsoft**.

---

## Architecture

| File | Purpose |
|------|---------|
| `AuthService.swift` | MSAL sign-in, silent token refresh, sign-out |
| `GraphEmailService.swift` | Fetch recent emails & create Outlook drafts via Microsoft Graph |
| `ClaudeService.swift` | Generate reply text via Anthropic Claude API |
| `SetupView.swift` | One-time credential entry screen |
| `EmailListView.swift` | List of last-12-hours emails |
| `EmailDetailView.swift` | Email preview + editable draft + Save Draft button |

## Permissions & Data

| Item | Why |
|------|-----|
| `Mail.ReadWrite` (Graph) | Read inbox emails and create draft replies |
| `LSApplicationQueriesSchemes: ms-outlook` | Check if the Outlook app is installed |
| `CFBundleURLTypes: msauth.*` | Receive the MSAL OAuth redirect from the browser |
| Anthropic API key | Stored in `UserDefaults` on-device only — never sent to any server except `api.anthropic.com` |
| Azure credentials | Stored in `UserDefaults` on-device only |

## Hard rules (inherited from the outlook-email workflow)

- **Never sends email automatically.** Drafts are created as `isDraft: true` and must be sent manually by the user.
- **Drafts are editable** in `EmailDetailView` before saving — always review before tapping Save Draft.
