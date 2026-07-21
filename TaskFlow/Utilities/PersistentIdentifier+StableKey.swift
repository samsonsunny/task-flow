import Foundation
import SwiftData

extension PersistentIdentifier {
    /// A stable string representation that survives app relaunches.
    /// Uses Codable serialization — unlike `hashValue` or `String(describing:)`,
    /// this is deterministic and tied to the underlying storage.
    var stableKey: String {
        let data = try! JSONEncoder().encode(self)
        return data.base64EncodedString()
    }

    init?(stableKey: String) {
        guard let data = Data(base64Encoded: stableKey) else { return nil }
        self = try! JSONDecoder().decode(PersistentIdentifier.self, from: data)
    }
}
