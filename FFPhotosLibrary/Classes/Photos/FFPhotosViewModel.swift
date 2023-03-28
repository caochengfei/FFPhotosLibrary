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
    func firstRequestPhotoAuthorError()
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
    public func getAllMedias(limit: Int = 0) {
        FFMediaLibrary.getDefaultAlbums(mediaType: mediaType) { success, album in
            if success == false {
                self.delegate?.firstRequestPhotoAuthorError()
            }
            self.albumArray.append(album)
            self.currentAlbum = album
            self.preAlbum = album
            self.loadMedia(with: album,mediaType: self.mediaType, limit: limit)
            self.delegate?.didFirstLoadedMediaFinish()
            DispatchQueue.global().async {
                self.getAllAlbum()
            }
        }
    }
    
    /// 获取相册目录
    /// - Parameter mediaType: video or image
    @discardableResult
    public func getAllAlbum() -> [FFAlbumItem]{
        let array = FFMediaLibrary.getAllAlbums(mediaType: mediaType)
        self.albumArray.append(contentsOf: array)
        self.albumArray.first?.isSelected = true
        return array
    }
        
    
    /// 根据相册获取对应素材
    /// - Parameters:
    ///   - album: 相册
    ///   - mediaType: 文件类型
    public func loadMedia(with album: FFAlbumItem?, mediaType: FFMediaLibraryType? = nil, limit: Int = 0) {
        guard let collection = album?.assetCollection else {
            return
        }
        let type =  mediaType != nil ? mediaType : self.mediaType
        self.assetsArray = FFMediaLibrary.getMedia(album: collection, mediaType: type ?? .image, ascending: nil, limit: limit)
        self.dataArray.removeAll()
        for index in 0..<self.assetsArray.count {
            let phAsset = self.assetsArray[index]
            /// 筛选录屏视频的过程 对速度会有点影响
            if self.config?.showRecordingVideoOnly == true, phAsset.mediaType == .video {
                if phAsset.pixelWidth > phAsset.pixelHeight {
                    continue
                }
                if let resource = PHAssetResource.assetResources(for: phAsset).first {
                    if  resource.originalFilename.prefix(8) != "RPReplay"{
                        continue
                    }
                }
            }
            let asset = FFAssetItem()
            asset.asset = phAsset
            self.checkSelectedStatus(asset: asset)
            self.dataArray.append(asset)
        }
        
        if album != self.currentAlbum {
            self.preAlbum = self.currentAlbum
            self.currentAlbum = album
        }
        self.delegate?.didUpdateMediaFinish()
        
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
        if config?.multipleSelected == true, selectedDataArray.first?.asset?.mediaType == .image {
            if containsAsset(asset: asset) {
                deleteAsset(asset: asset)
            } else {
                addAsset(asset: asset)
            }
        } else {
            if asset.isSelected.value == true {
                cleanAllSelected()
            } else {
                cleanAllSelected()
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
        if selectedDataArray.count >= (config?.maxSelectedCount ?? UInt.max) {return}
        asset.isSelected.accept(true)
        selectedDataArray.append(asset)
        if asset.asset?.mediaType == .image {
            dataArray.filter{($0.asset?.mediaType == .video)}.forEach({$0.enableSelect.accept(false)})
        }
    }
    
    private func deleteAsset(asset: FFAssetItem) {
        asset.isSelected.accept(false)
        selectedDataArray.removeAll { item in
            return item.asset?.localIdentifier == asset.asset?.localIdentifier
        }
        if selectedDataArray.count == 0 {
            dataArray.filter{($0.enableSelect.value == false)}.forEach({$0.enableSelect.accept(true)})
        }
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
            if item.enableSelect.value == false {
                item.enableSelect.accept(true)
            }
        }
    }
    
    private func refreshSelectStatus() {
       
    }
   
    private func sortSelectNumber() {
        //重新排序选中的位置
        for i in 0..<selectedDataArray.count {
            let model = selectedDataArray[i]
            model.selectNumber.accept(i + 1)
        }
    }
    
    func selectedItems(fromIndex: Int, toIndex: Int) {
        if isAdd {
            // add
            if fromIndex > toIndex {
                for i in (toIndex...fromIndex).reversed() {
                    if selectedDataArray.count >= (config?.maxSelectedCount ?? UInt.max) {continue}
                    let item = dataArray[i]
                    if !containsAsset(asset: item),item.enableSelect.value == true {
                        selectedDataArray.append(item)
                        item.isSelected.accept(true)
                    }
                    if selectedDataArray.first?.asset?.mediaType == .image {
                        dataArray.filter{($0.asset?.mediaType == .video)}.forEach({$0.enableSelect.accept(false)})
                    }
                }
            } else {
                for i in fromIndex...toIndex {
                    if selectedDataArray.count >= (config?.maxSelectedCount ?? UInt.max) {continue}
                    let item = dataArray[i]
                    if !containsAsset(asset: item), item.enableSelect.value == true {
                        selectedDataArray.append(item)
                        item.isSelected.accept(true)
                    }
                    if selectedDataArray.first?.asset?.mediaType == .image {
                        dataArray.filter{($0.asset?.mediaType == .video)}.forEach({$0.enableSelect.accept(false)})
                    }
                }
            }
            
        } else {
            // delete
            // add
            if fromIndex > toIndex {
                for i in (toIndex...fromIndex).reversed() {
                    let item = dataArray[i]
                    if containsAsset(asset: item) {
                        deleteAsset(asset: item)
                        item.isSelected.accept(false)
                    }
                }
            } else {
                for i in fromIndex...toIndex {
                    let item = dataArray[i]
                    if containsAsset(asset: item) {
                        deleteAsset(asset: item)
                        item.isSelected.accept(false)
                    }
                }
            }
            if selectedDataArray.count == 0 {
                dataArray.filter{($0.enableSelect.value == false)}.forEach({$0.enableSelect.accept(true)})
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

