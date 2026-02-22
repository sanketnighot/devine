import AVFoundation
import Photos
import SwiftUI
import UIKit

struct MirrorCheckinSheet: View {
    @ObservedObject var model: DevineAppModel
    var onOpenTimeline: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTags: Set<String> = []
    @State private var note: String = ""
    @State private var sheetHeight: CGFloat = 520

    @State private var selectedPreviewImage: UIImage?
    @State private var selectedAssetLocalIdentifier: String?
    @State private var selectedSource: MirrorPhotoSource?
    @State private var selectedPhotoCapturedAt: Date?

    @State private var showImageSourcePicker = false
    @State private var showPhotoPicker = false
    @State private var showCameraCapture = false
    @State private var isSavingImage = false

    @State private var cameraPermissionAlert = false
    @State private var photoPermissionAlert = false
    @State private var inlineError: String?

    private let tags = ["Puffy eyes", "Low energy", "Good sleep", "High stress", "Hydrated"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Add image (optional)") {
                    if let selectedPreviewImage {
                        VStack(alignment: .leading, spacing: 10) {
                            Image(uiImage: selectedPreviewImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            if let selectedSource {
                                Text(selectedSource == .camera ? "Source: Camera" : "Source: Photos")
                                    .font(.footnote)
                                    .foregroundStyle(DevineTheme.Colors.textSecondary)
                            }
                        }
                    }

                    HStack {
                        Button(selectedAssetLocalIdentifier == nil ? "Add image" : "Replace image") {
                            showImageSourcePicker = true
                        }

                        if selectedAssetLocalIdentifier != nil {
                            Button("Remove", role: .destructive) {
                                selectedPreviewImage = nil
                                selectedAssetLocalIdentifier = nil
                                selectedSource = nil
                                selectedPhotoCapturedAt = nil
                            }
                        }
                    }
                    .disabled(isSavingImage)
                }

                Section("How are you feeling today?") {
                    ForEach(tags, id: \.self) { tag in
                        Button {
                            if selectedTags.contains(tag) {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                        } label: {
                            HStack {
                                Text(tag)
                                Spacer()
                                if selectedTags.contains(tag) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }

                Section("Optional note") {
                    TextField("What changed today?", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }

                if let inlineError {
                    Section {
                        Text(inlineError)
                            .font(.footnote)
                            .foregroundStyle(DevineTheme.Colors.errorAccent)
                    }
                }

                Section {
                    Text("Private by default. Your check-in is used only to adapt your plan.")
                        .font(.footnote)
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(DevineTheme.Colors.bgPrimary)
            .foregroundStyle(DevineTheme.Colors.textPrimary)
            .navigationTitle("Mirror check-in")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSavingImage ? "Saving..." : "Save") {
                        saveCheckin()
                    }
                    .disabled(isSavingImage)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onMeasuredHeight { measured in
            let target = min(max(measured + 20, 460), 760)
            if abs(target - sheetHeight) > 1 {
                sheetHeight = target
            }
        }
        .presentationDetents([.height(sheetHeight), .large])
        .presentationDragIndicator(.visible)
        .tint(DevineTheme.Colors.ctaPrimary)
        .mirrorImageSourcePicker(
            isPresented: $showImageSourcePicker,
            onCamera: requestCameraAndPresentCapture,
            onPhotoLibrary: {
                Task {
                    await requestPhotosAndPresentPicker()
                }
            }
        )
        .mirrorPhotoLibraryPicker(
            isPresented: $showPhotoPicker,
            onSelection: { assetIdentifier, previewImage in
                Task {
                    await handleSelectedPhotoAsset(assetIdentifier: assetIdentifier, previewImage: previewImage)
                }
            }
        )
        .fullScreenCover(isPresented: $showCameraCapture) {
            CameraCaptureView(
                onImageCaptured: { image in
                    showCameraCapture = false
                    Task {
                        await handleCapturedImage(image)
                    }
                },
                onCancel: {
                    showCameraCapture = false
                }
            )
            .ignoresSafeArea()
        }
        .alert("Camera access needed", isPresented: $cameraPermissionAlert) {
            Button("Open Settings") {
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(settingsURL)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Allow camera access to capture mirror check-in photos.")
        }
        .alert("Photos access needed", isPresented: $photoPermissionAlert) {
            Button("Open Settings") {
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(settingsURL)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Allow Photos access to attach existing photos without creating duplicates.")
        }
    }

    @MainActor
    private func requestPhotosAndPresentPicker() async {
        inlineError = nil
        let status = await MirrorPhotoLibraryService.shared.requestReadWriteAuthorizationIfNeeded()
        switch status {
        case .authorized, .limited:
            showPhotoPicker = true
        case .denied, .restricted:
            photoPermissionAlert = true
        case .notDetermined:
            inlineError = "Photos permission state is unavailable."
        @unknown default:
            inlineError = "Photos permission state is unavailable."
        }
    }

    private func requestCameraAndPresentCapture() {
        inlineError = nil
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            inlineError = "Camera is not available on this device."
            return
        }

        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            showCameraCapture = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showCameraCapture = true
                    } else {
                        cameraPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            cameraPermissionAlert = true
        @unknown default:
            inlineError = "Camera permission state is unavailable."
        }
    }

    @MainActor
    private func handleCapturedImage(_ image: UIImage) async {
        inlineError = nil
        isSavingImage = true
        defer { isSavingImage = false }

        do {
            let identifier = try await MirrorPhotoLibraryService.shared.saveCapturedImageAndAddToAlbum(image)
            selectedAssetLocalIdentifier = identifier
            selectedSource = .camera
            selectedPhotoCapturedAt = MirrorPhotoLibraryService.shared.assetCreationDate(localIdentifier: identifier)
            selectedPreviewImage = image
        } catch {
            inlineError = error.localizedDescription
        }
    }

    @MainActor
    private func handleSelectedPhotoAsset(assetIdentifier: String?, previewImage: UIImage?) async {
        inlineError = nil
        isSavingImage = true
        defer { isSavingImage = false }

        do {
            guard let selectedIdentifier = assetIdentifier else {
                throw MirrorPhotoLibraryError.missingAssetReference
            }
            try await MirrorPhotoLibraryService.shared.addAssetToCheckinsAlbum(localIdentifier: selectedIdentifier)

            selectedAssetLocalIdentifier = selectedIdentifier
            selectedSource = .photosLibrary
            selectedPhotoCapturedAt = MirrorPhotoLibraryService.shared.assetCreationDate(localIdentifier: selectedIdentifier)
            if let previewImage {
                selectedPreviewImage = previewImage
                return
            }

            MirrorPhotoLibraryService.shared.requestImage(
                localIdentifier: selectedIdentifier,
                targetSize: CGSize(width: 720, height: 720),
                contentMode: .aspectFit
            ) { image in
                selectedPreviewImage = image
            }
        } catch {
            inlineError = error.localizedDescription
        }
    }

    private func saveCheckin() {
        let shouldOpenTimeline = selectedAssetLocalIdentifier != nil
        model.recordMirrorCheckin(
            tags: Array(selectedTags),
            note: note,
            assetLocalIdentifier: selectedAssetLocalIdentifier,
            source: selectedSource,
            photoCapturedAt: selectedPhotoCapturedAt
        )
        dismiss()
        if shouldOpenTimeline {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                onOpenTimeline?()
            }
        }
    }
}
