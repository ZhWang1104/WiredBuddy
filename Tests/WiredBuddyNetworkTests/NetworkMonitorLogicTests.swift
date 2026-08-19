import XCTest
@testable import WiredBuddyBuildCheck

final class NetworkMonitorLogicTests: XCTestCase {
    func testUnavailablePathClearsInterfaceAndAddresses() {
        let provider = StubAddressProvider(
            addressesByInterface: ["en1": NetworkAddresses(ipv4: "192.0.2.10", ipv6: nil)]
        )

        let state = WiredNetworkState.resolve(
            defaultPath: .unavailable,
            wiredPath: NetworkPathSnapshot(
                isSatisfied: false,
                usesWiredEthernet: false,
                wiredInterfaceNames: ["en1"]
            ),
            addressProvider: provider
        )

        XCTAssertEqual(state, .unavailable)
        XCTAssertEqual(provider.requestedInterfaces, [])
    }

    func testConnectedEthernetCanBeAvailableWithoutBeingPreferred() {
        let addresses = NetworkAddresses(ipv4: "192.0.2.10", ipv6: "2001:db8::10")
        let provider = StubAddressProvider(addressesByInterface: ["en7": addresses])

        let state = WiredNetworkState.resolve(
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

        XCTAssertTrue(state.isAvailable)
        XCTAssertFalse(state.isPreferred)
        XCTAssertEqual(state.interfaceName, "en7")
        XCTAssertEqual(state.addresses, addresses)
    }

    func testDefaultPathInterfaceWinsWhenEthernetIsPreferred() {
        let provider = StubAddressProvider(
            addressesByInterface: [
                "en3": NetworkAddresses(ipv4: "198.51.100.4", ipv6: nil),
                "en8": NetworkAddresses(ipv4: "203.0.113.8", ipv6: nil)
            ]
        )

        let state = WiredNetworkState.resolve(
            defaultPath: NetworkPathSnapshot(
                isSatisfied: true,
                usesWiredEthernet: true,
                wiredInterfaceNames: ["en3"]
            ),
            wiredPath: NetworkPathSnapshot(
                isSatisfied: true,
                usesWiredEthernet: true,
                wiredInterfaceNames: ["en8"]
            ),
            addressProvider: provider
        )

        XCTAssertTrue(state.isAvailable)
        XCTAssertTrue(state.isPreferred)
        XCTAssertEqual(state.interfaceName, "en3")
        XCTAssertEqual(state.addresses.ipv4, "198.51.100.4")
    }

    func testDefaultPathKeepsStateAvailableWhileWiredMonitorStarts() {
        let provider = StubAddressProvider(
            addressesByInterface: ["en0": NetworkAddresses(ipv4: "192.0.2.1", ipv6: nil)]
        )

        let state = WiredNetworkState.resolve(
            defaultPath: NetworkPathSnapshot(
                isSatisfied: true,
                usesWiredEthernet: true,
                wiredInterfaceNames: ["en0"]
            ),
            wiredPath: .unavailable,
            addressProvider: provider
        )

        XCTAssertTrue(state.isAvailable)
        XCTAssertTrue(state.isPreferred)
        XCTAssertEqual(state.interfaceName, "en0")
    }

    func testSystemAddressProviderReadsLoopbackWithoutCrashing() throws {
        let addresses = SystemNetworkAddressProvider().addresses(for: "lo0")

        XCTAssertEqual(addresses.ipv4, "127.0.0.1")
        XCTAssertNotNil(addresses.ipv6)
    }
}

private final class StubAddressProvider: NetworkAddressProviding {
    private let addressesByInterface: [String: NetworkAddresses]
    private(set) var requestedInterfaces: [String] = []

    init(addressesByInterface: [String: NetworkAddresses]) {
        self.addressesByInterface = addressesByInterface
    }

    func addresses(for interfaceName: String) -> NetworkAddresses {
        requestedInterfaces.append(interfaceName)
        return addressesByInterface[interfaceName] ?? .empty
    }
}
