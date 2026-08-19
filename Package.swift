// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "WiredBuddyBuildCheck",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(
            url: "https://github.com/yeahitsjan/LaunchAtLogin-Modern",
            revision: "a04ec1c363be3627734f6dad757d82f5d4fa8fcc"
        ),
        .package(
            url: "https://github.com/yeahitsjan/MacControlCenterUI",
            revision: "a98dc47a61116b126092839cf1617274f5c603dc"
        ),
        .package(
            url: "https://github.com/orchetect/MenuBarExtraAccess",
            exact: "1.2.2"
        ),
        .package(
            url: "https://github.com/orchetect/SettingsAccess",
            exact: "1.4.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "WiredBuddyBuildCheck",
            dependencies: [
                .product(name: "LaunchAtLogin", package: "LaunchAtLogin-Modern"),
                .product(name: "MacControlCenterUI", package: "MacControlCenterUI"),
                .product(name: "MenuBarExtraAccess", package: "MenuBarExtraAccess"),
                .product(name: "SettingsAccess", package: "SettingsAccess")
            ],
            path: "Wired Buddy",
            exclude: [
                "Assets.xcassets",
                "Locales",
                "Preview Content",
                "Wired_Buddy.entitlements"
            ]
        ),
        .testTarget(
            name: "WiredBuddyBuildCheckTests",
            dependencies: ["WiredBuddyBuildCheck"],
            path: "Tests/WiredBuddyNetworkTests"
        )
    ]
)
