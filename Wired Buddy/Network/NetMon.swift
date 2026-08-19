// Copyright (c) 2024-2026 Jan Strumpen <jan@strumpen.dev>. Licensed under the MIT License.

import Combine
import Darwin
import Foundation
import Network
import OSLog

struct NetworkAddresses: Equatable {
    let ipv4: String?
    let ipv6: String?

    static let empty = NetworkAddresses(ipv4: nil, ipv6: nil)
}

struct NetworkPathSnapshot: Equatable {
    let isSatisfied: Bool
    let usesWiredEthernet: Bool
    let wiredInterfaceNames: [String]

    static let unavailable = NetworkPathSnapshot(
        isSatisfied: false,
        usesWiredEthernet: false,
        wiredInterfaceNames: []
    )

    init(path: NWPath) {
        isSatisfied = path.status == .satisfied
        usesWiredEthernet = path.usesInterfaceType(.wiredEthernet)
        wiredInterfaceNames = path.availableInterfaces
            .filter { $0.type == .wiredEthernet }
            .map(\.name)
    }

    init(isSatisfied: Bool, usesWiredEthernet: Bool, wiredInterfaceNames: [String]) {
        self.isSatisfied = isSatisfied
        self.usesWiredEthernet = usesWiredEthernet
        self.wiredInterfaceNames = wiredInterfaceNames
    }
}

struct WiredNetworkState: Equatable {
    let isAvailable: Bool
    let isPreferred: Bool
    let interfaceName: String?
    let addresses: NetworkAddresses

    static let unavailable = WiredNetworkState(
        isAvailable: false,
        isPreferred: false,
        interfaceName: nil,
        addresses: .empty
    )

    static func resolve(
        defaultPath: NetworkPathSnapshot,
        wiredPath: NetworkPathSnapshot,
        addressProvider: NetworkAddressProviding
    ) -> WiredNetworkState {
        let defaultUsesWired = defaultPath.isSatisfied && defaultPath.usesWiredEthernet
        let wiredIsAvailable = wiredPath.isSatisfied || defaultUsesWired

        guard wiredIsAvailable else {
            return .unavailable
        }

        let interfaceName: String?
        if defaultUsesWired {
            interfaceName = defaultPath.wiredInterfaceNames.first
                ?? wiredPath.wiredInterfaceNames.first
        } else {
            interfaceName = wiredPath.wiredInterfaceNames.first
        }

        let addresses = interfaceName.map(addressProvider.addresses(for:)) ?? .empty

        return WiredNetworkState(
            isAvailable: true,
            isPreferred: defaultUsesWired,
            interfaceName: interfaceName,
            addresses: addresses
        )
    }
}

protocol NetworkAddressProviding {
    func addresses(for interfaceName: String) -> NetworkAddresses
}

struct SystemNetworkAddressProvider: NetworkAddressProviding {
    func addresses(for interfaceName: String) -> NetworkAddresses {
        var firstAddressPointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&firstAddressPointer) == 0,
              let firstAddressPointer else {
            return .empty
        }
        defer { freeifaddrs(firstAddressPointer) }

        var ipv4Candidates = Set<String>()
        var ipv6Candidates = Set<String>()

        for pointer in sequence(first: firstAddressPointer, next: { $0.pointee.ifa_next }) {
            let interface = pointer.pointee
            guard String(cString: interface.ifa_name) == interfaceName,
                  interface.ifa_flags & UInt32(IFF_UP) != 0,
                  let socketAddress = interface.ifa_addr else {
                continue
            }

            let family = Int32(socketAddress.pointee.sa_family)
            guard family == AF_INET || family == AF_INET6 else {
                continue
            }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let result = getnameinfo(
                socketAddress,
                socklen_t(socketAddress.pointee.sa_len),
                &hostname,
                socklen_t(hostname.count),
                nil,
                0,
                NI_NUMERICHOST
            )
            guard result == 0 else {
                continue
            }

            let address = String(cString: hostname)
            if family == AF_INET, address != "0.0.0.0" {
                ipv4Candidates.insert(address)
            } else if family == AF_INET6, address != "::" {
                ipv6Candidates.insert(address)
            }
        }

        return NetworkAddresses(
            ipv4: preferredIPv4(from: ipv4Candidates),
            ipv6: preferredIPv6(from: ipv6Candidates)
        )
    }

    private func preferredIPv4(from addresses: Set<String>) -> String? {
        addresses.sorted { lhs, rhs in
            let lhsRank = lhs.hasPrefix("169.254.") ? 1 : 0
            let rhsRank = rhs.hasPrefix("169.254.") ? 1 : 0
            return lhsRank == rhsRank ? lhs < rhs : lhsRank < rhsRank
        }.first
    }

    private func preferredIPv6(from addresses: Set<String>) -> String? {
        addresses.sorted { lhs, rhs in
            let lhsRank = lhs.lowercased().hasPrefix("fe80:") ? 1 : 0
            let rhsRank = rhs.lowercased().hasPrefix("fe80:") ? 1 : 0
            return lhsRank == rhsRank ? lhs < rhs : lhsRank < rhsRank
        }.first
    }
}

final class WBNetworkMonitor: ObservableObject {
    @Published private(set) var state: WiredNetworkState = .unavailable

    private let defaultPathMonitor: NWPathMonitor
    private let wiredPathMonitor: NWPathMonitor
    private let addressProvider: NetworkAddressProviding
    private let monitorQueue = DispatchQueue(label: "WiredBuddy.NetworkMonitor")
    private let logger = Logger(
        subsystem: "de.jkowalewicz.WiredBuddy",
        category: "NetworkMonitor"
    )

    private var defaultPath: NetworkPathSnapshot = .unavailable
    private var wiredPath: NetworkPathSnapshot = .unavailable

    init(
        defaultPathMonitor: NWPathMonitor = NWPathMonitor(),
        wiredPathMonitor: NWPathMonitor = NWPathMonitor(requiredInterfaceType: .wiredEthernet),
        addressProvider: NetworkAddressProviding = SystemNetworkAddressProvider()
    ) {
        self.defaultPathMonitor = defaultPathMonitor
        self.wiredPathMonitor = wiredPathMonitor
        self.addressProvider = addressProvider
        start()
    }

    deinit {
        defaultPathMonitor.cancel()
        wiredPathMonitor.cancel()
    }

    private func start() {
        defaultPathMonitor.pathUpdateHandler = { [weak self] path in
            let snapshot = NetworkPathSnapshot(path: path)
            DispatchQueue.main.async {
                self?.defaultPath = snapshot
                self?.refreshState()
            }
        }

        wiredPathMonitor.pathUpdateHandler = { [weak self] path in
            let snapshot = NetworkPathSnapshot(path: path)
            DispatchQueue.main.async {
                self?.wiredPath = snapshot
                self?.refreshState()
            }
        }

        defaultPathMonitor.start(queue: monitorQueue)
        wiredPathMonitor.start(queue: monitorQueue)
    }

    private func refreshState() {
        state = WiredNetworkState.resolve(
            defaultPath: defaultPath,
            wiredPath: wiredPath,
            addressProvider: addressProvider
        )

        let interfaceName = state.interfaceName ?? "none"
        logger.debug("available=\(self.state.isAvailable, privacy: .public), preferred=\(self.state.isPreferred, privacy: .public), interface=\(interfaceName, privacy: .public)")
    }
}
