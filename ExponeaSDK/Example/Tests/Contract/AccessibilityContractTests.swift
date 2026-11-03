import XCTest
import Yams
@testable import Example

/// Keeps `A11yID` and `automation_contract.yaml` in sync. The IDs are shared with test-hub and the other
/// example apps, so a rename or a new ID must be reflected in the contract.
final class AccessibilityContractTests: XCTestCase {

    private struct ContractId {
        let capability: String
        let id: String
        let afterTap: String?
    }

    private static let idFormat = try! NSRegularExpression(pattern: "^[a-z][a-z0-9]*(_[a-z0-9]+)+$")

    private func contract() throws -> [String: Any] {
        let url = try XCTUnwrap(
            Bundle(for: Self.self).url(forResource: "automation_contract", withExtension: "yaml"),
            "automation_contract.yaml is not a resource of the test bundle"
        )
        return try XCTUnwrap(try Yams.load(yaml: String(contentsOf: url, encoding: .utf8)) as? [String: Any])
    }

    /// Contract IDs this app can't apply (`known_gaps` in the YAML), each with a reason.
    private func knownGaps() throws -> [String] {
        let gaps = try XCTUnwrap(try contract()["known_gaps"] as? [[String: Any]], "missing known_gaps")
        return try gaps.map { gap in
            let id = try XCTUnwrap(gap["id"] as? String, "known gap without id")
            XCTAssertFalse((gap["reason"] as? String ?? "").isEmpty, "\(id): known gap needs a reason")
            return id
        }
    }

    private func contractIds() throws -> [ContractId] {
        let root = try contract()
        let capabilities = try XCTUnwrap(root["capabilities"] as? [String: Any], "missing capabilities")
        var ids: [ContractId] = []
        for (capability, value) in capabilities.sorted(by: { $0.key < $1.key }) {
            let entry = try XCTUnwrap(value as? [String: Any], "\(capability) is not a map")
            let semantics = try XCTUnwrap(entry["semantics"] as? [Any], "\(capability) has no semantics")
            for item in semantics {
                if let id = item as? String {
                    ids.append(ContractId(capability: capability, id: id, afterTap: nil))
                } else if let map = item as? [String: Any], let id = map["id"] as? String {
                    ids.append(ContractId(capability: capability, id: id, afterTap: map["afterTap"] as? String))
                } else {
                    XCTFail("\(capability): unexpected semantics item \(item)")
                }
            }
        }
        return ids
    }

    /// Every namespace of `A11yID`. A namespace missing here still fails the YAML → app check, because its
    /// IDs are in the contract.
    private var appNamespaces: [(name: String, value: Any)] {
        [
            ("auth", A11yID.auth),
            ("fetching", A11yID.fetching),
            ("appInbox", A11yID.appInbox),
            ("tracking", A11yID.tracking),
            ("flushing", A11yID.flushing),
            ("anonymize", A11yID.anonymize),
            ("contentBlocks", A11yID.contentBlocks),
            ("shell", A11yID.shell),
            ("logs", A11yID.logs)
        ]
    }

    private func appIds() -> [(property: String, id: String)] {
        appNamespaces.flatMap { namespace in
            Mirror(reflecting: namespace.value).children.compactMap { child -> (String, String)? in
                guard let id = child.value as? String else { return nil }
                return ("\(namespace.name).\(child.label ?? "?")", id)
            }
        }
    }

    func testContractIsWellFormed() throws {
        let ids = try contractIds()
        XCTAssertFalse(ids.isEmpty)

        let duplicates = Dictionary(grouping: ids, by: \.id).filter { $0.value.count > 1 }.keys.sorted()
        XCTAssertEqual(duplicates, [], "IDs listed more than once in the contract")

        let badFormat = ids.map(\.id).filter { id in
            Self.idFormat.firstMatch(in: id, range: NSRange(id.startIndex..., in: id)) == nil
        }
        XCTAssertEqual(badFormat, [], "IDs not in lower_snake_case with a prefix")

        let known = Set(ids.map(\.id))
        let danglingAfterTap = ids.compactMap { entry -> String? in
            guard let afterTap = entry.afterTap, !known.contains(afterTap) else { return nil }
            return "\(entry.id) afterTap \(afterTap)"
        }
        XCTAssertEqual(danglingAfterTap, [], "afterTap must point to an ID in the contract")
    }

    func testEveryContractIdExistsInAppUnlessKnownGap() throws {
        let app = Set(appIds().map(\.id))
        let gaps = Set(try knownGaps())
        let missing = try contractIds()
            .filter { !app.contains($0.id) && !gaps.contains($0.id) }
            .map { "\($0.capability): \($0.id)" }
        XCTAssertEqual(missing, [], "Contract IDs missing from A11yID (renamed or removed?)")
    }

    func testKnownGapsAreStillGaps() throws {
        let app = Set(appIds().map(\.id))
        let contract = Set(try contractIds().map(\.id))
        for gap in try knownGaps() {
            XCTAssertTrue(contract.contains(gap), "\(gap): known gap must stay listed in a capability")
            XCTAssertFalse(app.contains(gap), "\(gap): A11yID now has this ID, remove it from known_gaps")
        }
    }

    func testEveryAppIdIsInContract() throws {
        let contract = Set(try contractIds().map(\.id))
        let missing = appIds().filter { !contract.contains($0.id) }.map { "\($0.property) = \($0.id)" }
        XCTAssertEqual(missing, [], "A11yID values missing from automation_contract.yaml")
    }

    func testAppIdsAreUnique() {
        let duplicates = Dictionary(grouping: appIds(), by: \.id)
            .filter { $0.value.count > 1 }
            .map { "\($0.key): \($0.value.map(\.property).sorted().joined(separator: ", "))" }
            .sorted()
        XCTAssertEqual(duplicates, [], "One ID used by several A11yID properties")
    }

    func testEveryNamespaceIsEnumerable() throws {
        for namespace in appNamespaces {
            let count = Mirror(reflecting: namespace.value).children.filter { $0.value is String }.count
            XCTAssertGreaterThan(count, 0, "A11yID.\(namespace.name) has no stored IDs; use `let`, not `static let`")
        }
        XCTAssertEqual(appIds().count + (try knownGaps().count), try contractIds().count)
    }

    func testPlaceholderHeightIdFormat() {
        XCTAssertEqual(A11yID.contentBlocks.placeholderHeight("example_top"), "lbl_cb_height_example_top")
    }
}
