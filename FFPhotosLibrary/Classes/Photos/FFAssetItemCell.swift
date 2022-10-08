//
//  VSPhotoAlbumCell.swift
//  VerSaVideo
//
//  Created by cofey on 2020/4/13.
//  Copyright © 2020 baige. All rights reserved.
//

import UIKit
import Photos
import RxSwift
import RxRelay
import FFUITool
import RxCocoa

typealias PreviewVideoCallback = ()->()
typealias DidSelectedCallback = ()->()

protocol FFAssetItemCellProtocol: AnyObject {
    func longPressAction(cell: FFAssetItemCell, data: FFAssetItem)
}

class FFAssetItemCell: UICollectionViewCell {
    weak var delegate: FFAssetItemCellProtocol?
    // rx资源释放
    var disposeBag:DisposeBag = DisposeBag()
    
    /// 选择框
    var showCheckBox = true { didSet { checkBox.isHidden = !showCheckBox } }

    // 模型
    var assetModel : FFAssetItem? { didSet { updateData(model: assetModel) } }
    
    // 图片imageView
    let imageView = UIImageView()
    
    // 数量label
    let numberLabel = UILabel()
    
    // 时常（仅视频显示）
    let durationLabel = UILabel()
    
    lazy var checkBox: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = 5.px
        button.layer.masksToBounds = true
        button.setTitleColor(UIColor.green, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.clickEdgeInsets = UIEdgeInsets.init(top: 20, left: 20, bottom: 20, right: 20)
        return button
    }()
    
    lazy var selectedBgView: UIView = {
        let maskView = UIView()
        maskView.backgroundColor = UIColor(red: 100/255.0, green: 190/255.0, blue: 240/255.0, alpha: 0.8);
        return maskView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isExclusiveTouch = true
        self.contentView.backgroundColor = UIColor.white
        setupUI()
        addActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("FFAssetItemCell销毁了")
    }
    
    func setupUI() {
        //图片
        self.contentView.addSubview(imageView)
        imageView.contentMode = .scaleAspectFill
        
        imageView.layer.cornerRadius = 2.px
        imageView.layer.masksToBounds = true
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        self.contentView.addSubview(selectedBgView)
        selectedBgView.layer.cornerRadius = 2.px
        selectedBgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        //时长
        self.contentView.addSubview(durationLabel)
        durationLabel.textColor = .black
        durationLabel.font = UIFont.systemFont(ofSize: 12)
        durationLabel.snp.makeConstraints { (make) in
            make.right.equalTo(imageView.snp.right).offset(-5.px)
            make.bottom.equalTo(imageView.snp.bottom).offset(-5.px)
        }
        
        self.contentView.addSubview(checkBox)
        checkBox.snp.makeConstraints { (make) in
            make.top.equalTo(self.contentView.snp.top).offset(5.px)
            make.right.equalTo(self.contentView.snp.right).offset(-5.px)
            make.size.equalTo(CGSize(width: 26.px, height: 26.px))
        }
        
        //数量
        self.contentView.addSubview(numberLabel)
        numberLabel.isHidden = true
        numberLabel.textColor = .white
        numberLabel.textAlignment = .center
        numberLabel.font = UIFont.boldSystemFont(ofSize: 35)
        numberLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }
    
    private func addActions() {
        let longPress = UILongPressGestureRecognizer.init(target: self, action: #selector(longPressAction(_:)))
        self.addGestureRecognizer(longPress)
    }
}

//MARK: - actions
extension FFAssetItemCell {
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        guard let point = touches.first?.location(in: self) else {
//            super.touchesEnded(touches, with: event)
//            return
//        }
//        if checkBox.frame.contains(point) {
//            //TODO: 选中
//
//        } else {
//            //TODO: 其他处理
////            previewVideoCallback?()
//        }
//        super.touchesEnded(touches, with: event)
//    }
//
    @objc func longPressAction(_ longPress: UILongPressGestureRecognizer) {
        if longPress.state == .began {
            guard let model = assetModel else { return }
            delegate?.longPressAction(cell: self, data: model)
        }
    }
}

extension FFAssetItemCell {
    //更新相册数据
    func updateData(model: FFAssetItem?) -> Void {
        disposeBag = DisposeBag()
        _ = assetModel?.isSelected.asObservable().subscribe({[weak self] (event) in
            self?.showShadowLayer()
        }).disposed(by: disposeBag)
        _ = assetModel?.selectNumber.asObservable().skip(1).subscribe({[weak self] (event) in
            self?.showShadowLayer()
        }).disposed(by: disposeBag)
        
        // 显示图片
        self.requestImage(model:model)
    }

    //显示图片跟视频时长
    func requestImage(model: FFAssetItem?) {
        let size = CGSize(width: self.width * UIScreen.main.scale, height: self.height * UIScreen.main.scale)
        if let asset = model?.asset {
            FFMediaLibrary.getThumbImage(asset: asset, size: size) { image in
                self.imageView.image = image
                model?.thumbImage = image
            }
        }
        if model?.asset?.mediaType == PHAssetMediaType.image {
            self.durationLabel.isHidden = true
        } else if model?.asset?.mediaType == .video{
            self.durationLabel.isHidden = false
            let duration: TimeInterval = model?.asset?.duration ?? 0
            self.durationLabel.text = FFMediaLibrary.durationFormat(duration: duration)
        }
    }
    
    // 改变背景色，增加图片下标
    func showShadowLayer() -> Void {
        let show: Bool = assetModel?.isSelected.value ?? false
        let selectCount: Int = assetModel?.selectNumber.value ?? 0
        if show == false {
            selectedBgView.isHidden = true
            checkBox.isHidden = false
//            checkBox.setBackgroundImage(UIImage(named: ""), for: .normal)
            numberLabel.isHidden = true
        } else {
            selectedBgView.isHidden = false
            checkBox.isHidden = true
            numberLabel.isHidden = false
            numberLabel.text =  "\(selectCount)"
        }
    }
}

