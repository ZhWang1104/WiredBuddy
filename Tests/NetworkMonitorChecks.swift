import Darwin
import Foundation

private final class CheckAddressProvider: NetworkAddressProviding {
    let addressesByInterface: [String: NetworkAddresses]

    init(addressesByInterface: [String: NetworkAddresses]) {
        self.addressesByInterface = addressesByInterface
    }

    func addresses(for interfaceName: String) -> NetworkAddresses {
        addressesByInterface[interfaceName] ?? .empty
    }
}

@main
private enum NetworkMonitorChecks {
    static func main() {
        var failures: [String] = []

        func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
            if !condition() {
                failures.append(message)
            }
        }

        let addresses = NetworkAddresses(ipv4: "192.0.2.10", ipv6: "2001:db8::10")
        let provider = CheckAddressProvider(addressesByInterface: ["en7": addresses])

        let secondaryState = WiredNetworkState.resolve(
            defaultPath: NetworkPathSnapshot(
                isSatisfied: true,
                usesWiredEthernet: false,
                wiredInterfaceNames: []
            ),
            wiredPath: NetworkPathSnapshot(
                isSatisfied: true,
                usesWiredEthernet: true,
                wiredInterfaceNames: ["en7"]
            ),
            addressProvider: provider
        )
        expect(secondaryState.isAvailable, "A satisfied wired path must be available")
        expect(!secondaryState.isPreferred, "A non-default wired path must not be preferred")
        expect(secondaryState.interfaceName == "en7", "The wired monitor interface must be selected")
        expect(secondaryState.addresses == addresses, "Addresses must belong to the selected interface")

        let unavailableState = WiredNetworkState.resolve(
            defaultPath: .unavailable,
            wiredPath: .unavailable,
            addressProvider: provider
        )
        expect(unavailableState == .unavailable, "Unsatisfied paths must clear stale network data")

        let loopback = SystemNetworkAddressProvider().addresses(for: "lo0")
        expect(loopback.ipv4 == "127.0.0.1", "getifaddrs must return the loopback IPv4 address")
        expect(loopback.ipv6 != nil, "getifaddrs must return a loopback IPv6 address")

        let missingInterface = SystemNetworkAddressProvider().addresses(for: "wiredbuddy-missing")
        expect(missingInterface == .empty, "A missing interface must return empty addresses")

        if failures.isEmpty {
            print("All network monitor checks passed")
        } else {
            for failure in failures {
                fputs("FAIL: \(failure)\n", stderr)
            }
            exit(EXIT_FAILURE)
        }
    }
}
