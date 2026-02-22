import AVFoundation
import Photos
import SwiftUI
import UIKit

struct OnboardingResult {
    let goal: GlowGoal
    let didProvidePhotoEvidence: Bool
}

private enum OnboardingStep: Int, CaseIterable {
    case welcome
    case goal
    case photo
    case preview
}

struct OnboardingFlowView: View {
    let onComplete: (OnboardingResult) -> Void

    @State private var step: OnboardingStep = .welcome
    @State private var selectedGoal: GlowGoal?
    @State private var didProvidePhotoEvidence = false

    // Photo capture state
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
    @State private var photoInlineError: String?

    var body: some View {
        VStack(spacing: DevineTheme.Spacing.xxl) {
            header
            content
            Spacer()
            controls
        }
        .padding(DevineTheme.Spacing.xxl)
        .frame(maxWidth: 580)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: gradientForStep,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(DevineTheme.Motion.standard, value: step)
        )
        .foregroundStyle(DevineTheme.Colors.textPrimary)
        .mirrorImageSourcePicker(
            isPresented: $showImageSourcePicker,
            onCamera: requestCameraAndPresentCapture,
            onPhotoLibrary: {
                Task { await requestPhotosAndPresentPicker() }
            }
        )
        .mirrorPhotoLibraryPicker(
            isPresented: $showPhotoPicker,
            onSelection: { assetIdentifier, previewImage in
                Task { await handleSelectedPhotoAsset(assetIdentifier: assetIdentifier, previewImage: previewImage) }
            }
        )
        .fullScreenCover(isPresented: $showCameraCapture) {
            CameraCaptureView(
                onImageCaptured: { image in
                    showCameraCapture = false
                    Task { await handleCapturedImage(image) }
                },
                onCancel: { showCameraCapture = false }
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
            Text("Allow camera access to capture your check-in photo.")
        }
        .alert("Photos access needed", isPresented: $photoPermissionAlert) {
            Button("Open Settings") {
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(settingsURL)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Allow Photos access to choose an existing photo.")
        }
    }

    private var gradientForStep: [Color] {
        switch step {
        case .welcome:
            DevineTheme.Gradients.screenBackground
        case .goal:
            [DevineTheme.Colors.bgPrimary, DevineTheme.Colors.blush.opacity(0.3)]
        case .photo:
            [DevineTheme.Colors.bgPrimary, DevineTheme.Colors.peach.opacity(0.3)]
        case .preview:
            [DevineTheme.Colors.bgPrimary, DevineTheme.Colors.bgSecondary]
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
            HStack {
                if step != .welcome {
                    Button {
                        DevineHaptic.tap.fire()
                        withAnimation(DevineTheme.Motion.standard) {
                            if let previous = OnboardingStep(rawValue: step.rawValue - 1) {
                                step = previous
                            }
                        }
                    } label: {
                        HStack(spacing: DevineTheme.Spacing.xs) {
                            Image(systemName: "chevron.left")
                                .font(.caption.weight(.bold))
                            Text("Back")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Text("devine")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(DevineTheme.Colors.ctaPrimary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(DevineTheme.Colors.ringTrack)

                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: DevineTheme.Gradients.primaryCTA,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progressFraction)
                        .animation(DevineTheme.Motion.expressive, value: step)
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var progressFraction: CGFloat {
        CGFloat(step.rawValue + 1) / CGFloat(OnboardingStep.allCases.count)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:
            welcomeContent
        case .goal:
            goalContent
        case .photo:
            photoContent
        case .preview:
            previewContent
        }
    }

    // MARK: Welcome

    private var welcomeContent: some View {
        VStack(alignment: .leading, spacing: DevineTheme.Spacing.xl) {
            VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
                Text("Glow up,\nbut make it real.")
                    .font(.largeTitle.bold())
                    .lineSpacing(2)

                Text("A plan that evolves with you through small, sustainable daily actions.")
                    .font(.body)
                    .foregroundStyle(DevineTheme.Colors.textSecondary)
                    .lineSpacing(3)
            }

            VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
                promiseRow(icon: "camera.viewfinder", text: "Photo is optional")
                promiseRow(icon: "lock.shield", text: "Private by default")
                promiseRow(icon: "eye.slash", text: "No public rankings")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func promiseRow(icon: String, text: String) -> some View {
        HStack(spacing: DevineTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.body.weight(.medium))
                .foregroundStyle(DevineTheme.Colors.successAccent)
                .frame(width: 24)

            Text(text)
                .font(.subheadline.weight(.medium))
        }
    }

    // MARK: Goal

    private var goalContent: some View {
        VStack(alignment: .leading, spacing: DevineTheme.Spacing.lg) {
            Text("What do you want\nto upgrade first?")
                .font(.title2.bold())
                .lineSpacing(2)

            VStack(spacing: DevineTheme.Spacing.sm) {
                ForEach(GlowGoal.allCases) { goal in
                    goalCard(goal)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func goalCard(_ goal: GlowGoal) -> some View {
        let isSelected = selectedGoal == goal

        return Button {
            DevineHaptic.tap.fire()
            withAnimation(DevineTheme.Motion.quick) {
                selectedGoal = goal
            }
        } label: {
            HStack(spacing: DevineTheme.Spacing.md) {
                Image(systemName: goal.iconName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(isSelected ? goal.accentColor : DevineTheme.Colors.textMuted)
                    .frame(width: 28)

                Text(goal.displayName)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(DevineTheme.Colors.textPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(goal.accentColor)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(DevineTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DevineTheme.Radius.lg, style: .continuous)
                    .fill(isSelected ? goal.accentColor.opacity(0.1) : DevineTheme.Colors.surfaceCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DevineTheme.Radius.lg, style: .continuous)
                    .stroke(isSelected ? goal.accentColor.opacity(0.4) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Photo

    private var photoContent: some View {
        VStack(alignment: .leading, spacing: DevineTheme.Spacing.xl) {
            VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
                Text("Optional check-in photo")
                    .font(.title2.bold())

                Text("A private photo can unlock a verified Glow Score. You can always add this later.")
                    .font(.body)
                    .foregroundStyle(DevineTheme.Colors.textSecondary)
                    .lineSpacing(3)
            }

            // Photo preview or illustration
            SurfaceCard {
                VStack(spacing: DevineTheme.Spacing.lg) {
                    if let selectedPreviewImage {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: selectedPreviewImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(DevineTheme.Colors.ctaPrimary.opacity(0.3), lineWidth: 2)
                                )

                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(DevineTheme.Colors.successAccent)
                                .background(
                                    Circle()
                                        .fill(DevineTheme.Colors.bgPrimary)
                                        .padding(-2)
                                )
                                .offset(x: 4, y: -4)
                        }

                        Text("Looking great! Tap to retake.")
                            .font(.caption)
                            .foregroundStyle(DevineTheme.Colors.textMuted)
                    } else {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            DevineTheme.Colors.ctaPrimary.opacity(0.1),
                                            DevineTheme.Colors.ctaSecondary.opacity(0.08),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 72, height: 72)

                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 28))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: DevineTheme.Gradients.primaryCTA,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                        Text("Stored only on your device")
                            .font(.caption)
                            .foregroundStyle(DevineTheme.Colors.textMuted)
                    }
                }
                .frame(maxWidth: .infinity)
                .onTapGesture {
                    if selectedPreviewImage != nil {
                        showImageSourcePicker = true
                    }
                }
            }

            if let photoInlineError {
                Text(photoInlineError)
                    .font(.caption)
                    .foregroundStyle(DevineTheme.Colors.errorAccent)
            }

            VStack(spacing: DevineTheme.Spacing.md) {
                gradientButton(label: selectedPreviewImage != nil ? "Continue" : "Add quick check-in now", disabled: isSavingImage) {
                    DevineHaptic.tap.fire()
                    if selectedPreviewImage != nil {
                        withAnimation(DevineTheme.Motion.standard) { step = .preview }
                    } else {
                        showImageSourcePicker = true
                    }
                }

                Button {
                    DevineHaptic.tap.fire()
                    didProvidePhotoEvidence = false
                    withAnimation(DevineTheme.Motion.standard) {
                        step = .preview
                    }
                } label: {
                    Text("Skip for now")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Preview

    private var previewContent: some View {
        VStack(alignment: .leading, spacing: DevineTheme.Spacing.xl) {
            Text("Your plan is ready")
                .font(.title2.bold())

            if didProvidePhotoEvidence {
                SurfaceCard {
                    HStack(spacing: DevineTheme.Spacing.lg) {
                        ZStack {
                            Circle()
                                .fill(DevineTheme.Colors.successAccent.opacity(0.12))
                                .frame(width: 52, height: 52)

                            Image(systemName: "checkmark.shield.fill")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(DevineTheme.Colors.successAccent)
                        }

                        VStack(alignment: .leading, spacing: DevineTheme.Spacing.xs) {
                            Text("Evidence received")
                                .font(.system(.subheadline, design: .rounded, weight: .bold))

                            Text("Your Glow Score will appear after the first analysis. No fake numbers.")
                                .font(.caption)
                                .foregroundStyle(DevineTheme.Colors.textSecondary)
                                .lineSpacing(2)
                        }

                        Spacer()
                    }
                }
            } else {
                GradientCard(colors: DevineTheme.Gradients.heroCard, showGlow: true) {
                    VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
                        HStack(spacing: DevineTheme.Spacing.md) {
                            ProgressRing(
                                value: 0,
                                maxValue: 100,
                                size: 48,
                                lineWidth: 6,
                                trackColor: Color.white.opacity(0.2),
                                showLabel: false,
                                showGlow: false
                            )

                            VStack(alignment: .leading, spacing: DevineTheme.Spacing.xs) {
                                Text("No score yet")
                                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                                    .foregroundStyle(DevineTheme.Colors.textOnGradient)

                                Text("Add a mirror check-in anytime to unlock your verified Glow Score.")
                                    .font(.caption)
                                    .foregroundStyle(DevineTheme.Colors.textOnGradient.opacity(0.8))
                                    .lineSpacing(2)
                            }
                        }
                    }
                }
            }

            if let goal = selectedGoal {
                SurfaceCard {
                    HStack(spacing: DevineTheme.Spacing.md) {
                        GoalBadge(goal: goal)

                        VStack(alignment: .leading, spacing: DevineTheme.Spacing.xs) {
                            Text("3 daily actions")
                                .font(.system(.subheadline, design: .rounded, weight: .bold))

                            Text("Small, sustainable steps adapted to your goal.")
                                .font(.caption)
                                .foregroundStyle(DevineTheme.Colors.textSecondary)
                        }

                        Spacer()
                    }
                }
            }

            Text("Next: choose your plan to unlock the full adaptive experience.")
                .font(.caption)
                .foregroundStyle(DevineTheme.Colors.textMuted)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Controls

    private var controls: some View {
        Group {
            switch step {
            case .welcome:
                gradientButton(label: "Start your glow up") {
                    DevineHaptic.tap.fire()
                    withAnimation(DevineTheme.Motion.standard) {
                        step = .goal
                    }
                }

            case .goal:
                gradientButton(label: "Continue", disabled: selectedGoal == nil) {
                    DevineHaptic.tap.fire()
                    withAnimation(DevineTheme.Motion.standard) {
                        step = .photo
                    }
                }

            case .photo:
                EmptyView()

            case .preview:
                gradientButton(label: "Let's go") {
                    DevineHaptic.tap.fire()
                    onComplete(
                        OnboardingResult(
                            goal: selectedGoal ?? .faceDefinition,
                            didProvidePhotoEvidence: didProvidePhotoEvidence
                        )
                    )
                }
            }
        }
    }

    // MARK: - Gradient Button Helper

    // MARK: - Photo Logic

    @MainActor
    private func requestPhotosAndPresentPicker() async {
        photoInlineError = nil
        let status = await MirrorPhotoLibraryService.shared.requestReadWriteAuthorizationIfNeeded()
        switch status {
        case .authorized, .limited:
            showPhotoPicker = true
        case .denied, .restricted:
            photoPermissionAlert = true
        case .notDetermined:
            photoInlineError = "Photos permission state is unavailable."
        @unknown default:
            photoInlineError = "Photos permission state is unavailable."
        }
    }

    private func requestCameraAndPresentCapture() {
        photoInlineError = nil
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            photoInlineError = "Camera is not available on this device."
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
            photoInlineError = "Camera permission state is unavailable."
        }
    }

    @MainActor
    private func handleCapturedImage(_ image: UIImage) async {
        photoInlineError = nil
        isSavingImage = true
        defer { isSavingImage = false }

        do {
            let identifier = try await MirrorPhotoLibraryService.shared.saveCapturedImageAndAddToAlbum(image)
            selectedAssetLocalIdentifier = identifier
            selectedSource = .camera
            selectedPhotoCapturedAt = MirrorPhotoLibraryService.shared.assetCreationDate(localIdentifier: identifier)
            selectedPreviewImage = image
            didProvidePhotoEvidence = true
        } catch {
            photoInlineError = error.localizedDescription
        }
    }

    @MainActor
    private func handleSelectedPhotoAsset(assetIdentifier: String?, previewImage: UIImage?) async {
        photoInlineError = nil
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
            didProvidePhotoEvidence = true

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
            photoInlineError = error.localizedDescription
        }
    }

    // MARK: - Gradient Button Helper

    private func gradientButton(label: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.headline)
                .foregroundStyle(DevineTheme.Colors.textOnGradient)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DevineTheme.Spacing.lg)
                .background(
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: DevineTheme.Gradients.primaryCTA,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: DevineTheme.Gradients.primaryCTA.first?.opacity(0.3) ?? .clear, radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .opacity(disabled ? 0.4 : 1)
        .disabled(disabled)
    }
}
