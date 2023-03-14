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
    /// 是否可以多选 默认开启
    public var multipleSelected: Bool = true
    /// 数据源是否倒序
    public var reversed: Bool = true
    /// 初始化是否滚动到底部
    public var initScrollToBottom: Bool = true
    /// 列数
    public var columnCount: Int = 4
    /// 最小间隔
    public var minimumLineSpacing: CGFloat = 2
    /// 最大间隔
    public var minimumInteritemSpacing: CGFloat = 2
    /// 选中状态的背景色
    public var selectedBackgroundColor: UIColor = "#478FB3".uicolor(alpha: 0.8)
    /// 选中状态的颜色
    public var selectedTitleColor: UIColor = .white
    /// 选中状态的字体
    public var selectedTitleFont: UIFont = UIFont.boldSystemFont(ofSize: 30.px)
    /// cell中标记为视频的icon
    public var videoIcon: UIImage?
    /// cell不可选中时的图片
    public var disableIcon: UIImage?
    /// 是否显示视频时候只显示录屏视频
    public var showRecordingVideoOnly: Bool = false
    /// 最大可选择数量
    public var maxSelectedCount: UInt = UInt.max
    
    public init() {
        
    }
}
