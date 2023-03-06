//
//  VSPhotoAlbumModel.swift
//  VerSaVideo
//
//  Created by cofey on 2020/4/13.
//  Copyright © 2020 baige. All rights reserved.
//

import UIKit
import Photos
import RxSwift
import SnapKit
import RxRelay

enum DownloadingStatus:Int {
    case downloading
    case finish
    case notDownload // 未下载
}

/// 可观察协议
public protocol FFAssetItemObserverProtocol: AnyObject {
    /// 是否选中
    var isSelected: BehaviorRelay<Bool>{get set}
    /// 当前选中数字
    var selectNumber: BehaviorRelay<Int?>{get set}
}

open class FFAssetItem: NSObject,FFAssetItemObserverProtocol {
    public var isSelected: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    
    public var selectNumber: BehaviorRelay<Int?> = BehaviorRelay<Int?>(value: nil)
    // PHAsset
    public var asset:PHAsset?
    
    public var enableSelect: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: true)
            
    public func duration() ->TimeInterval {
        guard let asset = asset, asset.mediaType == .video else {
            return 0
        }
        return FFMediaLibrary.getVideoDuration(asset: asset)
    }
    
}

