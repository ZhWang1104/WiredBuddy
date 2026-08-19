// Copyright (c) 2024-2026 Jan Strumpen <jan@strumpen.dev>. Licensed under the MIT License.

import SwiftUI
import LaunchAtLogin

struct GeneralView: View {
    let isConnectionActive: Bool
    @Binding var wiredBuddyImage: Int

    @Binding var hideDockIcon: Bool
    @Binding var onlyShowIcon: Bool
    @Binding var hideIPinMenu: Bool
    @Binding var colorStatus: Bool

    var body: some View {
        Form {
            LabeledContent(LocalizedStringKey("startup")) {
                LaunchAtLogin.Toggle {
                    Text(LocalizedStringKey("launch_on_start"))
                }
            }
            Divider()
            LabeledContent(LocalizedStringKey("behavior")) {
                Toggle(LocalizedStringKey("only_icon"), isOn: $onlyShowIcon)
                    .toggleStyle(.checkbox)
            }
            Text(LocalizedStringKey("descr_only_icon")).font(.footnote).foregroundColor(.secondary).lineLimit(nil).fixedSize(horizontal: false, vertical: true)
            Toggle(LocalizedStringKey("hide_dock_icon"), isOn: $hideDockIcon)
                .toggleStyle(.checkbox)
            Text(LocalizedStringKey("descr_hide_dock_icon")).font(.footnote).foregroundColor(.secondary).lineLimit(nil).fixedSize(horizontal: false, vertical: true)
            Toggle(LocalizedStringKey("hide_ip"), isOn: $hideIPinMenu)
                .toggleStyle(.checkbox)
            Divider()
            Picker(LocalizedStringKey("menu_bar_symbol"), selection: $wiredBuddyImage) {
                ForEach(buddies) { buddy in
                    if isConnectionActive {
                        Image(systemName: buddy.imageActive).tag(buddy.id)
                    } else {
                        Image(systemName: buddy.imageInactive).tag(buddy.id)
                    }
                }
            }
            LabeledContent(LocalizedStringKey("colors")) {
                Toggle(LocalizedStringKey("colorize_status"), isOn: $colorStatus)
                    .toggleStyle(.checkbox)
                    .disabled(onlyShowIcon ? true : false)
            }
            Text(LocalizedStringKey("descr_colorize_status")).font(.footnote).foregroundColor(.secondary).lineLimit(nil).fixedSize(horizontal: false, vertical: true)
            Spacer()
        }.padding()
        .onChange(of: hideDockIcon) { opt in
            DockIconVisibility.apply(hidden: opt)
        }
    }
}
