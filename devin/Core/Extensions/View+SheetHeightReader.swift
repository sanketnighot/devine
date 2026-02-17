import SwiftUI

private struct SheetContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let next = nextValue()
        value = max(value, next)
    }
}

extension View {
    func onMeasuredHeight(_ onChange: @escaping (CGFloat) -> Void) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: SheetContentHeightPreferenceKey.self, value: proxy.size.height)
            }
        )
        .onPreferenceChange(SheetContentHeightPreferenceKey.self, perform: onChange)
    }
}
