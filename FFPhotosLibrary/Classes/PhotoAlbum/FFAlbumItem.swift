//
//  PhotoAlbumItem.swift
//  Picroll
//
//  Created by cofey on 2022/8/17.
//  相册模型

import UIKit
import Photos
import FFUITool

open class FFAlbumItem: NSObject {
    /// 是否默认相册
    public var isDefaultAlbum: Bool = false
    
    public var thumbailIsFirst: Bool = false
    
    public var assetCollection: PHAssetCollection? {
        didSet {
            processThumbnail()
        }
    }
    
    public var thumbnailItem: PHAsset?
    
    public var mediaType: FFMediaLibraryType = .image
    
    private func processThumbnail() {
        guard let assetCollection = assetCollection else {
            return
        }
        
        let medias = FFMediaLibrary.getMedia(album: assetCollection, mediaType: mediaType)
        thumbnailItem = thumbailIsFirst ? medias.firstObject : medias.lastObject
    }
    
    public func title(type: FFMediaLibraryType = .all)  -> String {
        if let title = assetCollection?.localizedTitle, !isDefaultAlbum {
            return title
        }
        
        if isDefaultAlbum {
            switch mediaType {
            case .image:
                return assetCollection?.localizedTitle ?? "图片"
            case .video:
                return "视频"
            default:
                return assetCollection?.localizedTitle ?? "图片"
            }
        }
        return assetCollection?.localizedTitle ?? ""
    }
    
    public func photoAlbuSubItemsCount() -> Int {
        var type: PHAssetMediaType = .unknown
        if mediaType == .image {
            type = .image
        } else if mediaType == .video {
            type = .video
        }
        guard let assetCollection = assetCollection else {
            return 0
        }
        let count = FFMediaLibrary.fetchAlubmAssetCount(collection: assetCollection).count
        return count
    }
}

extension FFAlbumItem {
    public static func == (lhs: FFAlbumItem, rhs: FFAlbumItem) -> Bool {
        return lhs.assetCollection?.assetCollectionSubtype == rhs.assetCollection?.assetCollectionSubtype
    }
}

