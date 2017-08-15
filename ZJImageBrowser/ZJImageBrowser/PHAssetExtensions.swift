//
//  PHAssetExtensions.swift
//  ZJImageBrowser
//
//  Created by luozhijun on 2017/8/15.
//  Copyright © 2017年 RickLuo. All rights reserved.
//

import UIKit
import Photos

//MARK: - Convenience
extension PHAsset {
    func originalImage(shouldSynchronous: Bool, completion: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) {
        image(shouldSynchronous: shouldSynchronous, size: PHImageManagerMaximumSize, resizeMode: .exact, completion: completion)
    }
    
    func image(shouldSynchronous: Bool, size: CGSize, resizeMode: PHImageRequestOptionsResizeMode = .fast, contentMode: PHImageContentMode = .aspectFill, completion: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) {
        let options = PHImageRequestOptions()
        options.resizeMode = resizeMode
        options.isSynchronous = shouldSynchronous
        
        PHCachingImageManager.default().requestImage(for: self, targetSize: size, contentMode: contentMode, options: options, resultHandler: completion)
    }
}
