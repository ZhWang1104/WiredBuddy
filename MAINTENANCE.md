# Maintenance guide

## Supported status model

Wired Buddy intentionally keeps two independent signals:

| Scenario | Available | Preferred |
| --- | --- | --- |
| Ethernet disconnected | No | No |
| Ethernet is the default path | Yes | Yes |
| Ethernet connected while another path is used | Yes | No |
| VPN or tunnel whose underlying path uses Ethernet | Yes | Yes |

`NWPath.usesInterfaceType(.wiredEthernet)` includes a physical interface beneath a tunnel. In that case “Preferred” means that the current default path uses Ethernet as a transport; it does not mean the tunnel is bypassed.

When more than one Ethernet interface is available, `NWPath.availableInterfaces` supplies them in preference order. Address enumeration is restricted to the selected BSD interface name.

## Before merging a change

Run:

```sh
Scripts/verify-network.sh
swift build --target WiredBuddyBuildCheck
swift test
xcodebuild \
  -project "Wired Buddy.xcodeproj" \
  -scheme "Wired Buddy" \
  -configuration Debug \
  -destination "platform=macOS" \
  CODE_SIGNING_ALLOWED=NO \
  build
```

The last two commands require full Xcode. CI runs the complete sequence.

Test these physical configurations before a release:

1. Ethernet only.
2. Ethernet and Wi-Fi with each service order.
3. Cable disconnect and reconnect while the menu is open.
4. A USB Ethernet adapter being attached and removed.
5. A VPN over Ethernet.
6. DHCP renewal and an IPv6-enabled network.
7. Launch at login after moving the app to `/Applications`.

## Dependency updates

`LaunchAtLogin-Modern` and the `MacControlCenterUI` fork are pinned to revisions because those repositories do not provide suitable stable releases. Update a revision only after the build and physical-network checks pass. Commit both `Package.resolved` files whenever the dependency graph changes.

## Release checklist

1. Update `MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`, and `Packaging/Info.plist` together.
2. Archive a Release build in Xcode.
3. Sign with a Developer ID Application certificate and enable the hardened runtime.
4. Submit the archive to Apple notarization and staple the result.
5. Verify with `codesign --verify --deep --strict` and `spctl -a -vv` on a clean account.
6. Test the ZIP after downloading it so quarantine behavior is included.
7. Update the cask version, checksum, and app path, then run `brew style` and `brew audit` from a proper tap.

Ad-hoc signing is appropriate for a locally built copy but not for a public binary release.
