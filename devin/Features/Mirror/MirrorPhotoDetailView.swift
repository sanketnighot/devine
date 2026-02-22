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
            VStack(alignment: .leading, spacing: DevineTheme.Spacing.xl) {
                heroImage
                metadataCard
                tagsSection
                noteSection
                deleteAction
            }
            .padding(.horizontal, DevineTheme.Spacing.lg)
            .padding(.top, DevineTheme.Spacing.md)
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
        .navigationTitle("Check-in")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Remove timeline entry?", isPresented: $showDeleteAlert) {
            Button("Remove", role: .destructive) {
                model.removeMirrorCheckin(entryID: entry.id)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the entry from devine only. The photo stays in your Photos library.")
        }
    }

    // MARK: - Hero Image

    private var heroImage: some View {
        Group {
            if assetExists {
                PhotoAssetFullImageView(localIdentifier: entry.assetLocalIdentifier)
                    .frame(maxWidth: .infinity)
                    .frame(height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: DevineTheme.Radius.xxl, style: .continuous))
                    .shadow(color: Color.black.opacity(0.15), radius: 16, y: 8)
            } else {
                RoundedRectangle(cornerRadius: DevineTheme.Radius.xxl, style: .continuous)
                    .fill(DevineTheme.Colors.bgSecondary)
                    .frame(height: 240)
                    .overlay {
                        VStack(spacing: DevineTheme.Spacing.sm) {
                            Image(systemName: "photo.slash")
                                .font(.title2)
                            Text("Photo unavailable")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        }
                        .foregroundStyle(DevineTheme.Colors.textMuted)
                    }
            }
        }
    }

    // MARK: - Metadata Card

    private var metadataCard: some View {
        SurfaceCard {
            HStack(spacing: DevineTheme.Spacing.lg) {
                VStack(alignment: .leading, spacing: DevineTheme.Spacing.xs) {
                    Text(entry.createdAt.formatted(date: .long, time: .shortened))
                        .font(.system(.subheadline, design: .rounded, weight: .bold))

                    HStack(spacing: DevineTheme.Spacing.sm) {
                        Image(systemName: entry.source == .camera ? "camera" : "photo.on.rectangle")
                            .font(.caption2)
                            .foregroundStyle(DevineTheme.Colors.textMuted)

                        Text(entry.source == .camera ? "Camera" : "Photos library")
                            .font(.caption)
                            .foregroundStyle(DevineTheme.Colors.textMuted)
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Tags

    @ViewBuilder
    private var tagsSection: some View {
        if !entry.tags.isEmpty {
            VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
                Text("Mood")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(DevineTheme.Colors.textMuted)
                    .textCase(.uppercase)
                    .tracking(0.5)

                FlowLayout(spacing: DevineTheme.Spacing.sm) {
                    ForEach(entry.tags, id: \.self) { tag in
                        MoodChip(label: tag, isSelected: true) {}
                            .disabled(true)
                    }
                }
            }
        }
    }

    // MARK: - Note

    @ViewBuilder
    private var noteSection: some View {
        if !entry.note.isEmpty {
            VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
                Text("Note")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(DevineTheme.Colors.textMuted)
                    .textCase(.uppercase)
                    .tracking(0.5)

                SurfaceCard(padding: DevineTheme.Spacing.lg) {
                    Text(entry.note)
                        .font(.body)
                        .foregroundStyle(DevineTheme.Colors.textPrimary)
                        .lineSpacing(3)
                }
            }
        }
    }

    // MARK: - Delete

    private var deleteAction: some View {
        Button {
            DevineHaptic.tap.fire()
            showDeleteAlert = true
        } label: {
            HStack(spacing: DevineTheme.Spacing.sm) {
                Image(systemName: "trash")
                    .font(.caption)
                Text("Delete entry")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(DevineTheme.Colors.errorAccent)
            .padding(.horizontal, DevineTheme.Spacing.lg)
            .padding(.vertical, DevineTheme.Spacing.sm)
            .background(
                Capsule(style: .continuous)
                    .fill(DevineTheme.Colors.errorAccent.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .padding(.top, DevineTheme.Spacing.md)
    }
}
