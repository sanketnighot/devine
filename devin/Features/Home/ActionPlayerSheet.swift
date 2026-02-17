import SwiftUI

struct ActionPlayerSheet: View {
    let action: PerfectAction
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var completed = false
    @State private var sheetHeight: CGFloat = 280

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                DevineTheme.Colors.bgPrimary
                    .ignoresSafeArea()

                content
                    .padding(20)
                    .onMeasuredHeight { measured in
                        let target = min(max(measured + 92, 240), 420)
                        if abs(target - sheetHeight) > 1 {
                            sheetHeight = target
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .navigationTitle("Action")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.visible)
        .tint(DevineTheme.Colors.ctaPrimary)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(action.title)
                .font(.title2.bold())

            Text(action.instructions)
                .foregroundStyle(DevineTheme.Colors.textSecondary)

            Label("\(action.estimatedMinutes) minutes", systemImage: "clock")
                .font(.subheadline)

            Button(completed ? "Completed" : "Mark as done") {
                guard !completed else { return }
                completed = true
                onComplete()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(completed)
            .tint(DevineTheme.Colors.ctaPrimary)
        }
        .foregroundStyle(DevineTheme.Colors.textPrimary)
    }
}
