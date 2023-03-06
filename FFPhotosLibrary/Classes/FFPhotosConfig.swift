//
//  FFPhotosConfig.swift
//  FFPhotosLibrary
//
//  Created by cofey on 2023/3/6.
//

import Foundation

public struct FFPhotosConfig {
    /// 是否显示选择框
    public var showCheckBox: Bool = false
    /// 是否显示选中数字, 显示数字则会隐藏checkBox
    public var showCheckNumber: Bool = true
    /// 0 为无限制
    public var maxSelectedCount: Int = 0
    /// 是否可以多选 默认开启
    public var multipleSelected: Bool = true
    /// 数据源是否倒序
    public var reversed: Bool = true
    /// 初始化是否滚动到底部
    public var initScrollToBottom: Bool = true
    /// 列数
    public var columnCount: Int = 4
    
    public var minimumLineSpacing: CGFloat = 2
    
    public var minimumInteritemSpacing: CGFloat = 2
    
    public var selectedBackgroundColor: UIColor = "#478FB3".uicolor(alpha: 0.8)
    
    public var selectedTitleColor: UIColor = .white
    
    public var selectedTitleFont: UIFont = UIFont.boldSystemFont(ofSize: 30.px)
    
    public var videoIcon: UIImage?
    
    public var disableIcon: UIImage?
    
    public var showRecordingVideoOnly: Bool = false
    
    public init() {
        
    }
}
