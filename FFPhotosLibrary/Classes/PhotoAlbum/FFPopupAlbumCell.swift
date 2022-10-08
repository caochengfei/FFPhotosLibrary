//
//  FFPopupAlbumCell.swift
//  Picroll
//
//  Created by cofey on 2022/8/18.
//

import UIKit
import SnapKit

public let albumSectionCellHeight:CGFloat = 80.px
public let albumTextHeight:CGFloat = 20.px
public let popupImagePad: CGFloat = 10.px

open class FFPopupAlbumCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    open override func layoutSubviews() {
        super.layoutSubviews()
        imageView?.frame = CGRect(x: popupImagePad, y: popupImagePad / 2.0, width: height - popupImagePad, height:height - popupImagePad)
        textLabel?.frame = CGRect(x: height + popupImagePad, y: popupImagePad , width: width / 2 - albumTextHeight, height: albumTextHeight)
        detailTextLabel?.frame = CGRect(x: height + popupImagePad, y: height / 2.0, width: width - popupImagePad - height, height: albumTextHeight)
    }
}
