# OutlookLauncher

A minimal iOS app with a single button that opens Microsoft Outlook. If Outlook isn't installed, it offers to take you to the App Store.

## How it works

- Uses the `ms-outlook://` URL scheme registered by the official Microsoft Outlook app
- `canOpenURL` checks whether Outlook is installed before trying to open it
- Falls back to the App Store listing if Outlook is missing

## Setup

### 1. Create an Xcode Project

1. Open Xcode → **File → New → Project**
2. Choose **iOS → App**
3. Set:
   - **Product Name**: `OutlookLauncher`
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Minimum Deployments**: iOS 17.0
4. Save the project

### 2. Add Source Files

Drag these files into your Xcode project (replace the generated stubs):
- `OutlookLauncherApp.swift`
- `ContentView.swift`

### 3. Configure Info.plist

Add the contents of `Resources/Info.plist` to your project's Info.plist (or replace it).

The `LSApplicationQueriesSchemes` entry for `ms-outlook` is required — without it, `canOpenURL` always returns `false` on iOS 9+.

### 4. Build and Run

Connect your iPhone and build. The simulator works for layout, but the deep link only fires on a real device with Outlook installed.

## Permissions

| Entry | Why |
|-------|-----|
| `LSApplicationQueriesSchemes: ms-outlook` | Allows the app to check if Outlook is installed before trying to open it |

No other permissions, sign-ins, or frameworks required.
