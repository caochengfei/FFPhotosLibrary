//
//  VSMediaLibrary.swift
//  GreenScreenMan
//
//  Created by cofey on 2019/3/22.
//  Copyright © 2019 Versa. All rights reserved.
//

import AssetsLibrary
import Photos
import AVFoundation
import FFUITool
import ImageIO

public enum FFMediaLibraryType : Int {
    case all = 0
    case image = 1
    case video = 2
    case audio = 3
}

//MARK: 相册信息获取
open class FFMediaLibrary: NSObject {
    /// 获取视频
    /// - Parameters:
    ///   - asset: PHAsset
    ///   - targetFolderPath: 存储目标路径
    ///   - progress: 进度回调
    ///   - completion: 结果回调
    /// - Returns: PHImageRequestID 用来取消操作
    public static func getVideo(asset: PHAsset, targetFolderPath:String?, progress: @escaping ((Double)->()), completion: @escaping (URL?)->()) ->PHImageRequestID {
        // 获取调整过的数据
        let adjustmentResources = PHAssetResource.assetResources(for: asset).filter { $0.type == .adjustmentData}
                
        let option: PHVideoRequestOptions = PHVideoRequestOptions()
        option.isNetworkAccessAllowed = true
        let progressHandler: PHAssetVideoProgressHandler = { (percent, error, stop, info) in
            progress(percent)
        }
        option.progressHandler = progressHandler
        //for slow motion
        option.version = adjustmentResources.count > 0 ? .current : .original
        //TODO:目前只做视频
        let reqId = PHImageManager.default().requestAVAsset(forVideo: asset, options: option) {(ret, mix, info) in
            func postFail() {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
            
            if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, isDegraded {
                postFail()
                return
            }
            
            if let isCancel = info?[PHImageCancelledKey] as? Bool, isCancel {
                postFail()
                return
            }
            
            if let _ = info?[PHImageErrorKey] {
                postFail()
                return
            }
            
            let targetId = "\(asset.localIdentifier)_\(asset.modificationDate?.description ?? "")"
            guard let origUrl = (ret as? AVURLAsset)?.url else {
//                if let composition = ret as? AVComposition, composition.tracks.count == 2 {
//                    //slow motion videos. See Here: https://overflow.buffer.com/2016/02/29/slow-motion-video-ios/
//
//                    //Output URL of the slow motion file.
//                    let folderPath: String = targetFolderPath ?? NSTemporaryDirectory()
//                    let targetPath: String = "\(folderPath)/\(targetId.md5).mov"
//                    // 有同名文件 系统会笑会掉exporter 导致外部始终拿不到回调 （慢动作视频）
//                    if FileManager.default.fileExists(atPath: targetPath) {
//                        DispatchQueue.main.async {
//                            completion(URL(fileURLWithPath: targetPath))
//                        }
//                        return
//                    }
//                    let url = URL(fileURLWithPath: targetPath)
//                    //Begin slow mo video export
//                    guard let exporter = VSAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
//                        postFail()
//                        return
//                    }
//                    exporter.outputURL = url
//                    exporter.outputFileType = AVFileType.mov
//                    exporter.shouldOptimizeForNetworkUse = true
//
//                    exporter.exportAsynchronously {
//                        DispatchQueue.main.async {
//                            if exporter.status == .completed {
//                                guard let url = exporter.outputURL else {
//                                    postFail()
//                                    return
//                                }
//
//                                if !FileManager.default.fileExists(atPath: targetPath) {
//                                    FFIOTool.copyItem(fromUrl: url, toUrl: URL(fileURLWithPath: targetPath))
//                                }
//
//                                DispatchQueue.main.async {
//                                    completion(URL(fileURLWithPath: targetPath))
//                                }
//                            }
//                        }
//                    }
//                    exporter.progressBlock = { (percent) in
//                        progress(Double(percent))
//                    }
//                    exporter.startObserverProgress()
//                } else {
//                    postFail()
//                }
                
                return
            }
            
            let folderPath: String = targetFolderPath ?? NSTemporaryDirectory()
            let targetPath: String = "\(folderPath)/\(targetId.md5).\(origUrl.pathExtension)"
           
            if !FileManager.default.fileExists(atPath: targetPath) {
                FFDiskTool.copyItem(fromUrl: origUrl, toUrl: URL(fileURLWithPath: targetPath))
            }
            
            DispatchQueue.main.async {
                completion(URL(fileURLWithPath: targetPath))
            }
        }
        
        return reqId
    }
    
    
    /// 获取图片
    /// - Parameters:
    ///   - asset: PHAsset
    ///   - progress: 进度回调
    ///   - completion: 结果回调
    /// - Returns: PHImageRequestID 用来取消操作
    @discardableResult
    public static func getImage(asset: PHAsset,
                         maxSize: CGSize = CGSize(width: 3000, height: 3000),
                         directoryName: String? = nil,
                         progress: ((Double)->())?,
                         completion: @escaping (URL?)->()) ->PHImageRequestID {
        let adjustmentResources = PHAssetResource.assetResources(for: asset).filter { $0.type == .adjustmentData }
        
        let option: PHImageRequestOptions = PHImageRequestOptions()
        option.isNetworkAccessAllowed = true
        option.deliveryMode = .highQualityFormat
        option.version = adjustmentResources.count > 0 ? .current : .unadjusted
        let progressHandler: PHAssetImageProgressHandler = { (percent, error, stop, info) in
            progress?(percent)
        }
        option.progressHandler = progressHandler
        //长边最大3000
        let targetSize = maxSize.fitRect(imageSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight)).size
        let reqId = PHImageManager.default().requestImage(for: asset,
                                                          targetSize: targetSize,
                                                          contentMode: .aspectFit,
                                                          options: option) { (image, hash) in
            DispatchQueue.global().async {
                guard let image = image else{
                    completion(nil)
                    return
                }
                let targetDirectory = (directoryName != nil) ? FFDiskTool.createDirectory(directoryName: directoryName!).path :  NSTemporaryDirectory()
                var targetPath = targetDirectory + "/\(NSUUID().uuidString.md5).png"
                autoreleasepool {
                    targetPath = saveImage(currentImage: image, targetPath: targetPath,usePng: false,useHeic: false)
                }
                DispatchQueue.main.async {
                    completion(URL(fileURLWithPath: targetPath))
                }
            }
        }
        return reqId
    }
    
    /// 获取图片
    /// - Parameters:
    ///   - asset: PHAsset
    ///   - progress: 进度回调
    ///   - completion: 结果回调
    /// - Returns: PHImageRequestID 用来取消操作
    @discardableResult
    public static func getImage(asset: PHAsset,
                         maxSize: CGSize = CGSize(width: 3000, height: 3000),
                         directoryName: String? = nil,
                         progress: ((Double)->())?) async throws -> URL {
        let adjustmentResources = PHAssetResource.assetResources(for: asset).filter { $0.type == .adjustmentData }
        
        let option: PHImageRequestOptions = PHImageRequestOptions()
        option.isNetworkAccessAllowed = true
        option.deliveryMode = .highQualityFormat
        option.version = adjustmentResources.count > 0 ? .current : .unadjusted
        let progressHandler: PHAssetImageProgressHandler = { (percent, error, stop, info) in
            progress?(percent)
        }
        option.progressHandler = progressHandler
        let targetSize = maxSize.fitRect(imageSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight)).size

        return try await withUnsafeThrowingContinuation { (config:UnsafeContinuation<URL, Error>) in
            //长边最大3000
            let reqId = PHImageManager.default().requestImage(for: asset,
                                                              targetSize: targetSize,
                                                              contentMode: .aspectFit,
                                                              options: option) { (image, hash) in
                DispatchQueue.global().async {
                    guard let image = image else{
                        config.resume(throwing: NSError(domain: "url is nil", code: -1))
                        return
                    }
                    let targetDirectory = (directoryName != nil) ? FFDiskTool.createDirectory(directoryName: directoryName!).path :  NSTemporaryDirectory()
                    var targetPath = targetDirectory + "/\(NSUUID().uuidString.md5).png"
                    targetPath = saveImage(currentImage: image, targetPath: targetPath,usePng: false,useHeic: false)
                    DispatchQueue.main.async {
                        config.resume(returning: URL(fileURLWithPath: targetPath))
//                        completion(URL(fileURLWithPath: targetPath))
                    }
                }
            }
        }
    }
    
    /// 获取缩略图
    /// - Parameters:
    ///   - asset: PHAsset
    ///   - progress: 进度回调
    ///   - completion: 结果回调
    /// - Returns: PHImageRequestID 用来取消操作
    @discardableResult
    public static func getThumbImage(asset: PHAsset, size: CGSize = CGSize(width: 50, height: 50) ,isPrew: Bool = false, completion: @escaping (UIImage?)->()) ->PHImageRequestID {
        let option: PHImageRequestOptions = PHImageRequestOptions()
        option.isNetworkAccessAllowed = true
        option.deliveryMode = .highQualityFormat
        option.version = .current
        option.isSynchronous = false
        option.resizeMode = isPrew ? .none : .fast
        //长边最大3000
        let targetSize = size.fitRect(imageSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight)).size
        let reqId = PHImageManager.default().requestImage(for: asset,
                                                          targetSize: targetSize,
                                                          contentMode: .aspectFill,
                                                          options: option) { (image, hash) in
            DispatchQueue.main.async {
                completion(image)
            }
        }
        return reqId
    }
    
    @discardableResult
    public static func syncThumbImage(asset: PHAsset, size: CGSize = CGSize(width: 50, height: 50) ,isPrew: Bool = false, completion: @escaping (UIImage?)->()) ->PHImageRequestID {
        let option: PHImageRequestOptions = PHImageRequestOptions()
        option.isNetworkAccessAllowed = true
        option.deliveryMode = .highQualityFormat
        option.version = .current
        option.isSynchronous = true
        option.resizeMode = isPrew ? .none : .fast
        //长边最大3000
        let targetSize = size.fitRect(imageSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight)).size
        let reqId = PHImageManager.default().requestImage(for: asset,
                                                          targetSize: targetSize,
                                                          contentMode: .aspectFill,
                                                          options: option) { (image, hash) in
            completion(image)
        }
        return reqId
    }
    
    
    /// 获取相册内的asset集合
    /// - Parameters:
    ///   - album: 相册
    ///   - mediaType: 类型
    /// - Returns: Phasset
    public static func getMedia(album: PHAssetCollection, mediaType:FFMediaLibraryType = .video, ascending: Bool? = nil, limit: Int = 0) ->PHFetchResult<PHAsset> {
        let opt: PHFetchOptions = PHFetchOptions()
        switch mediaType {
        case .image:
            opt.predicate = NSPredicate(format: "mediaType=%d", PHAssetMediaType.image.rawValue)
            if let ascending = ascending {
                opt.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: ascending)]
            }
            opt.fetchLimit = limit
        case .video:
            opt.predicate = NSPredicate(format: "mediaType=%d", PHAssetMediaType.video.rawValue)
            if let ascending = ascending {
                opt.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: ascending)]
            }
            opt.fetchLimit = limit
        default:
            if let ascending = ascending {
                opt.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: ascending)]
            }
            opt.fetchLimit = limit
            break
        }
        let assets: PHFetchResult<PHAsset> = PHAsset.fetchAssets(in: album, options: opt)
        return assets
    }
    
    
    /// 获取所有相册
    /// - Parameter mediaType: 相册类型
    /// - Returns: 相册集合
    public static func getAllPhotoAlbum(mediaType:FFMediaLibraryType = .image) ->PHFetchResult<PHAssetCollection> {
        let assetCollections: PHFetchResult<PHAssetCollection> = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)
        return assetCollections
    }
    
    
    /// 获取视频缩略图
    /// - Parameters:
    ///   - path: 文件路径
    ///   - maximumSize: 缩放最大大小
    ///   - tolerant: 准确的
    ///   - time: 要生成缩略图的时间
    /// - Returns: UIImage
    public static func getVideoThumbnail(for path:String?, maximumSize: CGSize = .zero, tolerant: Bool = true, time: CMTime = .zero) -> UIImage? {
        guard let path = path, FileManager.default.fileExists(atPath: path) else {
            ffAssert(false, "getThumbnail fail")
            return nil
        }
        let url = URL(fileURLWithPath: path)
        let asset = AVAsset(url: url)
        let gen:AVAssetImageGenerator = AVAssetImageGenerator.init(asset: asset)
        gen.maximumSize = maximumSize
        gen.appliesPreferredTrackTransform = true
        if !tolerant {
            gen.requestedTimeToleranceBefore = .zero
            gen.requestedTimeToleranceAfter = .zero
        }
        let track:AVAssetTrack? = asset.tracks(withMediaType: .video).first
        
        if track == nil {
            return nil
        }
                
        var thumb: UIImage? = nil
        do {
            let cgImage:CGImage = try gen.copyCGImage(at: time, actualTime: nil)
            thumb = UIImage(cgImage: cgImage)
        } catch {
            return nil
        }
        return thumb;
    }
    
    public static func deleteItem(assetIdentifiers: [String],completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            let result = PHAsset.fetchAssets(withLocalIdentifiers: assetIdentifiers, options: nil)
            var assets = [PHAsset]()
            result.enumerateObjects { item, idx, _ in
                let canDelete = item.canPerform(.delete)
                if canDelete {
                    assets.append(item)
                }
            }
            PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
        }, completionHandler: { (success, error) in
            DispatchQueue.main.async {
                completion(success, error)
            }
        })
    }
    
    public static func selectedItems(assetIdentifiers: [String]) -> PHFetchResult<PHAsset> {
        return PHAsset.fetchAssets(withLocalIdentifiers: assetIdentifiers, options: nil)
    }
}

//MARK: - PhotosAlbum 相册相关
extension FFMediaLibrary {
    /// 获取默认相册
    /// - Parameter mediaType: 相册类型
    /// - Returns: 相册模型
    public static func getDefaultAlbums(mediaType:FFMediaLibraryType = .all, result: @escaping (_ success: Bool, _ album: FFAlbumItem) -> ()) {
        let item = FFAlbumItem()
        item.mediaType = mediaType
        item.isDefaultAlbum = true
        FFAuthorizationTool.requestPhotoAuthorization(for: .readWrite, result: { success in
            if success {
                item.assetCollection = self.getAllPhotoAlbum(mediaType: mediaType).firstObject
                result(success,item)
            } else {
                item.assetCollection = nil
                result(false, item)
            }
        })
    }
    
    ///获取自定义的所有相册
    public static func getAllAlbums(mediaType:FFMediaLibraryType) -> [FFAlbumItem] {
        var dataArray: [FFAlbumItem] = [FFAlbumItem]()
        
        if let album = self.fetchFavoriteAlbums() {
            let item = FFAlbumItem()
            item.mediaType = mediaType
            item.assetCollection = album.firstObject
            dataArray.append(item)
        }

        if let album = self.getCustomFileAlbums(mediaType: mediaType) {
            for (_, item) in album.enumerated() {
                if item.estimatedAssetCount == 0 {
                    break
                }
                let photoAlbumItem = FFAlbumItem()
                photoAlbumItem.thumbailIsFirst = true
                photoAlbumItem.mediaType = mediaType
                photoAlbumItem.assetCollection = item
                if photoAlbumItem.photoAlbuSubItemsCount() > 0 {
                    dataArray.append(photoAlbumItem)
                }
            }
        }
        
        if let album = self.getRecentlyAddedAlbums() {
            let item = FFAlbumItem()
            item.mediaType = mediaType
            item.assetCollection = album.firstObject
            if item.photoAlbuSubItemsCount() > 0 {
                dataArray.append(item)
            }
        }
    
        if let album = self.getMyPhotoStreamAlbums() {
            let item = FFAlbumItem()
            item.mediaType = mediaType
            item.assetCollection = album.firstObject
            if item.photoAlbuSubItemsCount() > 0 {
                dataArray.append(item)
            }
        }
        if let album = self.getScreenShotsAlbums() {
            let item = FFAlbumItem()
            item.mediaType = mediaType
            item.assetCollection = album.firstObject
            if item.photoAlbuSubItemsCount() > 0 {
                dataArray.append(item)
            }
        }
        
        if let album = self.getPortraitAlbums() {
            let item = FFAlbumItem()
            item.mediaType = mediaType
            item.assetCollection = album.firstObject
            if item.photoAlbuSubItemsCount() > 0 {
                dataArray.append(item)
            }
        }
        
        return dataArray
    }
    
    /// 获取我喜欢的相册
    public static func fetchFavoriteAlbums() -> PHFetchResult<PHAssetCollection>? {
        return self.getPhotoAlbums(with: .smartAlbum, subtype: .smartAlbumFavorites, options: nil)
    }
    
    /// 获取自定义相册
    public static func getCustomFileAlbums(mediaType:FFMediaLibraryType) -> [PHAssetCollection]? {
        var tempArr: [PHAssetCollection] = []
        
        let topLeveUserCollections = PHCollectionList.fetchTopLevelUserCollections(with: nil)
        if topLeveUserCollections.count > 0 {
            for i in 0 ... topLeveUserCollections.count - 1 {
                let collection = topLeveUserCollections[i]
                if collection.isKind(of: PHAssetCollection.self) , let assetCollection = collection as? PHAssetCollection {
                    
                    let fetchResult = fetchAlubmAssetCount(collection: assetCollection)
                    if mediaType == .image {
                        if fetchResult.firstObject?.mediaType.rawValue == mediaType.rawValue {
                            tempArr.append(assetCollection)
                        }
                    } else if mediaType == .video {
                        if fetchResult.firstObject?.mediaType.rawValue == mediaType.rawValue {
                            tempArr.append(assetCollection)
                        }
                    } else if mediaType == .all {
                        if fetchResult.firstObject?.mediaType == .image || fetchResult.firstObject?.mediaType == .video {
                            tempArr.append(assetCollection)
                        }
                    }
                }
            }
        }
        return tempArr
    }
    
    public static func fetchAlubmAssetCount(collection: PHAssetCollection) -> PHFetchResult<PHAsset> {
        let fetchResult = PHAsset.fetchAssets(in: collection, options: nil)
        return fetchResult
    }
    
    
    /// 获取我的视频流相册
    public static func getMyPhotoStreamAlbums() -> PHFetchResult<PHAssetCollection>? {
        return self.getPhotoAlbums(with: .album, subtype: .albumMyPhotoStream, options: nil)
    }
    
    /// 获取截图相册
    public static func getScreenShotsAlbums() -> PHFetchResult<PHAssetCollection>? {
        return self.getPhotoAlbums(with: .smartAlbum, subtype: .smartAlbumScreenshots, options: nil)
    }
    
    /// 获取近期增加
    public static func getRecentlyAddedAlbums() -> PHFetchResult<PHAssetCollection>? {
        return self.getPhotoAlbums(with: .smartAlbum, subtype: .smartAlbumRecentlyAdded, options: nil)
    }
    
    /// 获取人像相册
    static func getPortraitAlbums() -> PHFetchResult<PHAssetCollection>? {
        if #available(macOS 10.15, iOS 10.2, tvOS 13.0, *)  {
            return self.getPhotoAlbums(with: .smartAlbum, subtype: .smartAlbumDepthEffect, options: nil)
        }
        return nil
    }
    
    /// 获取相册
    /// - Parameters:
    ///   - type: PHAssetCollectionType
    ///   - subtype: 相册类型
    ///   - options: 可选参数 PHFetchOptions
    /// - Returns: PHFetchResult<PHAssetCollection>？
    public static func getPhotoAlbums(with type: PHAssetCollectionType, subtype: PHAssetCollectionSubtype, options: PHFetchOptions?) -> PHFetchResult<PHAssetCollection>? {
        let assetCollections: PHFetchResult<PHAssetCollection> = PHAssetCollection.fetchAssetCollections(with: type,
                                                                                                         subtype: subtype,
                                                                                                         options: options)
        let collection: PHAssetCollection? =  assetCollections.firstObject
        return (collection?.estimatedAssetCount ?? 0 > 0) ? assetCollections : nil
    }
    
    /// 创建自定义相册
    /// - Returns: PHAssetCollection
    public static func createCustomAssetCollectionIfNeeded(albumName: String? = nil) -> PHAssetCollection? {
        var localIdentifier: String = FFMediaLibrary.getLocalIdentifier()
        let albumCollections = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [localIdentifier], options: nil);
        let albumCollection = albumCollections.firstObject
        if localIdentifier.count == 0 || albumCollection == nil  {
            do {
                try PHPhotoLibrary.shared().performChangesAndWait {
                    let title: String = albumName ?? Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Picroll"
                    localIdentifier = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title).placeholderForCreatedAssetCollection.localIdentifier;
                    FFMediaLibrary.setLocalIdentifier(identifier: localIdentifier)
                }
            } catch {
                return nil
            }
        }
        let album = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [localIdentifier], options: nil);
        return album.firstObject
    }
    
    
    /// 获取自定义相册的id
    /// - Returns: Identidier
    private static func getLocalIdentifier() -> String {
        return UserDefaults.standard.string(forKey: "AlbumLocalIdentidier") ?? ""
    }
    
    
    /// 设置自定义相册的id
    /// - Parameter identifier: 标识符
    private static func setLocalIdentifier(identifier: String) {
        UserDefaults.standard.set(identifier, forKey: "AlbumLocalIdentidier")
        UserDefaults.standard.synchronize()
    }
}

//MARK: - 权限相关
extension FFMediaLibrary {
    /// 跳转到设置页
    public static func openSettings() {
        let url: URL = URL(string: UIApplication.openSettingsURLString)!
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

//MARK:图片前处理
extension FFMediaLibrary {
    public static func getFitRect(image:UIImage) ->CGRect {
        var w: CGFloat = image.size.width
        var h: CGFloat = image.size.height
        let ratio: CGFloat = w / h
        let maxScale: CGFloat = 3.0
        if ratio > maxScale || ratio < 1.0 / maxScale {
            //TODO: 长宽比异常，做一个居中裁剪(临时解决方案)
            if(ratio > maxScale) {
                w = h * maxScale
            }
            else {
                h = w * maxScale
            }
        }
        
        let rect:CGRect = CGRect(x:(image.size.width - w) / 2, y:(image.size.height - h) / 2, width:w, height:h)
        return rect
    }
    
    public static func scaleToFitSize(origSize:CGSize, scale:CGFloat) ->CGSize {
        var fitSize:CGSize = origSize
        let minVal: CGFloat = 800 * scale
        let ratio: CGFloat = origSize.width / origSize.height
        if(ratio > 1) {
            fitSize.height = min(origSize.height, minVal)
            fitSize.width = round(fitSize.height * ratio)
        } else {
            fitSize.width = min(origSize.width, minVal)
            fitSize.height = round(fitSize.width / ratio)
        }
        
        return fitSize
    }
}


//MARK: - 视频信息相关
extension FFMediaLibrary {
    // 获取视频时长
    public static func getVideoDuration(path: String) -> TimeInterval {
        guard FileManager.default.fileExists(atPath: path) else {
            print("fileinfo is nil")
            return 0
        }
        let asset = AVURLAsset(url: URL(fileURLWithPath: path))
        return getVideoDuration(asset: asset)
    }
    
    /// 获取视频时长
    /// - Parameter asset: AVAsset
    /// - Returns: 时常
    public static func getVideoDuration(asset:AVAsset) -> TimeInterval{
        let duration = CMTimeGetSeconds(asset.duration);
        return duration
    }
    
    /// 获取视频时长
    /// - Parameter asset: AVAsset
    /// - Returns: 时常
    public static func getVideoDuration(asset:PHAsset) -> TimeInterval{
        return asset.duration
    }
    
    
    /// 获取视频fps
    /// - Parameter path: 文件路径
    /// - Returns: fps
    public static func fps(path:String) ->Float {
        let asset:AVAsset = AVAsset(url: URL.init(fileURLWithPath: path))
        return asset.tracks(withMediaType: .video).first?.nominalFrameRate ?? 0.0
    }
    
    
    /// 获取视频方向
    /// - Parameter path: 文件路径
    /// - Returns: UIInterfaceOrientation
    public static func orientation(path:String) ->UIInterfaceOrientation {
        let asset = AVURLAsset(url: URL(fileURLWithPath: path))
        guard let track = asset.tracks(withMediaType: .video).first else {
            return .portrait
        }
        let t = track.preferredTransform
        
        if t.a == 0, t.b == 1.0, t.c == -1.0, t.d == 0 {
//            degress = 90;
            return .portrait
        } else if t.a == 0, t.b == -1.0, t.c == 1.0, t.d == 0 {
//            degress = 270;
            return .landscapeLeft
        } else if t.a == 1.0, t.b == 0, t.c == 0, t.d == 1.0 {
//            degress = 0;
            return .landscapeRight
        } else if t.a == -1.0, t.b == 0, t.c == 0, t.d == -1.0 {
//            degress = 180;
            return .portraitUpsideDown
        }
        return .portrait
    }
    
    /// 获取帧率
    /// - Parameter path: 文件路径
    /// - Returns: 帧率
    public static func getFrameRate(path:String) -> Float {
        let asset: AVURLAsset = AVURLAsset(url: URL.init(fileURLWithPath: path))
        return getFrameRate(asset: asset)
    }
    
    
    public static func getFrameRate(asset:AVAsset) -> Float  {
        let track: AVAssetTrack? = asset.tracks(withMediaType: AVMediaType.video).first
        return track?.nominalFrameRate ?? 0.0
    }
    
    /// 获取视频文件大小
    /// - Parameter videoPath: 文件路径
    /// - Returns: CGSize
    public static func videoSize(videoPath:String) ->CGSize {
        return videoSize(videoAsset: AVURLAsset(url: URL.init(fileURLWithPath: videoPath)))
    }
    
    public static func videoSize(videoAsset:AVURLAsset) ->CGSize {
        let track:AVAssetTrack? = videoAsset.tracks(withMediaType: AVMediaType.video).first
        guard let size = track?.naturalSize else {
            let path = videoAsset.url.path
            if path.count > 0,
               FileManager.default.fileExists(atPath: path),
               let image = UIImage(contentsOfFile: path) {
                return image.size
            }
            return CGSize.zero
        }
        let result = size.applying(track!.preferredTransform)
        return CGSize(width: abs(result.width), height: abs(result.height))
    }
    
    public static func videoDuration(videoAsset: PHAsset?) -> String {
         guard let asset = videoAsset else { return "00:00" }
         let duration: TimeInterval = asset.duration
         let s: Int = Int(duration) % 60
         let m: Int = Int(duration) / 60
         let formattedDuration = String(format: "%02d:%02d", m, s)
         return formattedDuration
     }
}

//MARK: - 视频处理
extension FFMediaLibrary {
    
    /// 保存视频到相册
    /// - Parameters:
    ///   - path: from文件路径
    ///   - completion: 回调
    public static func saveVideoToPhotos(with path:String, completion: @escaping (Error?, String?)->Void) {
        FFAuthorizationTool.requestPhotoAuthorization(for: .readWrite, result: { success in
            if !success {
                completion(NSError(domain: "请打开相册权限", code: -1), nil)
                return
            }
            var localIdenitifer:String?
            PHPhotoLibrary.shared().performChanges({
                let request =  PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL:URL.init(fileURLWithPath: path))
                
                localIdenitifer = request?.placeholderForCreatedAsset?.localIdentifier ?? ""
                
            }, completionHandler: { (success, error) in
                DispatchQueue.main.async {
                    completion(error, localIdenitifer)
                }
            })
        })
          
    }
    
    
    /// 保存图片到相册
    /// - Parameters:
    ///   - path: from文件路径
    ///   - completion: 回调
    public static func saveImageToPhotosWithPath(with path:String, completion: @escaping (Error?, String?)->Void) {
        FFAuthorizationTool.requestPhotoAuthorization(for: .readWrite, result: { success in
            if !success {
                completion(NSError(domain: "请打开相册权限", code: -1), nil)
                return
            }
            var localIdenitifer:String?
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: URL(fileURLWithPath: path))
                localIdenitifer = request?.placeholderForCreatedAsset?.localIdentifier ?? ""
                
            }, completionHandler: { (success, error) in
                DispatchQueue.main.async {
                    completion(error, localIdenitifer)
                }
            })
        })
    }
    
    public static func saveImageToPhotosWithImage(with image: UIImage, createDate: Date? = nil, completion: @escaping (Error?, String?)->Void) {
        FFAuthorizationTool.requestPhotoAuthorization(for: .addOnly, result: { success in
            if !success {
                completion(NSError(domain: "请打开相册权限", code: -1), nil)
                return
            }
            let localIdenitifer:String = FFMediaLibrary.getLocalIdentifier()
            PHAsset.asyncCreateAssets(image: image, createDate: createDate) { assetId, error in
                DispatchQueue.main.async {
                    completion(error, nil)
                }
            }
        })
    }
    
    public static func saveImageToCustomPhotosWithImage(with image: UIImage, createDate: Date? = nil, completion: @escaping (Error?, String?)->Void) {
        FFAuthorizationTool.requestPhotoAuthorization(for: .readWrite, result: { success in
            if !success {
                completion(NSError(domain: "请打开相册权限", code: -1), nil)
                return
            }
            let albumCollection = FFMediaLibrary.createCustomAssetCollectionIfNeeded()
            let localIdenitifer:String = FFMediaLibrary.getLocalIdentifier()
            PHAsset.asyncCreateAssets(image: image, createDate: createDate) { assetId, error in
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
                if let albumCollection = albumCollection {
                    PHPhotoLibrary.shared().performChanges({
                        let request = PHAssetCollectionChangeRequest(for: albumCollection)
                        request?.addAssets(assets)
                    }, completionHandler: { (success, error) in
                        DispatchQueue.main.async {
                            completion(error, localIdenitifer)
                        }
                    })
                } else {
                    DispatchQueue.main.async {
                        completion(error, localIdenitifer)
                    }
                }
            }
        })
    }
    
    public static func saveImageToPhotosWithData(with data: Data?, createDate: Date? = nil, completion: @escaping (Error?, String?)->Void) {
        FFAuthorizationTool.requestPhotoAuthorization(for: .addOnly, result: { success in
            if !success {
                completion(NSError(domain: "请打开相册权限", code: -1), nil)
                return
            }
            PHAsset.asyncCreateAssets(data: data, createDate: createDate) { assetId, error in
                DispatchQueue.main.async {
                    completion(error, nil)
                }
            }
        })
    }
    
    public static func syncSaveImageToPhotosWithDataAndReturnAsset(for data: Data?, createDate: Date? = nil, completion: @escaping (Error?, PHAsset?)->Void) {
        FFAuthorizationTool.requestPhotoAuthorization(for: .addOnly, result: { success in
            if !success {
                completion(NSError(domain: "请打开相册权限", code: -1), nil)
                return
            }
            PHAsset.syncCreateAssets(data: data, createDate: createDate) { assetId, error in
                DispatchQueue.main.async {
                    let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
                    completion(error, assets.firstObject)
                }
            }
        })
    }
    
    public static func syncSaveImageWithDataToCustomPhotos(for data: Data?,createDate: Date? = nil, completion: @escaping (Error?, String?)->Void) {
        FFAuthorizationTool.requestPhotoAuthorization(for: .readWrite, result: { success in
            if !success {
                completion(NSError(domain: "请打开相册权限", code: -1), nil)
                return
            }
            let albumCollection = FFMediaLibrary.createCustomAssetCollectionIfNeeded()
            let localIdenitifer:String = FFMediaLibrary.getLocalIdentifier()
            PHAsset.syncCreateAssets(data: data, createDate: createDate) { assetId, error in
                
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
                if let albumCollection = albumCollection {
                    PHPhotoLibrary.shared().performChanges({
                        let request = PHAssetCollectionChangeRequest(for: albumCollection)
                        request?.addAssets(assets)
                    }, completionHandler: { (success, error) in
                        DispatchQueue.main.async {
                            completion(error, localIdenitifer)
                        }
                    })
                } else {
                    DispatchQueue.main.async {
                        completion(error, localIdenitifer)
                    }
                }
            }
        })
    }
    
    public static func asyncSaveImageWithDataToCustomPhotos(for data: Data?,createDate: Date? = nil, completion: @escaping (Error?, String?)->Void) {
        FFAuthorizationTool.requestPhotoAuthorization(for: .readWrite, result: { success in
            if !success {
                completion(NSError(domain: "请打开相册权限", code: -1), nil)
                return
            }
            let albumCollection = FFMediaLibrary.createCustomAssetCollectionIfNeeded()
            let localIdenitifer:String = FFMediaLibrary.getLocalIdentifier()
            PHAsset.asyncCreateAssets(data: data, createDate: createDate) { assetId, error in
                
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
                if let albumCollection = albumCollection {
                    PHPhotoLibrary.shared().performChanges({
                        let request = PHAssetCollectionChangeRequest(for: albumCollection)
                        request?.addAssets(assets)
                    }, completionHandler: { (success, error) in
                        DispatchQueue.main.async {
                            completion(error, localIdenitifer)
                        }
                    })
                } else {
                    DispatchQueue.main.async {
                        completion(error, localIdenitifer)
                    }
                }
            }
        })
    }
    
    
    /// 保存图片到沙盒
    /// - Parameters:
    ///   - currentImage: 图片
    ///   - targetPath: 文件路径
    @discardableResult
    public static func saveImage(currentImage: UIImage, targetPath: String, usePng: Bool = true, useHeic: Bool = false) -> String {
        var saveError: Bool = false
        var resultPath = targetPath
        if usePng {
            autoreleasepool {
                var urlPath = URL(fileURLWithPath: targetPath).deletingPathExtension()
                urlPath.appendPathExtension("png")
                do {
                    try saveFile(fileUrl: urlPath, image: currentImage, fileType: "public.png" as CFString)
                    resultPath = urlPath.path
                } catch  {
                    saveError = true
                }
            }
            if saveError == false {
                return resultPath
            }
        }
        
        if useHeic {
            autoreleasepool {
                if currentImage.isHeicSupported, let imageData = currentImage.heic {
                    var urlPath = URL(fileURLWithPath: targetPath).deletingPathExtension()
                    urlPath.appendPathExtension("heic")
                    FFDiskTool.saveFile(data: imageData, url: urlPath)
                    resultPath = urlPath.path
                } else {
                    saveError = true
                }
            }
            if saveError == false {
                return resultPath
            }
        }
       
        autoreleasepool {
            if let imageData = currentImage.jpegData(compressionQuality: 1.0) {
                var urlPath = URL(fileURLWithPath: targetPath).deletingPathExtension()
                urlPath.appendPathExtension("jpeg")
                FFDiskTool.saveFile(data: imageData, url: urlPath)
                resultPath = urlPath.path
            } else {
                saveError = true
            }
        }
        
        if saveError == false {
            return resultPath
        }
       
        autoreleasepool {
            if let imageData = currentImage.pngData() {
                var urlPath = URL(fileURLWithPath: targetPath).deletingPathExtension()
                urlPath.appendPathExtension("png")
                FFDiskTool.saveFile(data: imageData, url: urlPath)
                resultPath = urlPath.path
            } else {
                saveError = true
            }
        }
        return resultPath
    }
    
    private static func saveFile (fileUrl:URL, image:UIImage, fileType:CFString) throws {
        let url = fileUrl as CFURL
        let destination = CGImageDestinationCreateWithURL(url, fileType, 1, nil);
        if nil==destination {
            throw NSError(domain: "destination == nil", code: -1)
        }
        
        if nil == image.cgImage {
            throw NSError(domain: "image.cgImage = nil", code: -1)
        }
        CGImageDestinationAddImage(destination!, image.cgImage!, nil)
        CGImageDestinationFinalize(destination!)
    }
        
}

