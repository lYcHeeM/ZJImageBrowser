//
//  ZJImageWrapper.swift
//  ZJImageBrowser
//
//  Created by luozhijun on 2017/7/8.
//  Copyright © 2017年 RickLuo. All rights reserved.
//

import UIKit

open class ZJImageWrapper: NSObject {
    open var image              : UIImage?
    open var highQualityImageUrl: String = ""
    open var shouldDownloadImage: Bool = true
    open var progressStyle      : ZJProgressViewStyle = .pie
    open var placeholderImage   : UIImage?
    /// using for enlarging\shrinking animation
    weak open var imageContainer: UIView?
    
    public override init() {
        super.init()
    }
    
    public required init(image: UIImage? = nil, highQualityImageUrl: String?, shouldDownloadImage: Bool, placeholderImage: UIImage?, imageContainer: UIView?) {
        self.image               = image
        self.highQualityImageUrl = highQualityImageUrl ?? ""
        self.shouldDownloadImage = shouldDownloadImage
        self.placeholderImage    = placeholderImage
        self.imageContainer      = imageContainer
    }
}

