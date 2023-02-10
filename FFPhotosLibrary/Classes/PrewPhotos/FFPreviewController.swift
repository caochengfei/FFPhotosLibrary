//
//  VideoPreviewController.swift
//  VSTimeLine
//
//  Created by cofey on 2020/9/1.
//  Copyright © 2020 Versa. All rights reserved.
//

import UIKit
import RxSwift
import FFUITool
import SnapKit

typealias VideoPreViewCallback = (Bool, Array<FFAssetItem>)->()
public class FFPreviewController: UIViewController {
//    weak var delegate: SelectVideoViewProtocol?
    var videoPreViewCallback:VideoPreViewCallback?
    // 是否可以多选
    public var multipleSelect:Bool?
    
    // 选中的下标
    public var selectIndex:Int = 0 {
        didSet{
            currentModel = dataSource?[selectIndex]
//            self.resetUIState()
            self.addObserver()
        }
    }
  
    public var dataSource:[FFAssetItem]? {
        didSet{
            self.collectionView?.reloadData()
        }
    }
    
    public var selectDataSource:[FFAssetItem]?
    
    public var viewModel: FFPhotosViewModel?
    
    private var isFirstLoad:Bool = false
    private var disposeBag:DisposeBag = DisposeBag()
    
    private var currentModel:FFAssetItem?
    
    private var videoPlayerItem:VideoPlayerItem = VideoPlayerItem()
    
    private var collectionView:UICollectionView? = nil
    
    private var selectButton:UIButton?
    
    private var addButton: UIButton?
    
    fileprivate var oldSize: CGSize = .zero
    
    private var layout: UICollectionViewFlowLayout!
    
    // 侧滑返回按钮
    private lazy var leftBgView :UIView = {
        let bgView = UIView()
        bgView.frame = CGRect(x: 0, y: 0, width: 12.px, height: kScreenHeight)
        bgView.backgroundColor = "#000000".toRGB.withAlphaComponent(0.0001)
        return bgView
    }()
    
    
    lazy var backButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "cancel_white"), for: .normal)
        button.adjustsImageWhenHighlighted = false
        button.clickEdgeInsets = UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right: 10)
        button.addTarget(self, action: #selector(actionToBack), for: .touchUpInside)
        return button
    }()
        
    // 返回按钮
    @objc func actionToBack(){
        if selectDataSource != nil {
            self.videoPreViewCallback?(false, selectDataSource!)
        }
        if self.navigationController != nil {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true) {}
        }
    }
    
    //
    @objc func chooseBoxActionToSelect(){
//        actionToSelect(posotion: "预览页")
//        viewModel?.updateSelectedData(asset: <#T##FFAssetItem#>)
    }
    
    @objc func actionToImport(){
//        viewModel?.updateSelectedData(asset: <#T##FFAssetItem#>)
        if self.navigationController != nil {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true) {}
        }
    }
    
    private func addObserver(){
        _ = currentModel?.isSelected.asObservable().subscribe({[weak self] (event) in
//            self?.resetUIState()
        }).disposed(by: disposeBag)
        _ = currentModel?.selectNumber.asObservable().skip(1).subscribe({[weak self] (event) in
//            self?.resetUIState()
        }).disposed(by: disposeBag)
    }
    
    deinit {
        videoPlayerItem.resetConfig()
        videoPlayerItem.pause()
    }

    //MARK: -
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        view.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(kTopSafeHeight)
        }
        
        let itemSize = CGSize(width: view.width, height: view.height - FFScreenFit.instance().topSafeHeight - FFScreenFit.instance().bottomSafeHeight)
        
        layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = itemSize
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero
        
        view.layoutIfNeeded()
        collectionView = UICollectionView(frame: CGRect(x: 0, y: FFScreenFit.instance().topSafeHeight, width: itemSize.width, height: itemSize.height), collectionViewLayout: layout)
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.bounces = false
        collectionView?.backgroundColor = .black
        collectionView?.showsVerticalScrollIndicator = false
        collectionView?.isPagingEnabled = true
        if #available(iOS 11.0, *) {
            collectionView?.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
        }
        view.insertSubview(collectionView!, belowSubview: backButton)
//        view.addSubview(collectionView!)
        
        collectionView?.register(FFPreviewCell.self, forCellWithReuseIdentifier: NSStringFromClass(FFPreviewCell.self))
        
        view.addSubview(leftBgView)
        
        let index = selectIndex
        self.selectIndex = index

        let indexPath = IndexPath.init(item: selectIndex, section: 0)
        collectionView?.scrollToItem(at: indexPath, at: .right, animated: false)
        scrollViewDidEndDecelerating(collectionView!)
    }
}

extension FFPreviewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.dataArray.count ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(FFPreviewCell.self), for: indexPath) as! FFPreviewCell
        if let model = viewModel?.dataArray[indexPath.item] {
            cell.bindModel(model)
        }
        if let model = currentModel, let idx = viewModel?.dataArray.firstIndex(of: model) {
            if indexPath.row == idx && isFirstLoad == false {
                isFirstLoad = true
                cell.startPlay(videoPlayerItem)
            }
        }
        return cell
    }
}

extension FFPreviewController: UICollectionViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if layout.scrollDirection == .vertical {
            guard scrollView.contentOffset.y >= 0 else { return }
            let idx = Int(scrollView.contentOffset.y)/Int(scrollView.height)
            if let model = viewModel?.dataArray[idx], currentModel != model {
                currentModel = model
                addObserver()
    //            resetUIState()
                videoPlayerItem.resetConfig()
                let cell = self.collectionView?.cellForItem(at: IndexPath.init(row: idx, section: 0)) as? FFPreviewCell
                cell?.bindModel(model)
                cell?.startPlay(videoPlayerItem)
            }
        } else {
            guard scrollView.contentOffset.x >= 0 else {
                return
            }
            let idx = Int(scrollView.contentOffset.x) / Int(scrollView.width)
            if let model = viewModel?.dataArray[idx], currentModel != model {
                currentModel = model
                addObserver()
                videoPlayerItem.resetConfig()
                let cell = self.collectionView?.cellForItem(at: IndexPath(item: idx, section: 0)) as? FFPreviewCell
                cell?.bindModel(model)
                cell?.startPlay(videoPlayerItem)
            }
        }
      
    }
}
