import PhotosUI
import SwiftUI
import UIKit

struct MirrorPhotoLibraryPicker: UIViewControllerRepresentable {
    let onSelection: (_ assetIdentifier: String?, _ previewImage: UIImage?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelection: onSelection)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let onSelection: (_ assetIdentifier: String?, _ previewImage: UIImage?) -> Void

        init(onSelection: @escaping (_ assetIdentifier: String?, _ previewImage: UIImage?) -> Void) {
            self.onSelection = onSelection
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first else {
                onSelection(nil, nil)
                return
            }

            let assetIdentifier = result.assetIdentifier
            let provider = result.itemProvider

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { object, _ in
                    let image = object as? UIImage
                    DispatchQueue.main.async {
                        self.onSelection(assetIdentifier, image)
                    }
                }
                return
            }

            DispatchQueue.main.async {
                self.onSelection(assetIdentifier, nil)
            }
        }
    }
}

struct MirrorPhotoLibraryPickerModifier: ViewModifier {
    @Binding var isPresented: Bool
    let onSelection: (_ assetIdentifier: String?, _ previewImage: UIImage?) -> Void

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            MirrorPhotoLibraryPicker { assetIdentifier, previewImage in
                isPresented = false
                onSelection(assetIdentifier, previewImage)
            }
        }
    }
}

extension View {
    func mirrorPhotoLibraryPicker(
        isPresented: Binding<Bool>,
        onSelection: @escaping (_ assetIdentifier: String?, _ previewImage: UIImage?) -> Void
    ) -> some View {
        modifier(
            MirrorPhotoLibraryPickerModifier(
                isPresented: isPresented,
                onSelection: onSelection
            )
        )
    }
}
