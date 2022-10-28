//
//  PopupPhotoAlbumSectionView.swift
//  VSMediaRender_Example
//
//  Created by cofey on 2019/9/9.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import Photos
import FFUITool


//相册顶部弹出的相册选择页面
open class FFPopupAlbumView: UIView {
    // 点击回调
    public var didSelectPhotoAlbum: ((FFAlbumItem)->())?
    // 数据源
    public var dataArray: [FFAlbumItem]? = nil {
        didSet { tableView.reloadData() }
    }
    
    public var currentAlbum: FFAlbumItem?
    
    public var fromBottom = false
    
    public lazy var tableView: UITableView = {
        let view = UITableView(frame: CGRect.zero, style: .plain)
        view.separatorStyle = .none
        view.clipsToBounds = true
        view.delegate = self
        view.dataSource = self
        return view
    }()
    
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView() {
        self.backgroundColor = .white.dynamicGray6
        self.tableView.backgroundColor = self.backgroundColor
        
        addSubview(tableView)
        tableView.frame = self.bounds
        clipsToBounds = true
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        hide()
    }
    
    public func show() {
        if fromBottom {
            var row = tableView.dataSource?.tableView(tableView, numberOfRowsInSection: 0) ?? 0
            if let currentAlbum = self.currentAlbum {
                row = (dataArray?.firstIndex(of: currentAlbum) ?? -1) + 1
            }
            if row == 0 { return }
            let index = IndexPath(row: row > 0 ? row - 1 : 0, section: 0)
            tableView.scrollToRow(at: index, at: .bottom, animated: false)
//            UIView.animate(withDuration: 0.25) {
//                self.transform = CGAffineTransform.init(translationX: 0, y: -self.height)
//            }
        } else {
            tableView.frame = CGRect(x: 0, y: self.top, width: width, height: 0)
//            UIView.animate(withDuration: 0.25) {
//                self.tableView.frame = CGRect(x: 0, y: self.top, width: self.width, height: albumSectionCellHeight * min(3.5, CGFloat(self.dataArray?.count ?? 0)))
//            }
        }
    }
    
    public func hide() {
        UIView.animate(withDuration: 0.25, animations: {
            if self.fromBottom {
                self.transform = CGAffineTransform.identity
            } else {
                self.transform = CGAffineTransform.identity
            }
        }) { (flag) in
            self.removeFromSuperview()
        }
    }
}

extension FFPopupAlbumView: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return albumSectionCellHeight
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataArray?.count ?? 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: FFPopupAlbumCell? = tableView.dequeueReusableCell(withIdentifier: "FFAlbumSectionId") as? FFPopupAlbumCell
        if cell == nil {
            cell = FFPopupAlbumCell(style: .subtitle, reuseIdentifier: "FFAlbumSectionId")
            cell?.backgroundColor = UIColor.white.dynamicGray6
        }
        
        let model : FFAlbumItem = self.dataArray![indexPath.row]
        cell!.detailTextLabel?.text = "\(model.photoAlbuSubItemsCount())"
        cell!.textLabel?.textColor = UIColor.black.dynamicWhite
        cell!.textLabel?.font = UIFont.systemFont(ofSize: 15)
        cell!.textLabel?.text = model.title()

        let opt: PHImageRequestOptions = PHImageRequestOptions()
        opt.deliveryMode = .highQualityFormat
        opt.resizeMode = .exact
        opt.version = .current
        opt.isNetworkAccessAllowed = true
        
        cell!.imageView?.contentMode = .scaleAspectFill
        cell!.imageView?.clipsToBounds = true
        cell!.imageView?.layer.cornerRadius = 5.px
        cell!.detailTextLabel?.textColor = UIColor.gray.dynamicWhite
        cell!.detailTextLabel?.font = UIFont.systemFont(ofSize: 12)
        

        guard let item = model.thumbnailItem else {
            cell?.imageView?.image = nil
            return cell!
        }
        
        let size = CGSize(width: albumSectionCellHeight * UIScreen.main.scale, height: albumSectionCellHeight * UIScreen.main.scale)
        PHCachingImageManager.default().requestImage(for: item,
                                   targetSize: size,
                                   contentMode: .aspectFill,
                                   options: opt,
                                   resultHandler: { (image, info) in
                                    if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, isDegraded {
                                        return
                                    }
                                    
                                    if let isCancel = info?[PHImageCancelledKey] as? Bool, isCancel {
                                        return
                                    }
                                    
                                    if let _ = info?[PHImageErrorKey] {
                                        return
                                    }
                                    
                                    cell!.imageView?.image = image
                                    cell!.setNeedsLayout()
                                    cell!.layoutIfNeeded()
        })
        return cell!
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let model:FFAlbumItem = self.dataArray?[indexPath.row] else {
            return
        }
//        hide()
        didSelectPhotoAlbum?(model)
    }
}
