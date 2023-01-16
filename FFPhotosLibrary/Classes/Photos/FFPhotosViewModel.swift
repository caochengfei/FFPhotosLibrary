//
//  FFPhotosViewModel.swift
//  Picroll
//
//  Created by cofey on 2022/8/18.
//

import Foundation
import FFUITool
import Photos

public protocol FFPhotosViewModelProtocol: AnyObject {
    func didFirstLoadedMediaFinish()
    func didUpdateMediaFinish()
}

public class FFPhotosViewModel: NSObject {
    
    public weak var delegate: FFPhotosViewModelProtocol?
    
    public var config: FFPhotosConfig?
    
    public var dataArray = [FFAssetItem]()
    
    public var assetsArray = PHFetchResult<PHAsset>()
    
    public var selectedDataArray = [FFAssetItem]()
    
    public var albumArray = [FFAlbumItem]()
    
    public var currentAlbum: FFAlbumItem?
    
    public var preAlbum: FFAlbumItem?
    
    public var mediaType: FFMediaLibraryType = .image
        
    var isAdd: Bool = true
}

extension FFPhotosViewModel {
    
    /// 获取默认相册
    /// - Parameter mediaType: video or image
    public func getAllMedias() {
        FFMediaLibrary.getDefaultAlbums(mediaType: mediaType) { success, album in
            self.albumArray.append(album)
            self.currentAlbum = album
            self.preAlbum = album
            self.loadMedia(with: album,mediaType: self.mediaType)
            self.delegate?.didFirstLoadedMediaFinish()
            self.getAllAlbum()
        }
    }
    
    /// 获取相册目录
    /// - Parameter mediaType: video or image
    @discardableResult
    public func getAllAlbum() -> [FFAlbumItem]{
        let array = FFMediaLibrary.getAllAlbums(mediaType: mediaType)
        self.albumArray.append(contentsOf: array)
        return array
    }
        
    
    /// 根据相册获取对应素材
    /// - Parameters:
    ///   - album: 相册
    ///   - mediaType: 文件类型
    public func loadMedia(with album: FFAlbumItem?, mediaType: FFMediaLibraryType? = nil) {
        guard let collection = album?.assetCollection else {
            return
        }
        let type =  mediaType != nil ? mediaType : self.mediaType
        assetsArray = FFMediaLibrary.getMedia(album: collection, mediaType: type!)
        self.dataArray.removeAll()
        for index in 0..<assetsArray.count {
            let asset = FFAssetItem()
            asset.asset = assetsArray[index]
            checkSelectedStatus(asset: asset)
            self.dataArray.append(asset)
        }
        
        if self.config?.reversed == false {
            self.dataArray = self.dataArray.reversed()
        }
        if album != self.currentAlbum {
            self.preAlbum = self.currentAlbum
            self.currentAlbum = album
        }
        delegate?.didUpdateMediaFinish()
    }
    
    
    /// 删除所有选中
    func cleanAllSelected() {
        for item in selectedDataArray {
            item.isSelected.accept(false)
            item.selectNumber.accept(nil)
        }
        selectedDataArray.removeAll()
        
        for item in dataArray {
            if item.isSelected.value == true {
                item.isSelected.accept(false)
                item.selectNumber.accept(nil)
            }
        }
    }
}

//MARK: - CURD
extension FFPhotosViewModel {
    
    private func checkSelectedStatus(asset: FFAssetItem) {
        if let selectedAsset = selectAsset(asset: asset) {
            asset.isSelected.accept(selectedAsset.isSelected.value)
            asset.selectNumber.accept(selectedAsset.selectNumber.value)
        }
    }
    
    func updateSelectedData(asset:FFAssetItem) {
        if config?.multipleSelected == true {
            if containsAsset(asset: asset) {
                deleteAsset(asset: asset)
            } else {
                addAsset(asset: asset)
            }
        } else {
            cleanAllSelected()
            if asset.isSelected.value == false {
                addAsset(asset: asset)
            }
        }
        sortSelectNumber()
        refreshSelectStatus()
    }
    
    func containsAsset(asset:FFAssetItem) -> Bool {
        for selAsset in selectedDataArray {
            if let selId = selAsset.asset?.localIdentifier,
               let curId = asset.asset?.localIdentifier,
               selId == curId {
                return true
            }
        }
        return false
    }
    
    private func selectAsset(asset: FFAssetItem) -> FFAssetItem? {
        for selAsset in selectedDataArray {
            if let selId = selAsset.asset?.localIdentifier,
               let curId = asset.asset?.localIdentifier,
               selId == curId {
                return selAsset
            }
        }
        return nil
    }
    
    private func addAsset(asset: FFAssetItem) {
        asset.isSelected.accept(true)
        selectedDataArray.append(asset)
    }
    
    private func deleteAsset(asset: FFAssetItem) {
        asset.isSelected.accept(false)
        selectedDataArray.removeAll { item in
            return item.asset?.localIdentifier == asset.asset?.localIdentifier
        }
    }
    
    private func refreshSelectStatus() {
       
    }
   
    private func sortSelectNumber() {
        //重新排序选中的位置
        let tempIndex = selectedDataArray.count
        for i in 0..<selectedDataArray.count {
            let model = selectedDataArray[i]
            model.selectNumber.accept(i + 1)
        }
        
//        for i in 0..<tempSelectedArray.count {
//            let model = tempSelectedArray[i]
//            model.selectNumber.accept(tempIndex + i + 1)
//        }
    }
    
    func selectedItems(fromIndex: Int, toIndex: Int) {
        if isAdd {
            // add
            if fromIndex > toIndex {
                for i in (toIndex...fromIndex).reversed() {
                    let item = dataArray[i]
                    item.isSelected.accept(true)
                    if !containsAsset(asset: item) {
                        selectedDataArray.append(item)
                    }
//                    tempSelectedArray.append(item)
                }
            } else {
                for i in fromIndex...toIndex {
                    let item = dataArray[i]
                    item.isSelected.accept(true)
                    if !containsAsset(asset: item) {
                        selectedDataArray.append(item)
                    }
                }
            }
        } else {
            // delete
            // add
            if fromIndex > toIndex {
                for i in (toIndex...fromIndex).reversed() {
                    let item = dataArray[i]
                    item.isSelected.accept(false)
                    if containsAsset(asset: item) {
                        deleteAsset(asset: item)
                    }
                }
            } else {
                for i in fromIndex...toIndex {
                    let item = dataArray[i]
                    item.isSelected.accept(false)
                    if containsAsset(asset: item) {
                        deleteAsset(asset: item)
                    }
                }
            }
            
        }
        sortSelectNumber()
        refreshSelectStatus()
    }
    
    func mergeTempSelectedItems() {
        sortSelectNumber()
        refreshSelectStatus()
    }
}

