//
//  FFPopupAlbumCell.swift
//  Picroll
//
//  Created by cofey on 2022/8/18.
//

import UIKit
import SnapKit
import FFUITool

public let albumSectionCellHeight:CGFloat = 80.rem
public let albumImageItemHeight: CGFloat = 76.rem
public let albumTextHeight:CGFloat = 20.rem
public let popupImagePad: CGFloat = 4.rem

open class FFPopupAlbumCell: UITableViewCell {
    
    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 5.rem
        return imageView
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.medium)
        label.textColor = "#222222".toRGB.dynamicWhite
        return label
    }()
    
    lazy var detailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.medium)
        label.textColor = "#B3B3B3".toRGB.dynamicGray2
        return label
    }()
    
    lazy var checkmarkImage: UIImageView = {
        let imageView = UIImageView()
        if #available(iOS 13.0, *) {
//            imageView.image = UIImage.systedName(name: "checkmark", fontSize: 15, weight: UIImage.SymbolWeight.semibold)
            imageView.image = UIImage.systedName(name: "checkmark", font: UIFont.systemFont(ofSize: 15, weight: .semibold))
            imageView.contentMode = .scaleAspectFit
            imageView.transform = CGAffineTransform.init(scaleX: 0.6, y: 0.6)
            imageView.tintColor = "#19B2FF".toRGB
            imageView.contentScaleFactor = 1.0
        } else {
            // Fallback on earlier versions
        }
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(detailLabel)
        contentView.addSubview(checkmarkImage)
                
        iconImageView.snp.makeConstraints({ make in
            make.left.equalToSuperview().offset(4.rem)
            make.width.height.equalTo(CGSize(width: albumImageItemHeight, height: albumImageItemHeight))
        })
        
        titleLabel.snp.makeConstraints({ make in
            make.left.equalTo(iconImageView.snp.right).offset(14.rem)
            make.top.equalToSuperview().offset(14.rem)
        })
        
        detailLabel.snp.makeConstraints({ make in
            make.left.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-14.rem)
        })
        
        checkmarkImage.snp.makeConstraints { make in
            make.width.height.equalTo(30.rem)
            make.right.equalToSuperview().offset(-30.rem)
            make.centerY.equalToSuperview()
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
