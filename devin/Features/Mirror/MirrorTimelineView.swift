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
        .background(DevineTheme.Colors.bgPrimary)
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
            Text("This removes the entry from devine timeline only. Photo remains in Photos.")
        }
    }

    private var timelineContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Latest to oldest")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(DevineTheme.Colors.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                ForEach(model.mirrorCheckins.sorted(by: { $0.createdAt > $1.createdAt })) { entry in
                    if MirrorPhotoLibraryService.shared.assetExists(localIdentifier: entry.assetLocalIdentifier) {
                        NavigationLink {
                            MirrorPhotoDetailView(model: model, entry: entry)
                        } label: {
                            timelineCard(entry: entry)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Delete entry", role: .destructive) {
                                pendingDeleteEntryID = entry.id
                            }
                        }
                        .padding(.horizontal, 16)
                    } else {
                        unavailableCard(entry: entry)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.bottom, 16)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading your timeline...")
                .font(.subheadline)
                .foregroundStyle(DevineTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.title)
                .foregroundStyle(DevineTheme.Colors.textMuted)
            Text("No check-ins yet")
                .font(.headline)
            Text("Add your first mirror check-in photo to start visual progress.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(DevineTheme.Colors.textSecondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var permissionBlockedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield")
                .font(.title)
                .foregroundStyle(DevineTheme.Colors.textMuted)
            Text("Photo access is blocked")
                .font(.headline)
            Text("Allow Photos access to view your mirror timeline.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(DevineTheme.Colors.textSecondary)

            Button("Open Settings") {
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(settingsURL)
            }
            .buttonStyle(.borderedProminent)
            .tint(DevineTheme.Colors.ctaPrimary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundStyle(DevineTheme.Colors.warningAccent)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(DevineTheme.Colors.textSecondary)
            Button("Retry") {
                Task {
                    await requestPermissionAndLoad()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(DevineTheme.Colors.ctaPrimary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func timelineCard(entry: MirrorCheckinEntry) -> some View {
        HStack(spacing: 12) {
            PhotoAssetThumbnailView(localIdentifier: entry.assetLocalIdentifier)

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.weight(.semibold))

                if !entry.tags.isEmpty {
                    Text(entry.tags.joined(separator: " • "))
                        .font(.caption)
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                        .lineLimit(1)
                }

                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.caption)
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DevineTheme.Colors.textMuted)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(DevineTheme.Colors.surfaceCard)
        )
    }

    private func unavailableCard(entry: MirrorCheckinEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(DevineTheme.Colors.bgSecondary)
                    .frame(width: 84, height: 84)
                    .overlay(
                        Image(systemName: "photo.slash")
                            .foregroundStyle(DevineTheme.Colors.textMuted)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline.weight(.semibold))
                    Text("Photo unavailable")
                        .font(.caption)
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                }
                Spacer()
            }

            Button("Delete entry", role: .destructive) {
                pendingDeleteEntryID = entry.id
            }
            .buttonStyle(.bordered)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(DevineTheme.Colors.surfaceCard)
        )
    }

    private func requestPermissionAndLoad() async {
        let status = await MirrorPhotoLibraryService.shared.requestReadWriteAuthorizationIfNeeded()
        model.setMirrorTimelineAuthorization(status: status)
        if status == .authorized || status == .limited {
            model.loadMirrorTimeline()
        }
    }
}
