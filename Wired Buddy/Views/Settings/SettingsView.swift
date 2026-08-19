// Copyright (c) 2024-2026 Jan Strumpen <jan@strumpen.dev>. Licensed under the MIT License.

import SwiftUI

struct SettingsView: View {
    let isConnectionActive: Bool
    @Binding var wiredBuddyImage: Int

    @Binding var hideDockIcon: Bool
    @Binding var onlyShowIcon: Bool
    @Binding var hideIPinMenu: Bool
    @Binding var colorStatus: Bool

    @Binding var tabSelection: Int
    
    var body: some View {
        TabView(selection: $tabSelection) {
            GeneralView(isConnectionActive: isConnectionActive,
                        wiredBuddyImage: $wiredBuddyImage,
                        hideDockIcon: $hideDockIcon,
                        onlyShowIcon: $onlyShowIcon,
                        hideIPinMenu: $hideIPinMenu,
                        colorStatus: $colorStatus)
                .tabItem {
                    Label(LocalizedStringKey("general"), systemImage: "gearshape")
                }.tag(0)
            TipsView()
                .tabItem {
                    Label(LocalizedStringKey("tips"), systemImage: "lightbulb.max")
                }.tag(1)
            AboutView()
                .tabItem {
                    Label(LocalizedStringKey("about_header"), systemImage: "info.circle")
                }.tag(2)
        }.frame(width: 450, height: 300)
        .onAppear {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
}
