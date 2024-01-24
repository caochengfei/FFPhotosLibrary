//
//  PHAsset+create.swift
//  FFPhotosLibrary
//
//  Created by cofey on 2023/11/17.
//

import Foundation
import Photos

extension PHAsset {
    /// 同步根据图片创建Asset
    /// - Parameters:
    ///   - image: 图片
    ///   - createDate: 创建时间
    ///   - complated: 完成的回调用
    public static func syncCreateAssets(image: UIImage, createDate: Date? = nil, complated: @escaping (String, Error?)->()) {
        var assetId: String = ""
        do {
            try PHPhotoLibrary.shared().performChangesAndWait {
                guard let pngData = image.pngData() else {
                    return
                }
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: pngData, options: nil)
                if let date = createDate {
                    request.creationDate = date
                }
                assetId = request.placeholderForCreatedAsset?.localIdentifier ?? ""
            }
        } catch {
            complated(assetId,error)
        }
        complated(assetId,nil)
    }
    
    
    
    /// 同步根据文件路径创建Asset
    /// - Parameters:
    ///   - data: 图片数据
    ///   - createDate: 创建时间
    ///   - complated: 完成的回掉
    public static func syncCreateAssets(fileURL: URL,createDate: Date? = nil, complated: @escaping (String, Error?)->()) {
        var assetId: String = ""
        PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, fileURL: fileURL, options: nil)
            if let date = createDate {
                request.creationDate = date
            }
            assetId = request.placeholderForCreatedAsset?.localIdentifier ?? ""
        } completionHandler: { finish, error in
            complated(assetId,error)
        }
    }
    
    /// 同步根据Data创建Asset
    /// - Parameters:
    ///   - data: 图片数据
    ///   - createDate: 创建时间
    ///   - complated: 完成的回掉
    public static func syncCreateAssets(data: Data?,createDate: Date? = nil, complated: @escaping (String, Error?)->()) {
        var assetId: String = ""
        do {
            try PHPhotoLibrary.shared().performChangesAndWait {
                guard let data = data else {
                    return
                }
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: data, options: nil)
                if let date = createDate {
                    request.creationDate = date
                }
                assetId = request.placeholderForCreatedAsset?.localIdentifier ?? ""
            }
        } catch {
            complated(assetId,error)
        }
        complated(assetId,nil)
    }
    
    /// 异步根据图片创建Asset
    /// - Parameters:
    ///   - image: 图片
    ///   - createDate: 创建时间
    ///   - complated: 完成的回掉
    public static func asyncCreateAssets(image: UIImage, createDate: Date? = nil, complated: @escaping (String, Error?)->()) {
        var assetId: String = ""
        PHPhotoLibrary.shared().performChanges {
            guard let data = image.pngData() else {
                return
            }
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: data, options: nil)
            if let date = createDate {
                request.creationDate = date
            }
            assetId = request.placeholderForCreatedAsset?.localIdentifier ?? ""
        } completionHandler: { finish, error in
            complated(assetId,error)
        }
    }
    
    
    /// 异步根据Data创建Asset
    /// - Parameters:
    ///   - data: 图片数据
    ///   - createDate: 创建时间
    ///   - complated: 完成的回掉
    public static func asyncCreateAssets(data: Data?,createDate: Date? = nil, complated: @escaping (String, Error?)->()) {
        var assetId: String = ""
        PHPhotoLibrary.shared().performChanges {
            guard let data = data else {
                return
            }
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: data, options: nil)
            if let date = createDate {
                request.creationDate = date
            }
            assetId = request.placeholderForCreatedAsset?.localIdentifier ?? ""
        } completionHandler: { finish, error in
            complated(assetId,error)
        }
    }
    
    @available(iOS 13.0, *)
    public static func asyncCreateAssets(data: Data?,createDate: Date? = nil) async throws -> String {
        var assetId: String = ""
        try await PHPhotoLibrary.shared().performChanges {
            guard let data = data else {
                return
            }
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: data, options: nil)
            if let date = createDate {
                request.creationDate = date
            }
            assetId = request.placeholderForCreatedAsset?.localIdentifier ?? ""
        }
        return assetId
    }
    
    /// 异步根据图片路径创建Asset
    /// - Parameters:
    ///   - data: 图片数据
    ///   - createDate: 创建时间
    ///   - complated: 完成的回掉
    public static func asyncCreateAssets(fileURL: URL,createDate: Date? = nil, complated: @escaping (String, Error?)->()) {
        var assetId: String = ""
        PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, fileURL: fileURL, options: nil)
            if let date = createDate {
                request.creationDate = date
            }
            assetId = request.placeholderForCreatedAsset?.localIdentifier ?? ""
        } completionHandler: { finish, error in
            complated(assetId,error)
        }
    }
}
