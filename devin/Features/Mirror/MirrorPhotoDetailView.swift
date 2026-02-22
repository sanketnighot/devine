import SwiftUI

struct MirrorPhotoDetailView: View {
    @ObservedObject var model: DevineAppModel
    let entry: MirrorCheckinEntry

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false

    private var assetExists: Bool {
        MirrorPhotoLibraryService.shared.assetExists(localIdentifier: entry.assetLocalIdentifier)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if assetExists {
                    PhotoAssetFullImageView(localIdentifier: entry.assetLocalIdentifier)
                        .frame(maxWidth: .infinity)
                        .frame(height: 360)
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(DevineTheme.Colors.bgSecondary)
                        .frame(height: 240)
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.slash")
                                Text("Photo unavailable")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(DevineTheme.Colors.textSecondary)
                        }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline.weight(.semibold))
                    Text(entry.source == .camera ? "Source: Camera" : "Source: Photos")
                        .font(.footnote)
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                }

                if !entry.tags.isEmpty {
                    tagFlow(tags: entry.tags)
                }

                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.body)
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                }

                Button("Delete entry", role: .destructive) {
                    showDeleteAlert = true
                }
                .buttonStyle(.bordered)
                .padding(.top, 8)
            }
            .padding(16)
        }
        .background(DevineTheme.Colors.bgPrimary)
        .navigationTitle("Check-in")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Remove timeline entry?", isPresented: $showDeleteAlert) {
            Button("Remove", role: .destructive) {
                model.removeMirrorCheckin(entryID: entry.id)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the entry from devine timeline only. Photo remains in Photos.")
        }
    }

    private func tagFlow(tags: [String]) -> some View {
        FlexibleTagLayout(tags: tags)
    }
}

private struct FlexibleTagLayout: View {
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.subheadline.weight(.semibold))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule(style: .continuous)
                                .fill(DevineTheme.Colors.bgSecondary)
                        )
                }
            }
        }
    }
}
