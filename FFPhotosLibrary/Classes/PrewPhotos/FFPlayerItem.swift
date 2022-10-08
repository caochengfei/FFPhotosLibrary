//
//  FFPlayerItem.swift
//  Picroll
//
//  Created by cofey on 2022/8/18.
//

import Foundation
import AVFoundation
import Photos

// 播放完毕回调
typealias VideoPlayerDidEndPlay = ()->()

class VideoPlayerItem: NSObject {
    // id
    var requestID:PHImageRequestID?
    // 观察者
    private var observer:Any?
    // 播放完毕
    var videoPlayerDidEndPlay:VideoPlayerDidEndPlay?
    
    lazy private var player:AVPlayer = {
        let player = AVPlayer(playerItem: nil)
        return player
    }()
    
    private(set) lazy var playLayer:AVPlayerLayer = {
        let playLayer = AVPlayerLayer()
        playLayer.videoGravity = .resizeAspect
        return playLayer
    }()
    
    var currentTime: Double {
        return player.currentTime().seconds
    }
    
    var duration: Double {
        return player.currentItem?.duration.seconds ?? 0
    }
    
    @objc func playerFinished(){
        self.videoPlayerDidEndPlay?()
    }
    
    override init() {
        super.init()
//        NotifyCenter.addObserver(self, selector: #selector(playerFinished), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    deinit {
        self.resetConfig()
    }
    
    /// seek
    /// - Parameter toTime: toTime
    func seek(toTime:CMTime){
        self.player.pause()
        self.player.seek(to: toTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero, completionHandler: { (ret) in
            
        })
    }
    
    
    /// 观察播放进度
    /// - Parameter handler: 回调
    func observerProgress(handler:@escaping (Float)->()){
        let time = CMTimeMakeWithSeconds(0.01, preferredTimescale: Int32(USEC_PER_SEC))
        self.observer = self.player.addPeriodicTimeObserver(forInterval: time, queue: DispatchQueue.main) { (time) in
            let progress = CMTimeGetSeconds(time)
            handler(Float(progress))
        }
    }
    
    
    /// 添加播放layer
    /// - Parameters:
    ///   - frame: CGRect
    ///   - superLayer: superLayer
    func addToSuperLayer(_ frame:CGRect, _ superLayer:CALayer){
        if playLayer.superlayer == nil {
            superLayer.addSublayer((playLayer))
        }
        playLayer.frame = frame
    }
    
    
    /// 替换playerItem
    /// - Parameter item: AVPlayerItem
    func replaceCurrentItem(_ item:AVPlayerItem?){
        self.player.replaceCurrentItem(with: item)
        self.playLayer.player = self.player
    }
    
    /// 播放
    func play(){
        self.player.play()
    }
    
    /// 重播
    func rePlay() {
        player.seek(to: CMTime(value: 0, timescale: 100))
        player.play()
    }
    
    /// 暂停
    func pause(){
        self.player.pause()
    }
    
    
    /// 重设config
    func resetConfig(){
        if  let requestId = requestID {
            PHImageManager.default().cancelImageRequest(requestId)
        }
        self.player.pause()
        self.player.currentItem?.cancelPendingSeeks()
        self.player.currentItem?.asset.cancelLoading()
        if observer != nil {
           self.player.removeTimeObserver(observer!)
            observer = nil
        }
        self.player.replaceCurrentItem(with: nil)
        self.playLayer.player = nil
        self.playLayer.removeFromSuperlayer()
    }
    
    
    /// 隐藏
    public func hidePlayLayer() {
        playLayer.opacity = 0
    }
    
    /// 显示
    public func showPlayLayer() {
        playLayer.opacity = 1
    }
}
