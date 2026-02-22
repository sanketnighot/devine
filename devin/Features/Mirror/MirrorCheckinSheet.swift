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
            ScrollView {
                VStack(alignment: .leading, spacing: DevineTheme.Spacing.xl) {
                    imageSection
                    moodSection
                    noteSection

                    if let inlineError {
                        Text(inlineError)
                            .font(.caption)
                            .foregroundStyle(DevineTheme.Colors.errorAccent)
                            .padding(.horizontal, DevineTheme.Spacing.xs)
                    }

                    privacyNote
                }
                .padding(.horizontal, DevineTheme.Spacing.lg)
                .padding(.top, DevineTheme.Spacing.lg)
                .padding(.bottom, DevineTheme.Spacing.xxxl)
            }
            .background(
                LinearGradient(
                    colors: DevineTheme.Gradients.screenBackground,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .foregroundStyle(DevineTheme.Colors.textPrimary)
            .navigationTitle("Mirror check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveCheckin()
                    } label: {
                        Text(isSavingImage ? "Saving..." : "Save")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(DevineTheme.Colors.ctaPrimary)
                    }
                    .disabled(isSavingImage)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.subheadline)
                            .foregroundStyle(DevineTheme.Colors.textSecondary)
                    }
                }
            }
        }
        .presentationDetents([.large])
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
        .onAppear {
            DevineHaptic.sheetPresent.fire()
        }
    }

    // MARK: - Image Section

    private var imageSection: some View {
        VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
            sectionLabel("Photo (optional)")

            if let selectedPreviewImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: selectedPreviewImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: DevineTheme.Radius.xl, style: .continuous))

                    if let selectedSource {
                        Text(selectedSource == .camera ? "Camera" : "Photos")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color.black.opacity(0.5))
                            )
                            .padding(DevineTheme.Spacing.sm)
                    }
                }

                HStack(spacing: DevineTheme.Spacing.sm) {
                    Button {
                        DevineHaptic.tap.fire()
                        showImageSourcePicker = true
                    } label: {
                        Label("Replace", systemImage: "arrow.triangle.2.circlepath")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DevineTheme.Colors.ctaPrimary)
                            .padding(.horizontal, DevineTheme.Spacing.md)
                            .padding(.vertical, DevineTheme.Spacing.sm)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(DevineTheme.Colors.ctaPrimary.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(isSavingImage)

                    Button {
                        DevineHaptic.tap.fire()
                        self.selectedPreviewImage = nil
                        self.selectedAssetLocalIdentifier = nil
                        self.selectedSource = nil
                        self.selectedPhotoCapturedAt = nil
                    } label: {
                        Label("Remove", systemImage: "trash")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DevineTheme.Colors.errorAccent)
                            .padding(.horizontal, DevineTheme.Spacing.md)
                            .padding(.vertical, DevineTheme.Spacing.sm)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(DevineTheme.Colors.errorAccent.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(isSavingImage)
                }
            } else {
                Button {
                    DevineHaptic.tap.fire()
                    showImageSourcePicker = true
                } label: {
                    VStack(spacing: DevineTheme.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            DevineTheme.Colors.ctaPrimary.opacity(0.1),
                                            DevineTheme.Colors.ctaSecondary.opacity(0.08)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)

                            Image(systemName: "camera.viewfinder")
                                .font(.title3)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: DevineTheme.Gradients.primaryCTA,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                        Text("Add a photo")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DevineTheme.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .background(
                        RoundedRectangle(cornerRadius: DevineTheme.Radius.xl, style: .continuous)
                            .fill(DevineTheme.Colors.surfaceCard)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DevineTheme.Radius.xl, style: .continuous)
                            .stroke(DevineTheme.Colors.borderSubtle, style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                    )
                }
                .buttonStyle(.plain)
                .disabled(isSavingImage)
            }
        }
    }

    // MARK: - Mood Section

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
            sectionLabel("How are you feeling?")

            MoodChipGrid(tags: tags, selectedTags: $selectedTags)
        }
    }

    // MARK: - Note Section

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
            sectionLabel("Note (optional)")

            TextField("What changed today?", text: $note, axis: .vertical)
                .lineLimit(2...4)
                .font(.body)
                .padding(DevineTheme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: DevineTheme.Radius.lg, style: .continuous)
                        .fill(DevineTheme.Colors.surfaceCard)
                )
        }
    }

    // MARK: - Privacy Note

    private var privacyNote: some View {
        HStack(spacing: DevineTheme.Spacing.sm) {
            Image(systemName: "lock.shield")
                .font(.caption2)
                .foregroundStyle(DevineTheme.Colors.textMuted)

            Text("Private by default. Your check-in adapts your plan — nothing leaves this device.")
                .font(.caption2)
                .foregroundStyle(DevineTheme.Colors.textMuted)
        }
        .padding(.top, DevineTheme.Spacing.sm)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption, design: .rounded, weight: .bold))
            .foregroundStyle(DevineTheme.Colors.textMuted)
            .textCase(.uppercase)
            .tracking(0.5)
    }

    // MARK: - Photo Logic

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
        DevineHaptic.actionComplete.fire()
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
