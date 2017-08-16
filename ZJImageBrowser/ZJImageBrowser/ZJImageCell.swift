//
//  ZJImageCell.swift
//  ProgressView
//
//  Created by luozhijun on 2017/7/5.
//  Copyright © 2017年 RickLuo. All rights reserved.
//

import UIKit
import Photos
import SDWebImage

class ZJImageCell: UICollectionViewCell {
    
    static let reuseIdentifier = "ZJImageCell"
    
    fileprivate var scrollView  : UIScrollView = UIScrollView()
    fileprivate var imageView   : UIImageView  = UIImageView()
    fileprivate var progressView: ZJProgressView!
    fileprivate var retryButton : UIButton!
    fileprivate var imageWrapper: ZJImageWrapper?
    #if DEBUG
    fileprivate var hud: ZJImageBrowserHUD?
    #endif
    
    /// urlMap, 用于和图片url字符串的hashValue做对比, 目的是防止下载图片过程中滑动到其他页面(cell)时, 下载进度回调被交叉执行。
    /// 因为，一旦imageView被重用, 则滑动之前的下载进度回调和滑动之后的下载进度回调会在同一个cell中交叉触发(如果都在同一个线程中的话)。
    /// 图片下载完成时, 设置图片等操作之前对urlMap的检验同理。
    /// Apple文档说"hashValue"不能保证在不同的App启动环境中得到相同的结果, 并不影响此处的检验.
    /// Use to compare to the hash value of url string, in order to avoid 'progress' call back excuting crossly when scrolling pages.
    /// Because of reusing mechanism, onece 'imageView' is reused, the 'progress' call back of previous image downing and the 'progress' call back of the current image downing will execute in the same cell crossly (or concurrently).
    /// The same checking will be done in the 'completeion' call back.
    fileprivate var urlMap: Int = -1
    
    var imageContainer: UIImageView {
        return imageView
    }
    /// 注意: 此闭包将不在主线程执行
    /// Note: this closure excutes in global queue.
    var imageQueryingFinished: ((Bool, UIImage?)         -> Swift.Void)?
    var singleTapped         : ((UITapGestureRecognizer) -> Swift.Void)?
    
    var image: UIImage? {
        didSet {
            guard oldValue != image else { return }
            adjustSubviewFrames()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: - Setup UI
extension ZJImageCell {
    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = CGRect(x: 0, y: 0, width: frame.width - ZJImageBrowser.pageSpacing, height: frame.height)
        if let retryButton = retryButton {
            retryButton.frame.origin = CGPoint(x: ZJImageBrowser.buttonHorizontalPadding, y: frame.size.height - ZJImageBrowser.buttonVerticalPadding - ZJImageBrowser.buttonHeight)
            retryButton.frame.size.height = ZJImageBrowser.buttonHeight
        }
        adjustSubviewFrames()
    }
    
    override func prepareForReuse() {
        #if DEBUG
            hud?.hide(animated: false)
            hud = nil
        #endif
        progressView?.removeFromSuperview()
        progressView = nil
        super.prepareForReuse()
    }
    
    fileprivate func setupSubviews() {
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        singleTap.delaysTouchesBegan = true
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        singleTap.require(toFail: doubleTap)
        
        contentView.addSubview(scrollView)
        scrollView.showsVerticalScrollIndicator   = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate                       = self
        scrollView.addGestureRecognizer(singleTap)
        scrollView.addGestureRecognizer(doubleTap)
        
        scrollView.addSubview(imageView)
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFill
    }
    
    fileprivate func setupRetryButton() {
        guard retryButton == nil else { return }
        retryButton = UIButton(type: .system)
        retryButton.isHidden = true
        retryButton.setTitle(" \(ZJImageBrowser.retryButtonTitle) ", for: .normal)
        retryButton.titleLabel?.font   = UIFont.systemFont(ofSize: 12)
        retryButton.tintColor          = UIColor.white
        retryButton.layer.cornerRadius = 3
        retryButton.layer.borderWidth  = 1.5/UIScreen.main.scale
        retryButton.layer.borderColor  = UIColor.white.cgColor
        retryButton.backgroundColor    = UIColor(white: 0, alpha: 0.5)
        retryButton.sizeToFit()
        retryButton.addTarget(self, action: #selector(retryButtonClicked), for: .touchUpInside)
        contentView.addSubview(retryButton)
        retryButton.frame.origin = CGPoint(x: ZJImageBrowser.buttonHorizontalPadding, y: frame.size.height - ZJImageBrowser.buttonVerticalPadding - ZJImageBrowser.buttonHeight)
    }
    
    fileprivate func adjustSubviewFrames() {
        if let image = image {
            // 使imageView宽度和屏慕宽度保持一致, 宽高比和图片的宽高比一致
            // Make enlargingViewEndFrame's width equals to screen width, and its aspect ratio the same as its inner image;
            imageView.frame.size.width  = scrollView.frame.width
            imageView.frame.size.height = imageView.frame.width * (image.size.height/image.size.width)
            scrollView.contentSize      = imageView.frame.size
            imageView.center            = scrollViewContentCenter //CGPoint(x: frame.width/2, y: frame.height/2)
            imageView.image             = image
            
            // 根据图片大小找到合适的放大系数，放大图片时不留黑边
            // Find a appropriate zoom scale according to the imageView size in order to
                // 先设置为高度放大系数
                // By default, set 'maxZoomScale' as height zoom scale.
            var maxZoomScale: CGFloat = scrollView.frame.height / imageView.frame.height
            let widthZoomScale = scrollView.frame.width/imageView.frame.width
                // 如果小于宽度放大系数, 则设为宽度放大系数
                // If height zoom scale were less than width zoom scale, then use width zoom scale.
            if maxZoomScale < widthZoomScale {
                maxZoomScale = widthZoomScale
            }
                // 如果小于设定的放大系数, 即设定的放大系数已足够令屏幕不留黑边时, 直接用设定的放大系数即可.
                // Finally, if the computed max zoom scale were less than the preset value "maximumZoomScale", then discard it.
            if maxZoomScale < ZJImageBrowser.maximumZoomScale {
                maxZoomScale = ZJImageBrowser.maximumZoomScale
            }
            scrollView.minimumZoomScale = 1
            scrollView.maximumZoomScale = maxZoomScale
            scrollView.zoomScale        = 1
        } else {
            imageView.frame.size.width = scrollView.frame.width
            imageView.frame.size.height = imageView.frame.width
            imageView.center = CGPoint(x: scrollView.frame.width/2, y: scrollView.frame.height/2)
        }
        scrollView.contentOffset = .zero
    }
    
    /// 默认情况下, scrollView放大其子视图后会改变contentSize, 当contentSize小于scrollView.bounds.size时, 有可能使子视图不居中(比如令图片往下掉)
    /// By default, UIScrollView usually change its 'contentSize' after zooming subviews, and when 'contentSize < scrollView.bounds.size', zoomed subviews may shift (such as a familiar phenomenon: centered image would drop down if you do nothing). So we should get the real cotnetCenter of scrollView.
    fileprivate var scrollViewContentCenter: CGPoint {
        var offsetX: CGFloat = 0
        var offsetY: CGFloat = 0
        if scrollView.frame.width > scrollView.contentSize.width {
            offsetX = (scrollView.frame.width - scrollView.contentSize.width) * 0.5
        }
        if scrollView.frame.height > scrollView.contentSize.height {
            offsetY = (scrollView.frame.height - scrollView.contentSize.height) * 0.5
        }
        return CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
    }
}

extension ZJImageCell {
    
    func setImage(with imageWrapper: ZJImageWrapper) {
        self.imageWrapper = imageWrapper
        if let image = imageWrapper.image {
            self.image = image
            return
        } else if let asset = imageWrapper.asset {
            let indicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
            contentView.addSubview(indicator)
            indicator.center = CGPoint(x: (contentView.bounds.width - ZJImageBrowser.pageSpacing)/2, y: contentView.bounds.height/2)
            indicator.startAnimating()
            asset.originalImage(shouldSynchronous: false, completion: { (image, info) in
                indicator.removeFromSuperview()
                self.image = image
            })
            return
        }
        
        guard let usingUrl = URL(string: imageWrapper.highQualityImageUrl) else { return }
        
        var placeholderImage = imageWrapper.placeholderImage
        if placeholderImage == nil {
            placeholderImage = bundleImage(named: "whiteplaceholder")
        }
        retryButton?.isHidden = true
        progressView?.removeFromSuperview()
        urlMap = imageWrapper.highQualityImageUrl.hashValue
        image  = placeholderImage
        
        guard imageWrapper.shouldDownloadImage else {
            SDImageCache.shared().queryDiskCache(forKey: imageWrapper.highQualityImageUrl, done: { (image, cacheType) in
                guard let cachedImage = image else {
                    #if DEBUG
                        if ZJImageBrowser.showsDebugHud {
                            self.hud = ZJImageBrowserHUD.show(message: "Won't download the large image, cause 'shouldDownloadImage' is false.", inView: self.scrollView, animated: true, needsIndicator: false, hideAfter: 3)
                        }
                    #endif
                    return
                }
                guard self.urlMap == imageWrapper.highQualityImageUrl.hashValue else { return}
                DispatchQueue.main.async(execute: {
                    self.image = cachedImage
                })
            })
            return
        }
        
        progressView?.removeFromSuperview()
        
        let progressViewSize: CGFloat = 50
        let progressViewFrame = CGRect(x: (frame.width - progressViewSize)/2, y: (frame.height - progressViewSize)/2, width: progressViewSize, height: progressViewSize)
        progressView = ZJProgressView(frame: progressViewFrame, style: imageWrapper.progressStyle)
        contentView.addSubview(progressView)
        
        // 注意到imageView.sd_setImage方法会在开头cancel掉当前imageView关联的上一次下载,
        // 当cell被重用时, 意味着imageView被重用, 则切换图片时很可能会取消正在下载图片,
        // 导致重新滑到之前的页面会重新开启下载线程, 浪费资源, 故此处不用该方法.
        // Realizing 'imageView.sd_setImage...' function cancels previous image downloading which bounds to 'imageView', 
        // thus when cell is resued, it means imageView is reused, switching page would quite likely cancel the downloading progress. What's more, when we scroll to the that page again, a new downloading of the same image would be start. It's quite a waste of resources, so I use 'downloadImage' instead of 'sd_setImage...'.
        SDWebImageManager.shared().downloadImage(with: usingUrl, options: [.retryFailed], progress: { [weak self] (receivedSize, expectedSize) in
            // 校验urlMap是防止下载图片过程中滑动到其他页面(cell)时, 下载进度回调被交叉执行。
            // 因为，一旦imageView被重用, 则滑动之前的下载进度回调和滑动之后的下载进度回调会在同一个cell中交叉触发(如果都在同一个线程中的话)。
            // 图片下载完成时, 设置图片等操作之前对urlMap的检验同理。
            // Check 'urlMap' to avoid 'progress' call back excuting crossly when scrolling pages.
            // Because of reusing mechanism, onece 'imageView' is reused, the 'progress' call back of previous image downing and the 'progress' call back of the current image downing will execute in the same cell crossly (or concurrently).
            // The same checking will be done in the 'completeion' call back.
            guard self != nil, self!.urlMap == imageWrapper.highQualityImageUrl.hashValue else { return }
            let progress = CGFloat(receivedSize)/CGFloat(expectedSize)
            self?.progressView?.progress = progress
        }) { [weak self] (image, error, cacheType, finished, imageUrl) in
            guard self != nil, self!.urlMap == imageWrapper.highQualityImageUrl.hashValue, finished else { return }
            DispatchQueue.main.async(execute: {
                if let usingImage = image {
                    self?.image = usingImage
                }
                self?.progressView?.removeFromSuperview()
                if error != nil {
                    self?.setupRetryButton()
                    self?.retryButton.isHidden = false
                }
            })
            self?.imageQueryingFinished?(error == nil, image)
        }
    }
}

//MARK: - UIScrollViewDelegate
extension ZJImageCell: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // 默认情况下, scrollView放大其子视图后会改变contentSize, 当contentSize小于scrollView.bounds.size时, 有可能使子视图不居中(比如令图片往下掉)
        // By default, UIScrollView usually change its 'contentSize' after zooming subviews, and when 'contentSize < scrollView.bounds.size', zoomed subviews may shift (such as a familiar phenomenon: centered image would drop down if you do nothing).
        imageView.center = scrollViewContentCenter
    }
}

//MARK: - handle events
extension ZJImageCell {
    @objc fileprivate func handleSingleTap(recognizer: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
        singleTapped?(recognizer)
    }
    
    @objc fileprivate func handleDoubleTap(recognizer: UITapGestureRecognizer) {
        // 图片加载过程中不允许放大
        // Invalidate zooming when image is loading.
        if progressView?.superview != nil {
            return
        }
        
        let touchPoint = recognizer.location(in: contentView)
        if scrollView.zoomScale <= scrollView.minimumZoomScale {
            let pointX = touchPoint.x + scrollView.contentOffset.x
            let pointY = touchPoint.y + scrollView.contentOffset.y
            scrollView.zoom(to: CGRect(x: pointX, y: pointY, width: 10, height: 10), animated: true)
        } else {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
    }
    
    @objc fileprivate func retryButtonClicked() {
        retryButton.isHidden = true
        if let imageWrapper = imageWrapper {
            setImage(with: imageWrapper)
        }
    }
}
