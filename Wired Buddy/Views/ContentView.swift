// Copyright (c) 2024-2026 Jan Strumpen <jan@strumpen.dev>. Licensed under the MIT License.

import MacControlCenterUI
import SettingsAccess
import SwiftUI

struct ContentView: View {
    @Binding var isMenuPresented: Bool
    let networkState: WiredNetworkState

    @State private var isInfoSectionExpanded = true
    @Binding var onlyShowIcon: Bool
    @Binding var hideIPinMenu: Bool
    @Binding var colorStatus: Bool
    @Binding var tabSelection: Int

    @Environment(\.openURL) private var openURL
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        MacControlCenterMenu(isPresented: $isMenuPresented) {
            if onlyShowIcon {
                if !hideIPinMenu {
                    addressRows
                    Divider()
                }
            } else {
                MenuHeader(LocalizedStringKey("ethernet")) {
                    if let interfaceName = networkState.interfaceName {
                        Text(interfaceName)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }

                MenuToggle(
                    isOn: .constant(networkState.isAvailable),
                    image: networkState.isAvailable
                        ? Image(systemName: "network")
                        : Image(systemName: "network.slash")
                ) {
                    Text(
                        networkState.isAvailable
                            ? LocalizedStringKey("eth_is_connected")
                            : LocalizedStringKey("eth_not_connected")
                    )
                    .foregroundColor(statusColor)
                }

                MenuDisclosureSection(
                    LocalizedStringKey("information"),
                    isExpanded: $isInfoSectionExpanded
                ) {
                    if !hideIPinMenu {
                        addressRows
                    }

                    if networkState.isAvailable {
                        MenuToggle(
                            isOn: .constant(networkState.isPreferred),
                            image: networkState.isPreferred
                                ? Image(systemName: "trophy")
                                : Image(systemName: "exclamationmark.triangle")
                        ) {
                            Text(
                                networkState.isPreferred
                                    ? LocalizedStringKey("eth_preferred")
                                    : LocalizedStringKey("eth_not_preferred")
                            )
                        } onClick: { _ in
                            tabSelection = 1
                            openSettingsView()
                        }
                    }
                }

                Divider()
            }

            MenuCommand(LocalizedStringKey("network_prefs")) {
                guard let settingsURL = URL(
                    string: "x-apple.systempreferences:com.apple.Network-Settings.extension"
                ) else {
                    return
                }
                openURL(settingsURL)
            }

            Divider()

            MenuCommand(LocalizedStringKey("preferences")) {
                tabSelection = 0
                openSettingsView()
            }

            MenuCommand(LocalizedStringKey("about")) {
                tabSelection = 2
                openSettingsView()
            }

            Divider()

            MenuCommand(LocalizedStringKey("quit")) {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private var statusColor: Color? {
        guard colorStatus else {
            return nil
        }
        return networkState.isAvailable ? .green : .red
    }

    @ViewBuilder
    private var addressRows: some View {
        MenuToggle(
            isOn: .constant(networkState.isAvailable),
            image: Image(systemName: "externaldrive.connected.to.line.below")
        ) {
            Text("IPv4: \(ipv4DisplayValue)")
        } onClick: { _ in
            tabSelection = 1
            openSettingsView()
        }

        if let ipv6 = networkState.addresses.ipv6 {
            MenuToggle(
                isOn: .constant(networkState.isAvailable),
                image: Image(systemName: "network")
            ) {
                Text("IPv6: \(ipv6)")
            } onClick: { _ in
                tabSelection = 1
                openSettingsView()
            }
        }
    }

    private func openSettingsView() {
        try? openSettings()
    }

    private var ipv4DisplayValue: String {
        networkState.addresses.ipv4 ?? String(localized: "not_available")
    }
}
