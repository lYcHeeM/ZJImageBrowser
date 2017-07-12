//
//  ZJPhotoBrowserPreviewingController.swift
//  ZJPhotoBrowser
//
//  Created by luozhijun on 2017/7/11.
//  Copyright © 2017年 RickLuo. All rights reserved.
//

import UIKit
import SDWebImage
import Photos

class ZJPhotoBrowserPreviewingController: UIViewController {

    var imageView = UIImageView()
    var photoWrapper: ZJPhotoWrapper!
    
    required init(photoWrapper: ZJPhotoWrapper) {
        super.init(nibName: nil, bundle: nil)
        self.photoWrapper = photoWrapper
    }
    
    func supposedContentSize(with image: UIImage?) -> CGSize {
        guard let image = image else { return UIScreen.main.bounds.size }
        var result = CGSize.zero
        result.width  = view.frame.width
        result.height = result.width * (image.size.height/image.size.width)
        return result
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate var image: UIImage? {
        didSet {
            imageView.image = image
            var imageViewOrigin = CGPoint.zero
            var imageViewSize = view.frame.size
            if let image = imageView.image {
                imageViewSize.width = view.frame.width
                imageViewSize.height = view.frame.width * (image.size.height/image.size.width)
            }
            if imageViewSize.height <= view.frame.height {
                imageViewOrigin = CGPoint(x: 0, y: (view.frame.height - imageViewSize.height)/2)
            }
            imageView.frame.origin = imageViewOrigin
            imageView.frame.size   = imageViewSize
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(imageView)
        image = photoWrapper.placeholderImage
        
        guard let url = URL(string: photoWrapper.highQualityImageUrl) else { return }
        
        let progressViewSize: CGFloat = 55
        let progressViewFrame = CGRect(x: (imageView.frame.width - progressViewSize)/2, y: (imageView.frame.height - progressViewSize)/2, width: progressViewSize, height: progressViewSize)
        let progressView = ZJProgressView(frame: progressViewFrame, style: photoWrapper.progressStyle)
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
    override var previewActionItems: [UIPreviewActionItem] {
        let action1 = UIPreviewAction(title: "Copy to pastboard", style: .default) { (action, controller) in
            UIPasteboard.general.image = self.image
        }
        let action2 = UIPreviewAction(title: "Save to album", style: .default) { (action, controller) in
            let status = PHPhotoLibrary.authorizationStatus()
            if status == .restricted || status == .denied {
                ZJPhotoBrowserHUD.show(message: ZJPhotoBrowser.albumAuthorizingFailedHint, inView: self.view, needsIndicator: false, hideAfter: 2.5)
                return
            }
            guard let image = self.image else { return }
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
        return [action1, action2]
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: Any?) {
        var alertMessage = ""
        if error == nil {
            alertMessage = ZJPhotoBrowser.imageSavingSucceedHint
        } else {
            alertMessage = ZJPhotoBrowser.imageSavingFailedHint
        }
        ZJPhotoBrowserHUD.show(message: alertMessage, inView: nil, needsIndicator: false)
    }
}
