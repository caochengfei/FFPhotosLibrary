//
//  VideoPreViewCell.swift
//  VSTimeLine
//
//  Created by cofey on 2020/9/1.
//  Copyright © 2020 Versa. All rights reserved.
//

import UIKit
import Photos
//import RxSwift
import FFUITool

class FFPreviewCell: UICollectionViewCell {
    private let group = DispatchGroup()
    
    private var isSeek:Bool = false
    
    private var playerItem:VideoPlayerItem?
    
    let spinner = UIActivityIndicatorView(style: .whiteLarge)
    
    private var assetmodel:FFAssetItem?
    
    private var activeView:UIActivityIndicatorView = UIActivityIndicatorView(style: .white)
    
    lazy private var preview:UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()
    
    lazy private var preImageView:UIImageView = {
        let imgView = UIImageView()
        imgView.isHidden = true
        imgView.contentMode = .scaleAspectFit
        imgView.backgroundColor = .black
        return imgView
    }()
    
    lazy private var playButton:UIButton = {
        let pB = UIButton()
        pB.addTarget(self, action: #selector(actionToPlay), for: .touchUpInside)
//        pB.setImage(UIImage.svgImage(named: "icon_Muisc_Play_White"), for: .selected)
//        pB.setImage(UIImage.svgImage(named: "icon_Muisc_Stop_White"), for: .normal)
        return pB
    }()
    
    lazy private var startDatelabel:UILabel = {
        let l = UILabel()
        l.textAlignment = .right
//        l.textColor = .appColor(.textLight)
//        l.font = .appFont(.textBodyMainSmallBold)
        return l
    }()
    
    lazy private var endDateLabel:UILabel = {
        let l = UILabel()
        l.textAlignment = .left
//        l.textColor = .appColor(.textLight)
//        l.font = .appFont(.textBodyMainSmallBold)
        return l
    }()
    
    
    private lazy var sliderView: FFSliderView = {
        let sliderView = FFSliderView(frame: .zero)
        return sliderView
    }()
    
    @objc func actionToChangeValue(){
        self.isSeek = true
//        self.startDatelabel.text = Double(sliderView.value).formatNormal(minValue: 0)
        let seekValue = Int64(sliderView.value)
        let time = CMTimeMake(value: seekValue, timescale: 1)
        self.playerItem?.seek(toTime: time)
    }
    
    @objc func actionToTouchUpInside(){
        self.isSeek = false
        self.playerItem?.play()
        if playButton.isSelected == true {
            playButton.isSelected = false
        }
    }
    
    @objc func actionToPlay() {
        playButton.isSelected = !playButton.isSelected
        if playButton.isSelected == true {
            self.playerItem?.pause()
        }else{
            self.playerItem?.play()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(preview)
        contentView.addSubview(playButton)
        contentView.addSubview(startDatelabel)
        contentView.addSubview(endDateLabel)
        contentView.addSubview(sliderView)
        contentView.addSubview(preImageView)
        activeView.color = .darkGray
        contentView.addSubview(activeView)
        
        contentView.addSubview(spinner)
        playButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(20.rem)
            make.bottom.equalToSuperview().inset(40.rem)
            make.size.equalTo(CGSize(width: 18.rem, height: 18.rem))
        }

        
        startDatelabel.snp.makeConstraints { (make) in
            make.left.equalTo(playButton.snp.right).offset(20.rem)
            make.centerY.equalTo(playButton.snp.centerY)
            make.height.equalTo(18.rem)
        }
        
        endDateLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().inset(20.rem)
            make.centerY.equalTo(playButton.snp.centerY)
            make.height.equalTo(18.rem)
        }

        sliderView.snp.makeConstraints { (make) in
            make.left.equalTo(startDatelabel.snp.right).offset(-40)
            make.right.equalTo(endDateLabel.snp.left).offset(40)
            make.centerY.equalTo(playButton.snp.centerY)
            make.height.equalTo(31.rem)
        }
        
        preview.snp.makeConstraints({ (make) in
            make.right.equalToSuperview()
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(playButton.snp.top).offset(-30.rem)
        })
        
        preImageView.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        activeView.snp.makeConstraints { (make) in
            make.center.equalTo(preImageView)
        }
        
        playButton.clickEdgeInsets = UIEdgeInsets.init(top: 20, left: 20, bottom: 20, right: 20)
        spinner.center = CGPoint(x: self.contentView.width/2, y: self.contentView.height/2)
        spinner.color = .white
        
        
        sliderView.sliderDidChange = {[weak self] (value, minValue, maxValue) in
            self?.actionToChangeValue()
        }
        sliderView.sliderDidEnded = {[weak self] (value) in
            self?.actionToPlay()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerItem?.playLayer.frame = preview.frame
        playerItem?.playLayer.frame.size = CGSize(width: self.bounds.width, height: preview.frame.height)
    }
    
    func bindModel(_ model:FFAssetItem){
//        NotifyCenter.removeObserver(self)
        self.assetmodel = model
        preview.alpha = 0
        
        self.playButton.isHidden = true
        self.startDatelabel.isHidden = true
        self.endDateLabel.isHidden = true
        self.sliderView.isHidden = true
        self.spinner.isHidden = true
        if let asset = self.assetmodel?.asset,
           asset.mediaType == .image {
            preImageView.isHidden = false
            let options = PHImageRequestOptions()
            options.version = .current
            options.deliveryMode = .opportunistic
            options.isNetworkAccessAllowed = true
            let size = CGSize(width: UIScreen.main.bounds.width * UIDevice.deviceScale, height: UIScreen.main.bounds.height * UIDevice.deviceScale)
            let resourceArray = PHAssetResource.assetResources(for: asset)
            if resourceArray.first?.value(forKey: "locallyAvailable") as? Bool == false {
                self.activeView.startAnimating()
            }
            FFMediaLibrary.getThumbImage(asset: asset, size: size ,isPrew:  true) { image in
                self.activeView.stopAnimating()
                self.preImageView.image = image
            }
            return
        }
        self.preImageView.isHidden = true
        self.playButton.isHidden = false
        self.startDatelabel.isHidden = false
        self.endDateLabel.isHidden = false
        self.sliderView.isHidden = false
        
        let start:TimeInterval = 0
        self.startDatelabel.text = "00:00"
        self.endDateLabel.text = "00:00"
        self.sliderView.value = 0
        self.playButton.isSelected = false
       
//        NotifyCenter.addObserver(self, selector: #selector(enterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    
   
    }
    @objc func enterBackground() {
        self.playerItem?.pause()
        self.playButton.isSelected = true
    }

    func startPlay(_ playerItem:VideoPlayerItem){
        self.playerItem = playerItem
 
        if let asset = self.assetmodel?.asset, asset.mediaType == .video  {
            
            let options = PHVideoRequestOptions()
            options.version = .current
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            
            activeView.startAnimating()
            playerItem.requestID =  PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) {[weak self] (item, hash) in
                DispatchQueue.main.async {
                    
                    guard let sself = self, let item = item else {
                        return
                    }
                    
                    sself.activeView.stopAnimating()
                    sself.endDateLabel.text = sself.changeTimeFormat(timeValue: CMTimeGetSeconds(item.duration))
                    
                    if let time = sself.assetmodel?.asset?.duration {
                        sself.sliderView.maxValue = Float(time)
                    }
                
                    sself.preview.alpha = 1
                 
                    playerItem.addToSuperLayer(sself.getPreViewRect(), (sself.preview.layer))
                    playerItem.replaceCurrentItem(item)
                    playerItem.play()
                    
                    sself.addPlayObserver()
                }
            }
        }
    }
    
    private func changeTimeFormat(timeValue: Float64) -> String {
        var string = "";
        let time = Int(timeValue);
        if time < 3600 {
            let minutes = time / 60;
            let seconds = time % 60;
            string = String(format: "%02d:%02d", arguments: [minutes,seconds]);
        } else {
            string = String(format: "%2d:%2d:%2d", [time / 3600, time / 3600 / 60, (time / 3600 / 60) % 60]);
        }
        return string;
    }
    
    private func addPlayObserver(){
        playerItem?.observerProgress {[weak self] (progress) in
            guard let sself = self else {
                return
            }
            if sself.isSeek == false {
                
                /// 拖动进度条后, 回调的进度不是seek的位置进度,导致进度条回跳,所以如果回调进度小于进度条的进度 则不进行刷新
                let currentValue = sself.sliderView.value
                if progress > currentValue {
//                    sself.startDatelabel.text = Double(progress).formatNormal(minValue: 0)
                    sself.startDatelabel.text = sself.changeTimeFormat(timeValue: Float64(progress))
                    sself.sliderView.value = Float(progress)
                }
            }
        }
        
        playerItem?.videoPlayerDidEndPlay = {[weak self] in
            DispatchQueue.main.async {
                guard let sself = self else {
                    return
                }
                sself.playButton.isSelected = true
                sself.sliderView.value = 0
                sself.startDatelabel.text = "00:00"
                sself.playerItem?.seek(toTime: CMTimeMake(value: 0, timescale: 1))
            }
        }
    }
    
    private func getPreViewRect() -> CGRect{
        let pWidth = self.assetmodel?.asset?.pixelWidth ?? 0
        let pHeight = self.assetmodel?.asset?.pixelHeight ?? 0
        
        guard pWidth > 0, pHeight > 0 else {
            return .zero
        }
        
        var height:CGFloat =  0
        var width:CGFloat = 0
        var X:CGFloat = 0
        var Y:CGFloat = 0
        
        if pWidth > pHeight {
            width = self.preview.width
            height = CGFloat(Int(width)*pHeight/pWidth)
            Y = (self.preview.height - height)/2
        }else{
            height = self.preview.height
            width = CGFloat(Int(height)*pWidth/pHeight)
            X = (self.preview.width-width)/2
        }
        
        return CGRect(x: X, y: Y, width: width, height: height)
    }
}
