//
//  ZJPhotoCell.swift
//  ProgressView
//
//  Created by luozhijun on 2017/7/5.
//  Copyright © 2017年 RickLuo. All rights reserved.
//

import UIKit
import SDWebImage

class ZJPhotoCell: UICollectionViewCell {
    
    static let reuseIdentifier = "ZJPhotoCell"
    let maximumZoomScale: CGFloat = 2.5
    
    fileprivate var scrollView  : UIScrollView = UIScrollView()
    fileprivate var imageView   : UIImageView  = UIImageView()
    fileprivate var progressView: ZJProgressView!
    fileprivate var retryButton : UIButton!
    fileprivate var urlString   : String!
    
    fileprivate var urlMap: Int = -1
    
    var imageContainer: UIImageView {
        return imageView
    }
    var singleTapped: ((UITapGestureRecognizer) -> Swift.Void)?
    
    var image: UIImage? {
        didSet {
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
extension ZJPhotoCell {
    override func layoutSubviews() {
        super.layoutSubviews()
        if let retryButton = retryButton {
            retryButton.frame.origin = CGPoint(x: ZJPhotoBrowserButtonHorizontalPadding, y: frame.size.height - ZJPhotoBrowserButtonVerticalPadding - ZJPhotoBrowserButtonHeight)
            retryButton.frame.size.height = ZJPhotoBrowserButtonHeight
        }
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
        // 为避免在layoutSubviews中设置scrollView和imageView的frame,
        // 并注意到为了在页与页之间插入间隔, itemSize尾部有一小段非实际内容的间距用于实现此效果, 
        // 此处直接固定scrollView的frame
        scrollView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        
        scrollView.addSubview(imageView)
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFill
    }
    
    fileprivate func setupRetryButton() {
        guard retryButton == nil else { return }
        retryButton = UIButton(type: .system)
        retryButton.isHidden = true
        retryButton.setTitle("  原图加载失败, 点击重试  ", for: .normal)
        retryButton.titleLabel?.font   = UIFont.systemFont(ofSize: 12)
        retryButton.tintColor          = UIColor.white
        retryButton.layer.cornerRadius = 3
        retryButton.layer.borderWidth  = 1.5/UIScreen.main.scale
        retryButton.layer.borderColor  = UIColor.white.cgColor
        retryButton.backgroundColor    = UIColor(white: 0, alpha: 0.5)
        retryButton.sizeToFit()
        retryButton.addTarget(self, action: #selector(retryButtonClicked), for: .touchUpInside)
        contentView.addSubview(retryButton)
        retryButton.frame.origin = CGPoint(x: ZJPhotoBrowserButtonHorizontalPadding, y: frame.size.height - ZJPhotoBrowserButtonVerticalPadding - ZJPhotoBrowserButtonHeight)
    }
    
    fileprivate func adjustSubviewFrames() {
        if let image = image {
            // 使图片宽度和屏慕宽度保持一致, 宽高比和图片的宽高比一致
            imageView.frame.size.width  = scrollView.frame.width
            imageView.frame.size.height = imageView.frame.width * (image.size.height/image.size.width)
            scrollView.contentSize      = imageView.frame.size
            imageView.center            = scrollViewContentCenter //CGPoint(x: frame.width/2, y: frame.height/2)
            imageView.image             = image
            
            // 根据图片大小找到合适的放大系数，放大图片时不留黑边
            // 先设置为高度放大系数
            var maxZoomScale: CGFloat = scrollView.frame.height / imageView.frame.height
            let widthZoomScale = scrollView.frame.width/imageView.frame.width
            // 如果小于宽度放大系数, 则设为宽度放大系数
            if maxZoomScale < widthZoomScale {
                maxZoomScale = widthZoomScale
            }
            // 如果小于设定的放大系数, 即设定的放大系数已足够令屏幕不留黑边时, 直接用设定的放大系数即可.
            if maxZoomScale < maximumZoomScale {
                maxZoomScale = maximumZoomScale
            }
            scrollView.minimumZoomScale = 1
            scrollView.maximumZoomScale = maxZoomScale
            scrollView.zoomScale        = 1
        } else {
            imageView.frame = scrollView.bounds
        }
        scrollView.contentOffset = .zero
    }
    
    /// 默认情况下, scrollView放大其子视图后会改变contentSize, 当contentSize小于scrollView.bounds.size时, 有可能使子视图不居中(比如令图片往下掉)
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

extension ZJPhotoCell {
    func setImage(withUrl url: String, placeholderImage: UIImage?) {
        guard let usingUrl = URL(string: url) else { return }
        
        retryButton?.isHidden = true
        urlString = url
        
        contentView.viewWithTag(-111)?.removeFromSuperview()
        let progressViewSize: CGFloat = 50
        let progressViewFrame = CGRect(x: (frame.width - progressViewSize)/2, y: (frame.height - progressViewSize)/2, width: progressViewSize, height: progressViewSize)
        progressView = ZJProgressView(frame: progressViewFrame, style: .pie)
        progressView.tag = -111
        contentView.addSubview(progressView)
        
        urlMap = urlString.hashValue
        image  = placeholderImage
        // 注意到imageView.sd_setImage方法会在开头cancel掉当前imageView关联的上一次下载,
        // 当cell被重用时, 意味着imageView被重用, 则切换图片时很可能会取消正在下载图片,
        // 导致重新滑到之前的页面会重新开启下载线程, 浪费资源, 故此处不用该方法.        
        SDWebImageManager.shared().downloadImage(with: usingUrl, options: [.cacheMemoryOnly, .retryFailed], progress: { [weak self] (receivedSize, expectedSize) in
            guard self != nil, self!.urlMap == url.hashValue else { return }
            let progress = CGFloat(receivedSize)/CGFloat(expectedSize)
            self?.progressView?.progress = progress
        }) { [weak self] (image, error, cacheType, finished, imageUrl) in
            guard self != nil, self!.urlMap == url.hashValue, finished else { return }
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
        }
    }
}

//MARK: - UIScrollViewDelegate
extension ZJPhotoCell: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // 默认情况下, scrollView放大其子视图后会改变contentSize, 当contentSize小于scrollView.bounds.size时, 有可能使子视图不居中(比如令图片往下掉)
        imageView.center = scrollViewContentCenter
    }
}

//MARK: - handle events
extension ZJPhotoCell {
    @objc fileprivate func handleSingleTap(recognizer: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
        singleTapped?(recognizer)
    }
    
    @objc fileprivate func handleDoubleTap(recognizer: UITapGestureRecognizer) {
        // 图片加载过程中不允许放大
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
        setImage(withUrl: urlString, placeholderImage: imageView.image)
    }
}
