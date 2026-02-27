import SwiftUI

struct OnboardingBodyView: View {
    let name: String
    @Binding var heightCm: Double?
    @Binding var weightKg: Double?
    @Binding var prefersCm: Bool
    @Binding var prefersKg: Bool
    let onContinue: () -> Void

    @State private var heightText = ""
    @State private var weightText = ""
    @FocusState private var focusedField: Field?

    private enum Field { case height, weight }

    var body: some View {
        ZStack {
            DevineTheme.Colors.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: 28) {
                    // Headline
                    VStack(alignment: .leading, spacing: 8) {
                        TypewriterText(
                            text: "just a couple quick things 🌱",
                            speed: 42,
                            font: .system(size: 28, weight: .bold),
                            color: DevineTheme.Colors.textPrimary
                        )
                        Text("so i can personalize everything for you")
                            .font(.system(size: 14))
                            .foregroundColor(DevineTheme.Colors.textSecondary)
                    }

                    // Height input
                    SurfaceCard(cornerRadius: DevineTheme.Radius.lg, padding: DevineTheme.Spacing.lg) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Height", systemImage: "ruler")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(DevineTheme.Colors.textSecondary)
                                Spacer()
                                unitToggle(left: "cm", right: "ft", isCm: $prefersCm)
                            }

                            HStack(spacing: 8) {
                                TextField(prefersCm ? "e.g. 165" : "e.g. 5.4", text: $heightText)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(DevineTheme.Colors.textPrimary)
                                    .keyboardType(.decimalPad)
                                    .focused($focusedField, equals: .height)

                                Text(prefersCm ? "cm" : "ft")
                                    .font(.system(size: 16))
                                    .foregroundColor(DevineTheme.Colors.textMuted)
                            }
                        }
                    }

                    // Weight input
                    SurfaceCard(cornerRadius: DevineTheme.Radius.lg, padding: DevineTheme.Spacing.lg) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Weight", systemImage: "scalemass")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(DevineTheme.Colors.textSecondary)
                                Spacer()
                                unitToggle(left: "kg", right: "lbs", isCm: $prefersKg)
                            }

                            HStack(spacing: 8) {
                                TextField(prefersKg ? "e.g. 60" : "e.g. 132", text: $weightText)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(DevineTheme.Colors.textPrimary)
                                    .keyboardType(.decimalPad)
                                    .focused($focusedField, equals: .weight)

                                Text(prefersKg ? "kg" : "lbs")
                                    .font(.system(size: 16))
                                    .foregroundColor(DevineTheme.Colors.textMuted)
                            }
                        }
                    }

                    Text("your data never leaves your device 🔒")
                        .font(.system(size: 12))
                        .foregroundColor(DevineTheme.Colors.textMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 28)

                Spacer()

                VStack(spacing: 12) {
                    Button(action: handleContinue) {
                        Text("continue →")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: DevineTheme.Gradients.primaryCTA,
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                    }

                    Button(action: handleSkip) {
                        Text("skip this step →")
                            .font(.system(size: 14))
                            .foregroundColor(DevineTheme.Colors.textMuted)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { focusedField = nil }
    }

    private func unitToggle(left: String, right: String, isCm: Binding<Bool>) -> some View {
        HStack(spacing: 0) {
            ForEach([true, false], id: \.self) { isLeft in
                Button(action: {
                    withAnimation(DevineTheme.Motion.quick) { isCm.wrappedValue = isLeft }
                    DevineHaptic.tap.fire()
                }) {
                    Text(isLeft ? left : right)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isCm.wrappedValue == isLeft ? .white : DevineTheme.Colors.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            isCm.wrappedValue == isLeft
                            ? DevineTheme.Colors.ctaPrimary
                            : Color.clear
                        )
                        .clipShape(Capsule())
                }
            }
        }
        .background(DevineTheme.Colors.bgSecondary)
        .clipShape(Capsule())
    }

    private func handleContinue() {
        syncValues()
        DevineHaptic.tap.fire()
        onContinue()
    }

    private func handleSkip() {
        heightCm = nil
        weightKg = nil
        DevineHaptic.tap.fire()
        onContinue()
    }

    private func syncValues() {
        if let h = Double(heightText) {
            heightCm = prefersCm ? h : h * 30.48  // ft to cm
        } else {
            heightCm = nil
        }
        if let w = Double(weightText) {
            weightKg = prefersKg ? w : w / 2.20462  // lbs to kg
        } else {
            weightKg = nil
        }
    }
}
