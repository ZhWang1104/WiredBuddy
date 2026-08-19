// Copyright (c) 2024-2026 Jan Strumpen <jan@strumpen.dev>. Licensed under the MIT License.

import MenuBarExtraAccess
import SettingsAccess
import SwiftUI

enum DockIconVisibility {
    static func apply(hidden: Bool) {
        NSApplication.shared.setActivationPolicy(hidden ? .accessory : .regular)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let defaults = UserDefaults.standard
        let hideDockIcon = defaults.object(forKey: "HideDockIcon") as? Bool ?? true
        DockIconVisibility.apply(hidden: hideDockIcon)
    }
}

@main
struct WiredBuddyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var networkMonitor = WBNetworkMonitor()

    @State private var isMenuPresented = false
    @State private var tabSelection = 0

    @AppStorage("Buddy") private var wiredBuddyImage = 0
    @AppStorage("HideDockIcon") private var hideDockIcon = true
    @AppStorage("IconMode") private var onlyShowIcon = false
    @AppStorage("HideIPinMenu") private var hideIPinMenu = false
    @AppStorage("ColorizeStatus") private var colorStatus = false

    private var selectedBuddy: Buddy {
        buddies.first(where: { $0.id == wiredBuddyImage })
            ?? Buddy(id: 0, imageActive: "network", imageInactive: "network.slash")
    }

    var body: some Scene {
        MenuBarExtra(
            "Wired Buddy",
            systemImage: networkMonitor.state.isAvailable
                ? selectedBuddy.imageActive
                : selectedBuddy.imageInactive
        ) {
            ContentView(
                isMenuPresented: $isMenuPresented,
                networkState: networkMonitor.state,
                onlyShowIcon: $onlyShowIcon,
                hideIPinMenu: $hideIPinMenu,
                colorStatus: $colorStatus,
                tabSelection: $tabSelection
            )
            .openSettingsAccess()
        }
        .menuBarExtraStyle(.window)
        .menuBarExtraAccess(isPresented: $isMenuPresented)

        Settings {
            SettingsView(
                isConnectionActive: networkMonitor.state.isAvailable,
                wiredBuddyImage: $wiredBuddyImage,
                hideDockIcon: $hideDockIcon,
                onlyShowIcon: $onlyShowIcon,
                hideIPinMenu: $hideIPinMenu,
                colorStatus: $colorStatus,
                tabSelection: $tabSelection
            )
        }
        .commandsRemoved()
    }
}
