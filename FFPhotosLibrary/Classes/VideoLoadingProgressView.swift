////
////  VideoLoadingProgressView.swift
////  VSTimeLine
////
////  Created by cofey on 2020/6/5.
////  Copyright © 2020 Versa. All rights reserved.
////
//
//import Foundation
//import RxSwift
//import YYImage
//import UIKit
//public let videoLoadingViewTag = 10382
//
//class VideoLoadingProgressView: UIView {
//    var reqIds:[PHImageRequestID] = [PHImageRequestID]()
//    public var loadingString:String = "视频加载中"
//    
//    private var needProgress: Bool = true
//    
//    // 分母 用来计算进度的占比
//    public var denominator: Float = 1
//    
//    var content:String? {
//        didSet {
////            if content?.contains("模板") == true {
////                needProgress = false
////            }
//            loadingLabel.text = content
//        }
//    }
//    
//    var needHiddenClose:Bool = false {
//        didSet{
//            closeBtn.isHidden = needHiddenClose
//        }
//    }
//    
//    var progress:Float = 0 {
//        didSet {
//            if needProgress {
//                loadingLabel.text = "\(content ?? loadingString) \(Int(progress * 100))%"
//            }
//        }
//    }
//    
//    private var loadingTimer: Timer?
//    
//    var willRemoveClosure:(()->())?
//    
//    deinit {
//        animateView.removeObserverBlocks()
//    }
//    
//    fileprivate lazy var contentView:UIView = {
//        let view = UIView()
//        view.layer.cornerRadius = .appCornerRadius(.large)
//        view.clipsToBounds = true
//        view.backgroundColor = .appColor(.background)
//        return view
//    }()
//    
//    fileprivate lazy var closeBtn:UIButton = {
//        let btn = UIButton(type: .custom)
//        btn.setImage(UIImage.svgImage(named: "icon_Popup_Close"), for: .normal)
//        btn.touchExtendInset = kAppTouchExtendLowInset
//        btn.size = CGSize(width: smartFit(value: 14), height: smartFit(value: 14))
//        btn.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
//        return btn
//    }()
//    
//    fileprivate lazy var animateView: YYAnimatedImageView = {
//        let view = YYAnimatedImageView()
//        view.contentMode = .scaleAspectFit
//        view.isUserInteractionEnabled = false
//        return view
//    }()
//    
//    fileprivate lazy var loadingLabel: UILabel = {
//        let label = UILabel()
//        label.font = .appFont(.textBodyMain)
//        label.textColor = .appColor(.textTitle)
//        label.textAlignment = .center
//        return label
//    }()
//    
//    public class func showToView(view: UIView?, content: String? = "视频加载中") -> VideoLoadingProgressView? {
//        if let superView = view {
//            let loading = VideoLoadingProgressView()
//            loading.frame = superView.bounds
//            loading.tag = videoLoadingViewTag
//            loading.content = content
//            superView.addSubview(loading)
//            loading.startLoading()
//            return loading
//        }
//        return nil
//    }
//    
//    public class func dismiss(view: UIView?) {
//        guard let superView = view else {
//            return
//        }
//        if let loading = superView.viewWithTag(videoLoadingViewTag) as? VideoLoadingProgressView {
//            loading.removeFromSuperview()
//            loading.cleanTimerIfNeed()
//        }
//    }
//    
//    public class func refershProgress(superView: UIView?, progress: Float) {
//        guard let `superView` = superView else {
//            return
//        }
//        if let loading = superView.viewWithTag(videoLoadingViewTag) as? VideoLoadingProgressView {
//            loading.progress = progress
//        }
//    }
//    
//    
//    public class func globalView() -> VideoLoadingProgressView? {
//        if let view =  UIApplication.shared.keyWindow?.viewWithTag(videoLoadingViewTag) as? VideoLoadingProgressView {
//            return view
//        }
//        return nil
//    }
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupUI()
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    
//    private func setupUI() {
//        backgroundColor = .appColor(.backgroundDark, alpha: .alpha50)
//        
//        addSubview(contentView)
//        contentView.addSubview(animateView)
//        contentView.addSubview(closeBtn)
//        contentView.addSubview(loadingLabel)
//    }
//    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        contentView.size = CGSize(width: smartFit(value: 195), height: smartFit(value: 151))
//        contentView.center = CGPoint(x: width / 2, y: height / 2)
//        animateView.size = CGSize(width: smartFit(value: 125), height: smartFit(value: 90))
//        animateView.centerX = contentView.width / 2
//        animateView.top = smartFit(value: 10)
//        loadingLabel.frame = CGRect(x: 0, y: animateView.bottom + 10.fit, w: contentView.width, h: smartFit(value: 21))
//        
//        closeBtn.origin = CGPoint(x: smartFit(value: 10), y: smartFit(value: 10))
//    }
//    
//    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
//        let flag = super.point(inside: point, with: event)
//        return flag
//    }
//    
//    func startLoading() {
//        if animateView.currentIsPlayingAnimation == false {
//            animateView.removeObserverBlocks()
//            if let filePath = Bundle.main.path(forResource: "icon_video_loading", ofType: "png") {
//                animateView.image = YYImage(contentsOfFile: filePath)
//            }
//            animateView.currentAnimatedImageIndex = 0
//        }
//    }
//    
//    func startSuccessAnimation(completion:(()->())?) {
//        completion?()
//    }
//    
//    @objc func buttonAction() {
//        willRemoveClosure?()
//    }
//    
//    /// 是否需要加载空跑的进度
//    func loadingAverageProgressIfNeed (completion:@escaping (()->())) {
//        
//        guard progress < 1, progress > 0 else {
//            completion()
//            return
//        }
//        cleanTimerIfNeed()
//        loadingTimer = Timer(timeInterval: 0.003, repeats: true, block: {[weak self] (timer) in
//            guard let `self` = self else{return}
//            self.progress = max(self.progress + 0.01, self.progress)
//            vsPrint("剩余进度加载:\(self.progress)")
//            if self.progress >= 1 {
//                self.cleanTimerIfNeed()
//                completion()
//            }
//        })
//        
//        if let timer = loadingTimer {
//            RunLoop.main.add(timer, forMode: .common)
//        }
//    }
//    
//    public func cleanTimerIfNeed() {
//        if loadingTimer != nil {
//            loadingTimer?.invalidate()
//            loadingTimer = nil
//        }
//    }
//}
//
//class VSTextFastLoadingProgressView: VideoLoadingProgressView {
//    private lazy var descriptionLabel: UILabel = {
//        let label = UILabel()
//        label.font = .appFont(.textBodyMainSmall)
//        label.textColor = .appColor(.textBody)
//        label.textAlignment = .center
//        return label
//    }()
//    
//    public var descriptionText: String? {
//        didSet {
//            descriptionLabel.text = descriptionText
//        }
//    }
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupUI()
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    func setupUI() {
//        contentView.addSubview(descriptionLabel)
//    }
//    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        contentView.size = CGSize(width: smartFit(value: 195), height: smartFit(value: 151))
//        contentView.center = CGPoint(x: width / 2, y: height / 2)
//        animateView.size = CGSize(width: smartFit(value: 125), height: smartFit(value: 90))
//        animateView.centerX = contentView.width / 2
//        animateView.top = smartFit(value: 25)
//        loadingLabel.frame = CGRect(x: 0, y:animateView.bottom + smartFit(value: 10), w: contentView.width, h: smartFit(value: 21))
//        descriptionLabel.frame = CGRect.init(x: 0, y: loadingLabel.bottom + smartFit(value: 10), w: contentView.width, h: smartFit(value: 17))
//        closeBtn.origin = CGPoint(x: smartFit(value: 10), y: smartFit(value: 10))
//    }
//    
//}
