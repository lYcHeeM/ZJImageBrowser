//
//  ZJImageBrowserPreviewingController.swift
//  ZJImageBrowser
//
//  Created by luozhijun on 2017/7/11.
//  Copyright © 2017年 RickLuo. All rights reserved.
//

import UIKit
import SDWebImage
import Photos

open class ZJImageBrowserPreviewingController: UIViewController {

    private var imageView = UIImageView()
    private var cachedImage: UIImage?
    open var imageWrapper: ZJImageWrapper!
    open var needsCopyAction: Bool = true
    open var needsSaveAction: Bool = true
    
    required public init(imageWrapper: ZJImageWrapper) {
        super.init(nibName: nil, bundle: nil)
        self.imageWrapper = imageWrapper
    }
    
    open func supposedContentSize(with image: UIImage? = nil) -> CGSize {
        var usingImage = image
        if usingImage == nil {
            if let asset = imageWrapper.asset {
                asset.image(shouldSynchronous: true, size: CGSize(width: 100, height: 100), completion: { (image, info) in
                    self.cachedImage = image
                    usingImage = image
                })
            } else {
                usingImage = SDImageCache.shared().imageFromDiskCache(forKey: imageWrapper.highQualityImageUrl)
            }
        }
        guard let image = usingImage else { return UIScreen.main.bounds.size }
        var result    = CGSize.zero
        result.width  = UIScreen.main.bounds.size.width
        // 本以为要限制高度最大为屏幕高度, 同时按比例缩小width, 但实践发现这么做,
        // 在高度超过屏幕的长图上, 会使得peek操作触发后, 图片无法充满预览区域.
        // 但现在的做法也有一个缺陷, 长图无法完整显示, 超出屏幕高度的部分有可能看不到.
        result.height = result.width * (image.size.height/image.size.width)
        return result
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate var image: UIImage? {
        didSet {
            imageView.image        = image
            imageView.frame.size   = supposedContentSize(with: image)
            // 实践发现必须设置为zero才不会出现奇怪的问题.
            // 本以为当imageView的高度小于view.frame.height时, 须调整y值使imageView居中,
            // 但会有很大概率导致peek操作触发后, 图片显示不完全的现象.
            imageView.frame.origin = .zero
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        view.clipsToBounds = false
        view.addSubview(imageView)
        if let image = imageWrapper.image {
            self.image = image
            return
        } else if let image = cachedImage {
            self.image = image
            return
        } else if let asset = imageWrapper.asset {
            asset.image(shouldSynchronous: false, size: UIScreen.main.bounds.size, completion: { (image, info) in
                self.image = image
            })
            return
        }
        
        image = imageWrapper.placeholderImage
        
        guard let url = URL(string: imageWrapper.highQualityImageUrl) else { return }
        
        let progressViewSize: CGFloat = 55
        let progressViewFrame = CGRect(x: (imageView.frame.width - progressViewSize)/2, y: (imageView.frame.height - progressViewSize)/2, width: progressViewSize, height: progressViewSize)
        let progressView = ZJProgressView(frame: progressViewFrame, style: imageWrapper.progressStyle)
        imageView.addSubview(progressView)
        
        weak var weakProgressView = progressView
        SDWebImageManager.shared().downloadImage(with: url, options: [.retryFailed], progress: { (receivedSize, expectedSize) in
            let progress = CGFloat(receivedSize)/CGFloat(expectedSize)
            weakProgressView?.progress = progress
        }) { [weak self] (image, error, cacheType, finished, imageUrl) in
            guard self != nil, finished else { return }
            DispatchQueue.main.async(execute: {
                if let usingImage = image {
                    self?.image = usingImage
                }
                weakProgressView?.removeFromSuperview()
            })
        }
    }
    
    @available(iOS 9.0, *)
    override open var previewActionItems: [UIPreviewActionItem] {
        let copyAction = UIPreviewAction(title: ZJImageBrowser.copyToPastboardActionTitle, style: .default) { (action, controller) in
            UIPasteboard.general.image = self.image
        }
        let saveAction = UIPreviewAction(title: ZJImageBrowser.saveActionTitle, style: .default) { (action, controller) in
            let status = PHPhotoLibrary.authorizationStatus()
            if status == .restricted || status == .denied {
                ZJImageBrowserHUD.show(message: ZJImageBrowser.albumAuthorizingFailedHint, inView: self.view, needsIndicator: false, hideAfter: 2.5)
                return
            }
            guard let image = self.image else { return }
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
        var actions = [UIPreviewAction]()
        if needsCopyAction {
            actions.append(copyAction)
        }
        if needsSaveAction {
            actions.append(saveAction)
        }
        return actions
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: Any?) {
        var alertMessage = ""
        if error == nil {
            alertMessage = ZJImageBrowser.imageSavingSucceedHint
        } else {
            alertMessage = ZJImageBrowser.imageSavingFailedHint
        }
        ZJImageBrowserHUD.show(message: alertMessage, inView: nil, needsIndicator: false)
    }
}
