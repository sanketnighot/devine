import AVFoundation
import Photos
import SwiftUI
import UIKit

// MARK: - Result

struct OnboardingResult {
    let goal: GlowGoal
    let didProvidePhotoEvidence: Bool
    let userProfile: UserProfile
    let generatedPlan: GeneratedPlan?
}

// MARK: - Steps

private enum OnboardingStep: Int, CaseIterable {
    case intro       // "hi, i'm devine."
    case name        // what should i call you?
    case birthday    // DOB + zodiac reveal
    case body        // height + weight (optional)
    case goal        // goal selection
    case photo       // optional selfie
    case generating  // AI plan generation
    case reveal      // plan preview

    var showsBackButton: Bool {
        switch self {
        case .intro, .generating, .reveal: return false
        default: return true
        }
    }

    var showsProgress: Bool {
        switch self {
        case .intro: return false
        default: return true
        }
    }

    var previous: OnboardingStep? {
        guard rawValue > 0 else { return nil }
        return OnboardingStep(rawValue: rawValue - 1)
    }
}

// MARK: - OnboardingFlowView

struct OnboardingFlowView: View {
    let onComplete: (OnboardingResult) -> Void

    // Step state
    @State private var step: OnboardingStep = .intro

    // User data
    @State private var name = ""
    @State private var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -20, to: .now) ?? .now
    @State private var heightCm: Double? = nil
    @State private var weightKg: Double? = nil
    @State private var prefersCm = true
    @State private var prefersKg = true
    @State private var selectedGoal: GlowGoal? = nil
    @State private var generatedPlan: GeneratedPlan? = nil

    // Photo capture state (reusing Mirror infrastructure)
    @State private var didProvidePhotoEvidence = false
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

    private var totalSteps: Int { OnboardingStep.allCases.filter { $0.showsProgress }.count }
    private var currentStepIndex: Int { max(0, step.rawValue - 1) } // offset for intro (no progress bar)

    var body: some View {
        ZStack(alignment: .top) {
            // Step content
            stepContent
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(step)

            // Progress + back button overlay (on top for non-intro steps)
            if step.showsProgress || step.showsBackButton {
                VStack(spacing: 0) {
                    HStack(spacing: 16) {
                        // Back button
                        if step.showsBackButton {
                            Button(action: goBack) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(DevineTheme.Colors.textSecondary)
                                    .frame(width: 36, height: 36)
                                    .background(DevineTheme.Colors.surfaceCard)
                                    .clipShape(Circle())
                            }
                        } else {
                            Spacer().frame(width: 36)
                        }

                        // Progress dots
                        if step.showsProgress {
                            HStack(spacing: 6) {
                                ForEach(0..<totalSteps, id: \.self) { i in
                                    Capsule()
                                        .fill(i <= currentStepIndex
                                              ? DevineTheme.Colors.ctaPrimary
                                              : DevineTheme.Colors.borderSubtle)
                                        .frame(width: i == currentStepIndex ? 20 : 6, height: 6)
                                        .animation(DevineTheme.Motion.quick, value: currentStepIndex)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }

                        Spacer().frame(width: 36)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    Spacer()
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: step)
        // Photo modifiers
        .mirrorImageSourcePicker(
            isPresented: $showImageSourcePicker,
            onCamera: requestCameraAndPresentCapture,
            onPhotoLibrary: { Task { await requestPhotosAndPresentPicker() } }
        )
        .mirrorPhotoLibraryPicker(
            isPresented: $showPhotoPicker,
            onSelection: { id, preview in
                Task { await handleSelectedPhotoAsset(assetIdentifier: id, previewImage: preview) }
            }
        )
        .fullScreenCover(isPresented: $showCameraCapture) {
            CameraCaptureView(
                onImageCaptured: { captured in
                    showCameraCapture = false
                    Task { await handleCapturedImage(captured) }
                },
                onCancel: { showCameraCapture = false }
            )
            .ignoresSafeArea()
        }
        .alert("Camera Access Needed", isPresented: $cameraPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Not Now", role: .cancel) {}
        } message: {
            Text("Enable camera access in Settings to take a check-in photo.")
        }
        .alert("Photos Access Needed", isPresented: $photoPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Not Now", role: .cancel) {}
        } message: {
            Text("Enable Photos access in Settings to choose a check-in photo.")
        }
    }

    // MARK: - Step Router

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .intro:
            OnboardingIntroView(onContinue: { advance() })

        case .name:
            OnboardingNameView(name: $name, onContinue: { advance() })
                .padding(.top, 72) // leave room for progress/back bar

        case .birthday:
            OnboardingBirthdayView(
                name: name,
                dateOfBirth: $dateOfBirth,
                onContinue: { advance() }
            )
            .padding(.top, 72)

        case .body:
            OnboardingBodyView(
                name: name,
                heightCm: $heightCm,
                weightKg: $weightKg,
                prefersCm: $prefersCm,
                prefersKg: $prefersKg,
                onContinue: { advance() }
            )
            .padding(.top, 72)

        case .goal:
            OnboardingGoalView(
                name: name,
                selectedGoal: $selectedGoal,
                onContinue: { advance() }
            )
            .padding(.top, 72)

        case .photo:
            photoStep
                .padding(.top, 72)

        case .generating:
            OnboardingGeneratingView(
                name: name,
                profile: buildProfile(),
                goal: selectedGoal ?? .faceDefinition,
                photo: selectedPreviewImage,
                onComplete: { plan in
                    generatedPlan = plan
                    advance()
                },
                onFallback: { advance() }
            )

        case .reveal:
            OnboardingRevealView(
                name: name,
                goal: selectedGoal ?? .faceDefinition,
                plan: generatedPlan,
                onComplete: finishOnboarding
            )
        }
    }

    // MARK: - Photo Step

    private var photoStep: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // Headline
                VStack(alignment: .leading, spacing: 8) {
                    TypewriterText(
                        text: "drop a quick selfie 📸",
                        speed: 42,
                        font: .system(size: 28, weight: .bold),
                        color: DevineTheme.Colors.textPrimary
                    )
                    Text("i'll use it to personalize your plan — totally private")
                        .font(.system(size: 14))
                        .foregroundColor(DevineTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)

                // Photo preview / placeholder
                ZStack {
                    if let preview = selectedPreviewImage {
                        Image(uiImage: preview)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 160, height: 160)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(DevineTheme.Colors.ctaPrimary, lineWidth: 3)
                            )
                            .overlay(alignment: .bottomTrailing) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(DevineTheme.Colors.successAccent)
                                    .background(Circle().fill(DevineTheme.Colors.bgPrimary))
                            }
                    } else {
                        Circle()
                            .fill(DevineTheme.Colors.blush.opacity(0.4))
                            .frame(width: 160, height: 160)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(DevineTheme.Colors.ctaPrimary)
                            )
                    }
                }
                .onTapGesture { showImageSourcePicker = true }

                if let error = photoInlineError {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(DevineTheme.Colors.errorAccent)
                }
            }

            Spacer()

            // CTAs
            VStack(spacing: 12) {
                if didProvidePhotoEvidence {
                    Button(action: { advance() }) {
                        Text("continue →")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(colors: DevineTheme.Gradients.primaryCTA, startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(Capsule())
                    }
                } else {
                    Button(action: { showImageSourcePicker = true }) {
                        Label("add quick check-in now", systemImage: "camera")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(colors: DevineTheme.Gradients.primaryCTA, startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(Capsule())
                    }
                }

                Button(action: { advance() }) {
                    Text("skip for now →")
                        .font(.system(size: 14))
                        .foregroundColor(DevineTheme.Colors.textMuted)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Navigation

    private func advance() {
        let next = OnboardingStep(rawValue: step.rawValue + 1) ?? step
        withAnimation(.easeInOut(duration: 0.35)) {
            step = next
        }
    }

    private func goBack() {
        guard let prev = step.previous else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            step = prev
        }
    }

    private func finishOnboarding() {
        let profile = buildProfile()
        let result = OnboardingResult(
            goal: selectedGoal ?? .faceDefinition,
            didProvidePhotoEvidence: didProvidePhotoEvidence,
            userProfile: profile,
            generatedPlan: generatedPlan
        )
        onComplete(result)
    }

    private func buildProfile() -> UserProfile {
        UserProfile(
            name: name.trimmingCharacters(in: .whitespaces).isEmpty ? "you" : name.trimmingCharacters(in: .whitespaces),
            dateOfBirth: dateOfBirth,
            heightCm: heightCm,
            weightKg: weightKg,
            prefersCentimetres: prefersCm,
            prefersKilograms: prefersKg
        )
    }

    // MARK: - Photo Handlers (Mirror infrastructure)

    private func requestPhotosAndPresentPicker() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await MainActor.run {
            switch status {
            case .authorized, .limited: showPhotoPicker = true
            case .denied, .restricted: photoPermissionAlert = true
            case .notDetermined: showPhotoPicker = true
            @unknown default: break
            }
        }
    }

    private func requestCameraAndPresentCapture() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized: showCameraCapture = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted { showCameraCapture = true }
                    else { cameraPermissionAlert = true }
                }
            }
        case .denied, .restricted: cameraPermissionAlert = true
        @unknown default: break
        }
    }

    @MainActor
    private func handleCapturedImage(_ image: UIImage) async {
        isSavingImage = true
        photoInlineError = nil
        do {
            let identifier = try await MirrorPhotoLibraryService.shared.saveCapturedImageAndAddToAlbum(image)
            selectedPreviewImage = image
            selectedAssetLocalIdentifier = identifier
            selectedSource = .camera
            selectedPhotoCapturedAt = .now
            didProvidePhotoEvidence = true
        } catch {
            photoInlineError = "Couldn't save photo. Try again."
        }
        isSavingImage = false
    }

    @MainActor
    private func handleSelectedPhotoAsset(assetIdentifier: String?, previewImage: UIImage?) async {
        guard let assetIdentifier else { return }
        isSavingImage = true
        photoInlineError = nil
        do {
            try await MirrorPhotoLibraryService.shared.addAssetToCheckinsAlbum(localIdentifier: assetIdentifier)
            selectedPreviewImage = previewImage
            selectedAssetLocalIdentifier = assetIdentifier
            selectedSource = .photosLibrary
            selectedPhotoCapturedAt = nil
            didProvidePhotoEvidence = true
        } catch {
            photoInlineError = "Couldn't add photo. Try again."
        }
        isSavingImage = false
    }
}
