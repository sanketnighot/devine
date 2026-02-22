import SwiftUI

struct MirrorImageSourcePickerModifier: ViewModifier {
    @Binding var isPresented: Bool
    let onCamera: () -> Void
    let onPhotoLibrary: () -> Void

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                "Add image",
                isPresented: $isPresented,
                titleVisibility: .visible
            ) {
                Button("Take photo") {
                    onCamera()
                }
                Button("Choose from Photos") {
                    onPhotoLibrary()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Choose how you want to add your mirror check-in photo.")
            }
    }
}

extension View {
    func mirrorImageSourcePicker(
        isPresented: Binding<Bool>,
        onCamera: @escaping () -> Void,
        onPhotoLibrary: @escaping () -> Void
    ) -> some View {
        modifier(
            MirrorImageSourcePickerModifier(
                isPresented: isPresented,
                onCamera: onCamera,
                onPhotoLibrary: onPhotoLibrary
            )
        )
    }
}
