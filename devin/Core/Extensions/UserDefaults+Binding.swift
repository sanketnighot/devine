import SwiftUI

extension UserDefaults {
    func binding(forKey key: String) -> Binding<Bool> {
        Binding(
            get: { self.bool(forKey: key) },
            set: { self.set($0, forKey: key) }
        )
    }
}
