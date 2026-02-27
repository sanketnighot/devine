import SwiftUI

struct OnboardingBirthdayView: View {
    let name: String
    @Binding var dateOfBirth: Date
    let onContinue: () -> Void

    @State private var showZodiac = false
    @State private var lastDate: Date = Calendar.current.date(byAdding: .year, value: -20, to: .now) ?? .now

    private var zodiac: ZodiacSign { ZodiacSign.from(date: dateOfBirth) }

    private static var dateRange: ClosedRange<Date> {
        let cal = Calendar.current
        let min = cal.date(byAdding: .year, value: -50, to: .now)!
        let max = cal.date(byAdding: .year, value: -13, to: .now)!
        return min...max
    }

    var body: some View {
        ZStack {
            DevineTheme.Colors.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: 28) {
                    // Headline
                    VStack(alignment: .leading, spacing: 8) {
                        TypewriterText(
                            text: "\(name), when's your birthday? 🎂",
                            speed: 45,
                            font: .system(size: 28, weight: .bold),
                            color: DevineTheme.Colors.textPrimary
                        )
                        Text("i want to know your cosmic energy")
                            .font(.system(size: 14))
                            .foregroundColor(DevineTheme.Colors.textSecondary)
                    }

                    // Date picker
                    DatePicker(
                        "",
                        selection: $dateOfBirth,
                        in: Self.dateRange,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .onChange(of: dateOfBirth) { _, newVal in
                        if !showZodiac || ZodiacSign.from(date: newVal) != ZodiacSign.from(date: lastDate) {
                            lastDate = newVal
                            withAnimation(DevineTheme.Motion.expressive) {
                                showZodiac = true
                            }
                            DevineHaptic.scoreUpdate.fire()
                        }
                    }

                    // Zodiac card
                    if showZodiac {
                        zodiacCard
                            .transition(.scale(scale: 0.85).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 28)

                Spacer()

                Button(action: {
                    DevineHaptic.tap.fire()
                    onContinue()
                }) {
                    Text("that's my birthday →")
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
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }

        }
        .onAppear {
            // Set default to 20 years ago so the wheel feels relevant
            dateOfBirth = Calendar.current.date(byAdding: .year, value: -20, to: .now) ?? .now
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(DevineTheme.Motion.expressive) { showZodiac = true }
            }
        }
    }

    private var zodiacCard: some View {
        GradientCard(
            colors: [DevineTheme.Colors.ctaPrimary.opacity(0.15), DevineTheme.Colors.ctaSecondary.opacity(0.1)],
            cornerRadius: DevineTheme.Radius.xl
        ) {
            HStack(spacing: 16) {
                Text(zodiac.emoji)
                    .font(.system(size: 40))

                VStack(alignment: .leading, spacing: 4) {
                    Text(zodiac.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(DevineTheme.Colors.textPrimary)

                    Text("a typical \(zodiac.rawValue) energy —")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DevineTheme.Colors.ctaPrimary)

                    Text(zodiac.personalityTeaser)
                        .font(.system(size: 13))
                        .foregroundColor(DevineTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(DevineTheme.Spacing.lg)
        }
    }
}
