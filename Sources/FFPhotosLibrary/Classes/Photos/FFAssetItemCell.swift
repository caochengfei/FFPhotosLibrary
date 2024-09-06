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

class FFAssetInfoView: UIView {
    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = UIColor.white
        return imageView
    }()
    
    lazy var durationLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 10)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = "#000000".uicolor(alpha: 0.5)
        addSubview(iconImageView)
        addSubview(durationLabel)
        
        iconImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(2)
            make.centerY.equalToSuperview()
        }
        
        durationLabel.snp.makeConstraints { make in
            make.left.equalTo(iconImageView.snp.right).offset(3)
            make.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FFAssetDisableView: UIView {
    lazy var disableImageView: UIImageView = {
        let disableImageView = UIImageView()
        return disableImageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        self.isUserInteractionEnabled = false
        addSubview(disableImageView)
        
        disableImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FFAssetItemCell: UICollectionViewCell {
    weak var delegate: FFAssetItemCellProtocol?
    // rx资源释放
    var disposeBag:DisposeBag? = DisposeBag()

    // 模型
    var assetModel : FFAssetItem? {
        didSet {
            if let phRequestID = oldValue?.phRequestID {
                PHImageManager.default().cancelImageRequest(phRequestID)
            }
            updateData(model: assetModel)
        }
    }
    
    // 图片imageView
    let imageView = UIImageView()
    
    // 数量label
    let numberLabel = UILabel()
    
    let infoView = FFAssetInfoView()
    
    let disableView = FFAssetDisableView()

    lazy var checkBox: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = 5.rem
        button.layer.masksToBounds = true
        button.setTitleColor(UIColor.green, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
//        button.clickEdgeInsets = UIEdgeInsets.init(top: 20, left: 20, bottom: 20, right: 20)
        return button
    }()
    
    var showCheckBox: Bool = false {
        didSet {
            if showCheckBox, checkBox.superview == nil {
                self.contentView.addSubview(checkBox)
                checkBox.snp.makeConstraints { (make) in
                    make.top.equalTo(self.contentView.snp.top).offset(5.rem)
                    make.right.equalTo(self.contentView.snp.right).offset(-5.rem)
                    make.size.equalTo(CGSize(width: 26.rem, height: 26.rem))
                }
            } else {
                checkBox.removeFromSuperview()
                checkBox.snp.removeConstraints()
            }
        }
    }
    
    lazy var selectedBgView: UIView = {
        let maskView = UIView()
        maskView.backgroundColor = UIColor(red: 100/255.0, green: 190/255.0, blue: 240/255.0, alpha: 0.8);
        return maskView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.backgroundColor = UIColor.white.dynamicGray6
        setupUI()
        addActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        //        
        //        deinitPrint()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
        self.assetModel = nil
        disposeBag = nil
    }
    
    func setupUI() {
        //图片
        self.contentView.addSubview(imageView)
        imageView.contentMode = .scaleAspectFill
        
        imageView.layer.masksToBounds = true
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        contentView.addSubview(infoView)
        infoView.isHidden = true
        infoView.snp.makeConstraints { make in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(12)
        }
        
        contentView.addSubview(disableView)
        disableView.isHidden = true
        disableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        self.contentView.addSubview(selectedBgView)
        selectedBgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        //数量
        self.contentView.addSubview(numberLabel)
        numberLabel.isHidden = true
        numberLabel.textColor = UIColor.white.dynamicGray6
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
        }).disposed(by: disposeBag!)
        _ = assetModel?.selectNumber.asObservable().skip(1).subscribe({[weak self] (event) in
            self?.showShadowLayer()
        }).disposed(by: disposeBag!)
        _ = assetModel?.enableSelect.asObservable().subscribe({[weak self] (event) in
            self?.disableView.isHidden = event.element ?? true
            self?.isUserInteractionEnabled = event.element ?? true
        }).disposed(by: disposeBag!)
        // 显示图片
        self.requestImage(model:model)
    }

    //显示图片跟视频时长
    func requestImage(model: FFAssetItem?) {
        let size = CGSize(width: self.width * UIDevice.deviceScale, height: self.height * UIDevice.deviceScale)
        if let asset = model?.asset {
            model?.phRequestID = FFMediaLibrary.getThumbImage(asset: asset, size: size,isPrew: true) {[weak self] image in
                self?.imageView.image = image
                self?.assetModel?.phRequestID = nil
            }
        }
        if model?.asset?.mediaType == PHAssetMediaType.image {
            self.infoView.isHidden = true
        } else if model?.asset?.mediaType == .video{
            self.infoView.isHidden = false
            self.infoView.durationLabel.text = FFMediaLibrary.videoDuration(videoAsset: model?.asset)
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

