import Photos
import SwiftUI
import UIKit

struct MirrorTimelineView: View {
    @ObservedObject var model: DevineAppModel

    @State private var pendingDeleteEntryID: UUID?

    var body: some View {
        Group {
            switch model.mirrorTimelineState {
            case .idle, .loading:
                loadingView
            case .permissionBlocked:
                permissionBlockedView
            case let .error(message):
                errorView(message: message)
            case .empty:
                emptyView
            case .ready:
                timelineContent
            }
        }
        .background(
            LinearGradient(
                colors: DevineTheme.Gradients.screenBackground,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Progress Timeline")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await requestPermissionAndLoad()
        }
        .alert("Remove timeline entry?", isPresented: Binding(
            get: { pendingDeleteEntryID != nil },
            set: { isPresented in
                if !isPresented {
                    pendingDeleteEntryID = nil
                }
            }
        )) {
            Button("Remove", role: .destructive) {
                if let entryID = pendingDeleteEntryID {
                    model.removeMirrorCheckin(entryID: entryID)
                    pendingDeleteEntryID = nil
                }
            }
            Button("Cancel", role: .cancel) {
                pendingDeleteEntryID = nil
            }
        } message: {
            Text("This removes the entry from devine only. The photo stays in your Photos library.")
        }
    }

    // MARK: - Timeline Content

    private var timelineContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DevineTheme.Spacing.lg) {
                HStack {
                    Text("Your journey")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(DevineTheme.Colors.textMuted)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Spacer()

                    Text("\(model.mirrorCheckins.count) check-in\(model.mirrorCheckins.count == 1 ? "" : "s")")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(DevineTheme.Colors.textMuted)
                }
                .padding(.horizontal, DevineTheme.Spacing.lg)
                .padding(.top, DevineTheme.Spacing.md)

                ForEach(model.mirrorCheckins.sorted(by: { $0.createdAt > $1.createdAt })) { entry in
                    if MirrorPhotoLibraryService.shared.assetExists(localIdentifier: entry.assetLocalIdentifier) {
                        NavigationLink {
                            MirrorPhotoDetailView(model: model, entry: entry)
                        } label: {
                            timelineCard(entry: entry)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                pendingDeleteEntryID = entry.id
                            } label: {
                                Label("Delete entry", systemImage: "trash")
                            }
                        }
                        .padding(.horizontal, DevineTheme.Spacing.lg)
                    } else {
                        unavailableCard(entry: entry)
                            .padding(.horizontal, DevineTheme.Spacing.lg)
                    }
                }
            }
            .padding(.bottom, DevineTheme.Spacing.xxxl)
        }
    }

    // MARK: - Timeline Card

    private func timelineCard(entry: MirrorCheckinEntry) -> some View {
        HStack(spacing: DevineTheme.Spacing.lg) {
            PhotoAssetThumbnailView(
                localIdentifier: entry.assetLocalIdentifier,
                size: CGSize(width: 72, height: 72)
            )

            VStack(alignment: .leading, spacing: DevineTheme.Spacing.xs) {
                Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))

                if !entry.tags.isEmpty {
                    HStack(spacing: DevineTheme.Spacing.xs) {
                        ForEach(entry.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(moodColor(for: tag))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(moodColor(for: tag).opacity(0.12))
                                )
                        }
                    }
                }

                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.caption)
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(DevineTheme.Colors.textMuted)
        }
        .padding(DevineTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DevineTheme.Radius.xl, style: .continuous)
                .fill(DevineTheme.Colors.surfaceCard)
        )
    }

    // MARK: - Unavailable Card

    private func unavailableCard(entry: MirrorCheckinEntry) -> some View {
        HStack(spacing: DevineTheme.Spacing.lg) {
            RoundedRectangle(cornerRadius: DevineTheme.Radius.md, style: .continuous)
                .fill(DevineTheme.Colors.bgSecondary)
                .frame(width: 72, height: 72)
                .overlay(
                    Image(systemName: "photo.slash")
                        .font(.body)
                        .foregroundStyle(DevineTheme.Colors.textMuted)
                )

            VStack(alignment: .leading, spacing: DevineTheme.Spacing.xs) {
                Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))

                Text("Photo unavailable")
                    .font(.caption)
                    .foregroundStyle(DevineTheme.Colors.textMuted)
            }

            Spacer()

            Button {
                pendingDeleteEntryID = entry.id
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(DevineTheme.Colors.errorAccent)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(DevineTheme.Colors.errorAccent.opacity(0.1))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(DevineTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DevineTheme.Radius.xl, style: .continuous)
                .fill(DevineTheme.Colors.surfaceCard)
        )
        .opacity(0.7)
    }

    // MARK: - State Views

    private var loadingView: some View {
        VStack(spacing: DevineTheme.Spacing.lg) {
            ProgressView()
                .tint(DevineTheme.Colors.ctaPrimary)
            Text("Loading your timeline...")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(DevineTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        DevineEmptyState(
            icon: "photo.on.rectangle.angled",
            title: "No check-ins yet",
            message: "Add your first mirror check-in photo to start tracking your visual progress."
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var permissionBlockedView: some View {
        DevineEmptyState(
            icon: "lock.shield",
            title: "Photo access needed",
            message: "Allow Photos access to view your mirror timeline.",
            ctaLabel: "Open Settings"
        ) {
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(settingsURL)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        DevineEmptyState(
            icon: "exclamationmark.triangle",
            title: "Something went wrong",
            message: message,
            ctaLabel: "Retry"
        ) {
            Task {
                await requestPermissionAndLoad()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func moodColor(for tag: String) -> Color {
        switch tag.lowercased() {
        case "good sleep": DevineTheme.Colors.successAccent
        case "hydrated": DevineTheme.Colors.ctaPrimary
        case "low energy": DevineTheme.Colors.warningAccent
        case "high stress": DevineTheme.Colors.errorAccent
        case "puffy eyes": DevineTheme.Colors.ctaSecondary
        default: DevineTheme.Colors.textMuted
        }
    }

    private func requestPermissionAndLoad() async {
        let status = await MirrorPhotoLibraryService.shared.requestReadWriteAuthorizationIfNeeded()
        model.setMirrorTimelineAuthorization(status: status)
        if status == .authorized || status == .limited {
            model.loadMirrorTimeline()
        }
    }
}
