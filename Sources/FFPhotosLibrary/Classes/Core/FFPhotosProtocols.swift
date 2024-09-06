//
//  FFPhotosProtocols.swift
//  Picroll
//
//  Created by cofey on 2022/8/18.
//

import Foundation
import UIKit

public protocol FFPhotosProtocol: AnyObject {
    
    /// 默认相册加载完毕，只有首次打开app会调用
    func photosDefaultLoadFinish(defaultArray: [FFAssetItem])
    
    /// 选中
    /// - Parameters:
    ///   - model: 当前数据
    ///   - selectedDataSource: 所有已选中集合
    func didSelectedItem(model: FFAssetItem?, selectedDataSource: [FFAssetItem])
    
    /// 确认当前选中
    /// - Parameter selectedDataSource: 所有已选中集合
    func didSelectedDone(selectedDataSource: [FFAssetItem])
    
    /// 点击预览
    /// - Parameters:
    ///   - model: 当前数据
    ///   - selectedDataSource: 所有已选中集合
    func didPrewItem(model: FFAssetItem, selectedDataSource: [FFAssetItem], allDataSource: [FFAssetItem])
    
    func scrollViewDidScroll(view: UIScrollView)
    
    func firstRequestPhotosAuthorError()
}

// 默认实现，使协议可选
extension FFPhotosProtocol {
    public func photosDefaultLoadFinish(defaultArray: [FFAssetItem]) {}
    
    public func didSelectedItem(model: FFAssetItem?, selectedDataSource: [FFAssetItem]) {}
    
    public func didSelectedDone(selectedDataSource: [FFAssetItem]) {}
    
    public func didPrewItem(model: FFAssetItem, selectedDataSource: [FFAssetItem], allDataSource: [FFAssetItem]) {}
    
    public func scrollViewDidScroll(view: UIScrollView){}
    
    public func firstRequestPhotosAuthorError() {}

}
