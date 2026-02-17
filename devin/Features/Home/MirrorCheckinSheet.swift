import SwiftUI

struct MirrorCheckinSheet: View {
    @ObservedObject var model: DevineAppModel

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTags: Set<String> = []
    @State private var note: String = ""
    @State private var sheetHeight: CGFloat = 520

    private let tags = ["Puffy eyes", "Low energy", "Good sleep", "High stress", "Hydrated"]

    var body: some View {
        NavigationStack {
            Form {
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
                    Button("Save") {
                        model.recordMirrorCheckin(tags: Array(selectedTags), note: note)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onMeasuredHeight { measured in
            let target = min(max(measured + 20, 420), 680)
            if abs(target - sheetHeight) > 1 {
                sheetHeight = target
            }
        }
        .presentationDetents([.height(sheetHeight), .large])
        .presentationDragIndicator(.visible)
        .tint(DevineTheme.Colors.ctaPrimary)
    }
}
