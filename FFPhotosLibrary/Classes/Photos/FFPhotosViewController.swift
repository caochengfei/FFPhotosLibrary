//
//  SelectVideoViewController.swift
//  VSTimeLine
//
//  Created by cofey on 2020/4/27.
//  Copyright © 2020 Versa. All rights reserved.
//

import UIKit
import SnapKit
import Photos
import FFUITool

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
    
    public init() {
        
    }
}

public protocol FFPhotosCustomViewActions: AnyObject {
    func cancelButtonAction()
    func doneButtonAction()
    func selectedDataArray() -> [FFAssetItem]?
    func currentDataArray() -> [FFAssetItem]?
}

open class FFPhotosCustomBottomView: UIView, FFPhotosCustomViewActions {
    
    weak var delegate: FFPhotosCustomViewActions?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func cancelButtonAction() {
        delegate?.cancelButtonAction()
    }

    public func doneButtonAction() {
        delegate?.doneButtonAction()
    }
    
    public func selectedDataArray() -> [FFAssetItem]? {
        return delegate?.selectedDataArray()
    }
    
    public func currentDataArray() -> [FFAssetItem]? {
        return delegate?.currentDataArray()
    }

}


open class FFPhotosViewController: UIViewController {
    // 协议
    public weak var delegate: FFPhotosProtocol?
    // 配置文件
    public var config: FFPhotosConfig = FFPhotosConfig()
    // 加载的资源类型
    public var mediaType: FFMediaLibraryType = .image {
        didSet {
            viewModel.mediaType = mediaType
        }
    }
    
    public let viewModel = FFPhotosViewModel()
    
    public var customBottomView: FFPhotosCustomBottomView? {
        didSet {
            bottomViewChangeUpdateUI()
        }
    }
    
    
    public var albumArray: [FFAlbumItem] {
        return viewModel.albumArray
    }
        
    public lazy var collectionView : UICollectionView = {
        return _lazyCollectionView()
    }()
    
    private var startMovePoint: CGPoint?
    
    lazy var panGesture: UIPanGestureRecognizer = {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panAction(_ :)))
        return panGesture
    }()
    
    // Sliding multi-select
    var preIndexPath: IndexPath?
    var beginIndexPath: IndexPath?
    var autoScrollTop: Bool = false
    var timer: Timer?
    
    private override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required convenience public init(config: FFPhotosConfig, delegate: FFPhotosProtocol?, mediaType: FFMediaLibraryType = .image) {
        self.init(nibName: nil, bundle: nil)
        self.config = config
        self.viewModel.delegate = self
        self.viewModel.config = config
        self.mediaType = mediaType
        self.delegate = delegate
        self.viewModel.mediaType = mediaType
        
        if config.multipleSelected == true {
            self.view.addGestureRecognizer(panGesture)
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        viewModel.getAllMedias()
        addPhotoChangeObserver()
    }
    
    deinit {
        removePhotoChangeObserver()
    }

    func setupUI() {
        view.backgroundColor = .white.dynamicGray6
        self.view.addSubview(collectionView)
        bottomViewChangeUpdateUI()
    }
    
    func bottomViewChangeUpdateUI() {
        if let customBottomView = customBottomView {
            customBottomView.delegate = self
            self.view.addSubview(customBottomView)
            collectionView.snp.remakeConstraints { (make) in
                make.left.right.top.equalToSuperview()
                make.bottom.equalTo(customBottomView.snp.top)
            }
            
            customBottomView.snp.remakeConstraints({ make in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview()
                make.height.equalTo(customBottomView.height)
            })
        } else {
            collectionView.snp.remakeConstraints { (make) in
                make.left.right.top.equalToSuperview()
                make.left.right.top.bottom.equalToSuperview()
            }
        }
    }
    
    @objc func backButtonClickAction(){
        guard let nv = navigationController else {
            dismiss(animated: true)
            return
        }
        if nv.viewControllers.first == self {
            nv.dismiss(animated: true, completion: nil)
        } else {
            nv.popViewController(animated: true)
        }
    }
    
    /// 滚动到底部
    public func scrollToBottom(animate: Bool = false) {
        if self.viewModel.dataArray.count > 0 {
            let numberOfItem = collectionView.numberOfItems(inSection: 0);
            if numberOfItem > 0 {
                let indexPath = IndexPath(item: numberOfItem - 1, section: 0)
                collectionView.scrollToItem(at: indexPath, at: .bottom, animated: animate)
                scrollViewDidScroll(collectionView)
            }
        }
    }
}

//MARK: - actions
extension FFPhotosViewController {
    @objc func doneButtonClick() {
        delegate?.didSelectedDone(selectedDataSource: viewModel.selectedDataArray)
    }
}

extension FFPhotosViewController : UICollectionViewDataSource,UICollectionViewDelegate {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.dataArray.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(FFAssetItemCell.self), for: indexPath) as! FFAssetItemCell
        cell.showCheckBox = config.showCheckBox
        cell.selectedBgView.backgroundColor = config.selectedBackgroundColor
        cell.numberLabel.font = config.selectedTitleFont
        cell.numberLabel.textColor = config.selectedTitleColor
        cell.delegate = self
        let asset = viewModel.dataArray[indexPath.item]
        cell.assetModel = asset
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = viewModel.dataArray[indexPath.item]
        viewModel.updateSelectedData(asset: asset)
        delegate?.didSelectedItem(model: asset, selectedDataSource: viewModel.selectedDataArray)
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return UICollectionReusableView()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: self.view.width, height: 0)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.scrollViewDidScroll(view: scrollView)
    }
}

extension FFPhotosViewController: FFAssetItemCellProtocol {
    
    func longPressAction(cell: FFAssetItemCell, data: FFAssetItem) {
        self.delegate?.didPrewItem(model: data, selectedDataSource: self.viewModel.selectedDataArray, allDataSource: self.viewModel.dataArray)
    }
}

extension FFPhotosViewController: FFPhotosViewModelProtocol {
    public func didFirstLoadedMediaFinish() {
        didUpdateMediaFinish()
        delegate?.photosDefaultLoadFinish(defaultArray: viewModel.dataArray)
    }
    
    public func didUpdateMediaFinish() {
        collectionView.reloadData()
        if config.initScrollToBottom {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
                self.scrollToBottom()
            }
        }
    }
}

extension FFPhotosViewController: FFPhotosCustomViewActions {
    public func doneButtonAction() {
        delegate?.didSelectedDone(selectedDataSource: viewModel.selectedDataArray)
    }
    
    public func cancelButtonAction() {
        self.viewModel.cleanAllSelected()
        delegate?.didSelectedItem(model: nil, selectedDataSource: [FFAssetItem]())
    }
    
    public func selectedDataArray() -> [FFAssetItem]? {
        return self.viewModel.selectedDataArray
    }
    
    public func currentDataArray() -> [FFAssetItem]? {
        return self.viewModel.dataArray
    }
}

//MARK: - lazy View - get private
extension FFPhotosViewController {
    private func _lazyCollectionView() -> UICollectionView {
        let flowlayout = UICollectionViewFlowLayout()
        flowlayout.sectionInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
        flowlayout.minimumLineSpacing = config.minimumLineSpacing
        flowlayout.minimumInteritemSpacing = config.minimumInteritemSpacing
        
        let width = (view.width - flowlayout.minimumInteritemSpacing * CGFloat(config.columnCount - 1) - flowlayout.sectionInset.left - flowlayout.sectionInset.right) / CGFloat(config.columnCount)
        let size = CGSize(width: width, height: width)
        
        flowlayout.itemSize = size
        flowlayout.scrollDirection = .vertical
        
        let view = UICollectionView(frame: CGRect(x: 0, y: 44.px, width: self.view.height, height: self.view.height), collectionViewLayout: flowlayout)
        view.register(FFAssetItemCell.self, forCellWithReuseIdentifier: NSStringFromClass(FFAssetItemCell.self))
        view.backgroundColor = "#E6E6E6".toRGB.dynamicGray6
        view.delegate = self
        view.dataSource = self
        view.showsVerticalScrollIndicator = false
        return view
    }
}

extension FFPhotosViewController: PHPhotoLibraryChangeObserver {
    func addPhotoChangeObserver() {
        PHPhotoLibrary.shared().register(self)
    }
    
    func removePhotoChangeObserver() {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            let changes = changeInstance.changeDetails(for: self.viewModel.assetsArray)
            if (changes != nil) {
                self.cancelButtonAction()
                self.viewModel.loadMedia(with: self.viewModel.currentAlbum, mediaType: self.viewModel.mediaType)
            }
        }
    }
}

extension FFPhotosViewController {
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if let flowlayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let width = (size.width - flowlayout.minimumInteritemSpacing * CGFloat(config.columnCount - 1) - flowlayout.sectionInset.left - flowlayout.sectionInset.right) / CGFloat(config.columnCount)
            let size = CGSize(width: width, height: width)
            flowlayout.itemSize = size
            flowlayout.invalidateLayout()
        }
    }
}

//MARK: -  Sliding multi-select
extension FFPhotosViewController {
    
    func startTimer() {
        if timer == nil {
            self.timer = Timer(timeInterval: 0.003, target: self, selector: #selector(autoScroll), userInfo: nil, repeats: true)
            RunLoop.current.add(timer!, forMode: .default)
        }
    }
    
    @objc func autoScroll() {
        let offSetY = self.collectionView.contentOffset.y
        if autoScrollTop == true {
            if offSetY < 0 {
                return
            }
            self.collectionView.contentOffset.y = offSetY - 1
        }
       
        if autoScrollTop == false {
            if offSetY + collectionView.height > collectionView.contentSize.height {
                return
            }
            self.collectionView.contentOffset.y = offSetY + 1
        }
    }
    
    func endTimer() {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    @objc func panAction(_ panGesture: UIPanGestureRecognizer) {
        if panGesture.state == .began {
            if let indexPath = self.collectionView.indexPathForItem(at: panGesture.location(in: self.collectionView)) {
                beginIndexPath = indexPath
                viewModel.isAdd = !viewModel.containsAsset(asset: viewModel.dataArray[indexPath.item])
            }
        }
        
        if panGesture.state == .ended || panGesture.state == .cancelled {
            endTimer()
            viewModel.mergeTempSelectedItems()
            delegate?.didSelectedItem(model: nil, selectedDataSource: viewModel.selectedDataArray)
        }
        
        if panGesture.state == .changed {
            guard let `beginIndexPath` = beginIndexPath else {
                return
            }
            let point = panGesture.location(in: self.collectionView)
            let translate = panGesture.translation(in: self.view)
            let absX = abs(translate.x)
            let absY = abs(translate.y)
            if max(absX, absY) < 15 {
                return
            }
            if absX > absY {
                if translate.x < 0 {
                    // 左
                } else {
                    // 右
                }
            } else if absY > absX {
                if point.y < self.collectionView.contentOffset.y {
                    autoScrollTop = true
                    startTimer()
                } else if point.y > self.collectionView.contentOffset.y + self.collectionView.size.height - 50 {
                    autoScrollTop = false
                    startTimer()
                } else {
                    endTimer()
                }
                
                if translate.y < 0 {
                    // 上
                } else {
                    // 下
                }
            }
            if let indexPath = self.collectionView.indexPathForItem(at: panGesture.location(in: self.collectionView)), indexPath != preIndexPath {
                viewModel.selectedItems(fromIndex: beginIndexPath.item, toIndex: indexPath.item)
                preIndexPath = indexPath
            }
        }
    }
}
