import Foundation
import Photos
import UIKit

enum MirrorPhotoLibraryError: LocalizedError {
    case permissionDenied
    case saveFailed
    case albumNotFound
    case missingAssetReference

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Photo access is required to save mirror check-ins."
        case .saveFailed:
            return "Could not save this photo right now."
        case .albumNotFound:
            return "Could not access the devine Check-ins album."
        case .missingAssetReference:
            return "Couldn’t link this photo without creating a duplicate. Please select another photo."
        }
    }
}

final class MirrorPhotoLibraryService {
    static let shared = MirrorPhotoLibraryService()

    private let imageManager = PHCachingImageManager()
    private let albumName = "devine Check-ins"

    private init() {}

    func requestReadWriteAuthorizationIfNeeded() async -> PHAuthorizationStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .notDetermined else { return status }
        return await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    func saveCapturedImageAndAddToAlbum(_ image: UIImage) async throws -> String {
        let status = await requestReadWriteAuthorizationIfNeeded()
        guard status == .authorized || status == .limited else {
            throw MirrorPhotoLibraryError.permissionDenied
        }

        let localIdentifier = try await saveUIImageToLibrary(image)
        try await addAssetToCheckinsAlbum(localIdentifier: localIdentifier)
        return localIdentifier
    }

    func addAssetToCheckinsAlbum(localIdentifier: String) async throws {
        let status = await requestReadWriteAuthorizationIfNeeded()
        guard status == .authorized || status == .limited else {
            throw MirrorPhotoLibraryError.permissionDenied
        }

        let collection = try await findOrCreateAlbum()
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        guard assets.count > 0 else {
            throw MirrorPhotoLibraryError.saveFailed
        }

        let existingOptions = PHFetchOptions()
        existingOptions.predicate = NSPredicate(format: "localIdentifier == %@", localIdentifier)
        let existingInAlbum = PHAsset.fetchAssets(in: collection, options: existingOptions)
        if existingInAlbum.count > 0 {
            return
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                guard let request = PHAssetCollectionChangeRequest(for: collection) else {
                    return
                }
                request.addAssets(assets)
            } completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: MirrorPhotoLibraryError.albumNotFound)
                }
            }
        }
    }

    func assetExists(localIdentifier: String) -> Bool {
        PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil).count > 0
    }

    func assetCreationDate(localIdentifier: String) -> Date? {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        return assets.firstObject?.creationDate
    }

    func requestImage(
        localIdentifier: String,
        targetSize: CGSize,
        contentMode: PHImageContentMode = .aspectFill,
        completion: @escaping (UIImage?) -> Void
    ) {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        guard let asset = assets.firstObject else {
            completion(nil)
            return
        }

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true

        imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: contentMode,
            options: options
        ) { image, _ in
            completion(image)
        }
    }

    private func saveUIImageToLibrary(_ image: UIImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            var placeholder: PHObjectPlaceholder?
            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                placeholder = request.placeholderForCreatedAsset
            } completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard success, let localIdentifier = placeholder?.localIdentifier else {
                    continuation.resume(throwing: MirrorPhotoLibraryError.saveFailed)
                    return
                }
                continuation.resume(returning: localIdentifier)
            }
        }
    }

    private func findOrCreateAlbum() async throws -> PHAssetCollection {
        if let existing = fetchAlbumByTitle(albumName) {
            return existing
        }

        let localIdentifier = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            var placeholder: PHObjectPlaceholder?
            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: self.albumName)
                placeholder = request.placeholderForCreatedAssetCollection
            } completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard success, let id = placeholder?.localIdentifier else {
                    continuation.resume(throwing: MirrorPhotoLibraryError.albumNotFound)
                    return
                }
                continuation.resume(returning: id)
            }
        }

        let collections = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [localIdentifier], options: nil)
        guard let collection = collections.firstObject else {
            throw MirrorPhotoLibraryError.albumNotFound
        }
        return collection
    }

    private func fetchAlbumByTitle(_ title: String) -> PHAssetCollection? {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "title = %@", title)
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: options)
        return collections.firstObject
    }
}
