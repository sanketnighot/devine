import Foundation
import CryptoKit

extension UUID {
    /// Creates a deterministic (version 5) UUID from a namespace UUID and a name string.
    /// Uses SHA-1 per RFC 4122 §4.3.  Safe for ID generation despite SHA-1's crypto weakness.
    static func v5(namespace: UUID, name: String) -> UUID {
        var bytes = withUnsafeBytes(of: namespace.uuid) { Array($0) }
        bytes += Array(name.utf8)
        var digest = Array(Insecure.SHA1.hash(data: Data(bytes)).prefix(16))

        // Set version to 5 (0101) in high nibble of byte 6
        digest[6] = (digest[6] & 0x0F) | 0x50
        // Set RFC 4122 variant (10xx) in high bits of byte 8
        digest[8] = (digest[8] & 0x3F) | 0x80

        return UUID(uuid: (
            digest[0],  digest[1],  digest[2],  digest[3],
            digest[4],  digest[5],  digest[6],  digest[7],
            digest[8],  digest[9],  digest[10], digest[11],
            digest[12], digest[13], digest[14], digest[15]
        ))
    }

    /// Creates a stable action ID from a day number, action index within that day, and title.
    /// Using this at parse time ensures that re-fetching the same Gemini plan responses
    /// doesn't change action UUIDs and invalidate stored completion state.
    static func deterministicAction(dayNumber: Int, actionIndex: Int, title: String) -> UUID {
        // Project-specific namespace prevents collision with generic v5 UUIDs elsewhere.
        let namespace = UUID(uuidString: "B6A0F4C2-1D3E-5F89-AB12-CD34EF567890")!
        return v5(namespace: namespace, name: "\(dayNumber):\(actionIndex):\(title)")
    }
}
