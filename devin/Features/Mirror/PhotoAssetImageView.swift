import Photos
import SwiftUI

struct PhotoAssetThumbnailView: View {
    let localIdentifier: String
    var size: CGSize = CGSize(width: 84, height: 84)

    @State private var image: UIImage?
    @State private var didLoad = false

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(DevineTheme.Colors.bgSecondary)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundStyle(DevineTheme.Colors.textMuted)
                    )
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .task(id: localIdentifier) {
            guard !didLoad else { return }
            didLoad = true
            MirrorPhotoLibraryService.shared.requestImage(
                localIdentifier: localIdentifier,
                targetSize: size
            ) { loaded in
                image = loaded
            }
        }
    }
}

struct PhotoAssetFullImageView: View {
    let localIdentifier: String

    @State private var image: UIImage?
    @State private var didLoad = false

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(DevineTheme.Colors.bgSecondary)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.title2)
                            Text("Photo unavailable")
                                .font(.footnote)
                        }
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .task(id: localIdentifier) {
            guard !didLoad else { return }
            didLoad = true
            MirrorPhotoLibraryService.shared.requestImage(
                localIdentifier: localIdentifier,
                targetSize: CGSize(width: 1280, height: 1280),
                contentMode: .aspectFit
            ) { loaded in
                image = loaded
            }
        }
    }
}
