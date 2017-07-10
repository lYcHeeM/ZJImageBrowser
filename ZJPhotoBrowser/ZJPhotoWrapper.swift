//
//  ZJPhotoWrapper.swift
//  ZJPhotoBrowser
//
//  Created by luozhijun on 2017/7/8.
//  Copyright © 2017年 RickLuo. All rights reserved.
//

import UIKit

class ZJPhotoWrapper: NSObject {
    var highQualityImageUrl: String = ""
    var shouldDownloadImage: Bool = true
    var progressStyle      : ZJProgressViewStyle = .pie
    var placeholderImage   : UIImage?
    /// using for enlarging\shrinking animation
    weak var imageContainer: UIView?
    
    override init() {
        super.init()
    }
    
    init(highQualityImageUrl: String?, shouldDownloadImage: Bool, placeholderImage: UIImage?, imageContainer: UIView?) {
        self.highQualityImageUrl = highQualityImageUrl ?? ""
        self.shouldDownloadImage = shouldDownloadImage
        self.placeholderImage    = placeholderImage
        self.imageContainer      = imageContainer
    }
}
