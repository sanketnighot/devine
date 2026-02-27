import SwiftUI

struct OnboardingNameView: View {
    @Binding var name: String
    let onContinue: () -> Void

    @FocusState private var isFocused: Bool
    @State private var showLoveMessage = false
    @State private var isAdvancing = false

    var isValid: Bool { name.trimmingCharacters(in: .whitespaces).count >= 2 }

    var body: some View {
        ZStack {
            DevineTheme.Colors.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: 32) {
                    // Headline
                    VStack(alignment: .leading, spacing: 8) {
                        TypewriterText(
                            text: "first things first —",
                            speed: 40,
                            font: .system(size: 14, weight: .medium),
                            color: DevineTheme.Colors.ctaPrimary
                        )
                        TypewriterText(
                            text: "what should i\ncall you?",
                            speed: 38,
                            font: .system(size: 34, weight: .bold),
                            color: DevineTheme.Colors.textPrimary
                        )
                    }

                    // Name input — underline style
                    VStack(spacing: 8) {
                        TextField("", text: $name)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(DevineTheme.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                            .focused($isFocused)
                            .submitLabel(.done)
                            .onSubmit { if isValid { handleContinue() } }
                            .placeholder(when: name.isEmpty) {
                                Text("your name here")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(DevineTheme.Colors.textMuted)
                                    .multilineTextAlignment(.center)
                            }

                        Rectangle()
                            .fill(
                                isFocused
                                ? LinearGradient(colors: DevineTheme.Gradients.primaryCTA, startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [DevineTheme.Colors.borderSubtle], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(height: 2)
                            .animation(DevineTheme.Motion.quick, value: isFocused)
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal, 32)

                // Love message after they type
                if showLoveMessage {
                    Text("love that name, \(name.trimmingCharacters(in: .whitespaces)) 🌟")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(DevineTheme.Colors.ctaPrimary)
                        .padding(.top, 20)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                }

                Spacer()

                // CTA
                Button(action: handleContinue) {
                    Text("that's me →")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(isValid ? .white : DevineTheme.Colors.textMuted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            isValid
                            ? LinearGradient(colors: DevineTheme.Gradients.primaryCTA, startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [DevineTheme.Colors.surfaceCard], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                }
                .disabled(!isValid || isAdvancing)
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }

        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                isFocused = true
            }
        }
    }

    private func handleContinue() {
        guard isValid, !isAdvancing else { return }
        isAdvancing = true
        isFocused = false
        DevineHaptic.actionComplete.fire()

        withAnimation(DevineTheme.Motion.celebration) {
            showLoveMessage = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            onContinue()
        }
    }
}

// MARK: - Placeholder helper

private extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: .center) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
