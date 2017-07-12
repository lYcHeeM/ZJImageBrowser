//
//  ZJImageBrowser.swift
//
//  Created by luozhijun on 2017/7/5.
//  Copyright © 2017年 RickLuo. All rights reserved.
//

import UIKit
import Photos

/// An elegant full screen photo browser based on UICollectionView.
class ZJImageBrowser: UICollectionView {
    static let buttonHorizontalPadding: CGFloat = 20
    static let buttonVerticalPadding  : CGFloat = 35
    static let buttonHeight           : CGFloat = 27
    static let pageSpacing            : CGFloat = 10
    
    static let albumAuthorizingFailedHint = "Saving failed! Can't access your ablum, check in \"Settings\"->\"Privacy\"->\"Photos\"."
    static let imageSavingSucceedHint     = "Saving succeed"
    static let imageSavingFailedHint      = "Saving failed!"
    
    fileprivate var imageWrappers     = [ZJImageWrapper]()
    fileprivate var isShowing         = false
    fileprivate var saveButton        = UIButton(type: .system)
    fileprivate var pageIndexLabel    = UILabel()
    fileprivate var innerInitialIndex = 0
    fileprivate weak var hud: ZJImageBrowserHUD?
    
    var initialIndex: Int {
        return innerInitialIndex
    }
    var containerRect: CGRect = UIScreen.main.bounds {
        didSet {
            let pageSpacing: CGFloat = ZJImageBrowser.pageSpacing
            frame = CGRect(x: containerRect.minX, y: containerRect.minY, width: containerRect.width + pageSpacing, height: containerRect.height)
            if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
                layout.itemSize = CGSize(width: containerRect.width + pageSpacing, height: containerRect.height)
                collectionViewLayout = layout
            }
        }
    }
    override var isScrollEnabled: Bool {
        didSet {
            needsPageIndex = isScrollEnabled
            let tempValue  = isScrollEnabled
            super.isScrollEnabled = tempValue
        }
    }
    var needsPageIndex: Bool = true {
        didSet {
            pageIndexLabel.isHidden = !needsPageIndex
        }
    }
    var needsSaveButton: Bool = true {
        didSet {
            saveButton.isHidden = !needsSaveButton
        }
    }
    /// Default is true. trun off it if you want use loacl HUD.
    /// 默认打开, 如果想用项目本地的hud提示异常, 请置为false
    var usesInternalHUD = true
    var imageViewSingleTapped : ((ZJImageBrowser, Int, UIImage?)         -> Swift.Void)?
    var albumAuthorizingFailed: ((ZJImageBrowser, PHAuthorizationStatus) -> Swift.Void)?
    var photoSavingFailed     : ((ZJImageBrowser, UIImage)               -> Swift.Void)?
    /// 注意: 此闭包将不在主线程执行
    /// Note: this closure excutes in global queue.
    var imageQueryingFinished : ((ZJImageBrowser, Bool, UIImage?)        -> Swift.Void)?
    
    required init(imageWrappers: [ZJImageWrapper], initialIndex: Int = 0, containerRect: CGRect = UIScreen.main.bounds) {
        let layout = UICollectionViewFlowLayout()
        self.containerRect = containerRect
        // 每个item, 除了实际内容, 尾部再加一段空白间隙, 以实现和ScrollView一样的翻页效果.
        // 意识到设置minimumLineSpacing = 10, 并增加collectionView相同的宽度, 
        // 似乎也能达到这个效果, 但由于最后一页尾部不存在lineSpacing, collectionView的contentSize将无法完全展示最后一页, 即最后一页末尾10距离的内容将不能显示.
        // By default, UICollectionViewFlowLayout's minimumLineSpacing is 10.0, when collectionView's item is horizontally filled (itemSize.width = collectionView.bounds.width) and collectionView is paging enabled, greater than zero 'minimumLineSpacing' will cause an unintended performance: start from second page, every page has a gap which will be accumulated by page number.
        // It seems that we can expand collectionView's width by 'minimumLineSpacing' to fix this problem. But pratice negates this solution: When there are tow pages or more, collectionView will not give the last one a 'lineSpacing', so it's 'contentSize' is not enough to show this page's content completely, which means if the 'minimumLineSpacing' were 10.0, the last page's end would overstep the collectionView's contentSize by 10.0.
        // Finally, I use the following simple solution to insert a margin between every item (like UIScrollView's preformance): Expand every collectionViewItem's width by a fixed value 'pageSpacing' (such as 10.0), and expand the collectionView's width by the same value, too. And don't forget that, when layout collevtionViewCell's subviews, there's an additional spacing which is not for diplaying the real content.
        let pageSpacing: CGFloat       = ZJImageBrowser.pageSpacing
        layout.itemSize                = CGSize(width: containerRect.width + pageSpacing, height: containerRect.height)
        layout.scrollDirection         = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing      = 0
        
        super.init(frame: CGRect(x: containerRect.minX, y: containerRect.minY, width: containerRect.width + pageSpacing, height: containerRect.height), collectionViewLayout: layout)
        self.imageWrappers     = imageWrappers
        self.innerInitialIndex = initialIndex
        
        isPagingEnabled = true
        dataSource      = self
        delegate        = self
        showsHorizontalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        register(ZJImageCell.self, forCellWithReuseIdentifier: ZJImageCell.reuseIdentifier)
        
        setupSaveButton()
        setupPageIndexLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

//MARK: - Setup UI
extension ZJImageBrowser {
    override func layoutSubviews() {
        super.layoutSubviews()
        saveButton.frame.origin = CGPoint(x: frame.width - ZJImageBrowser.buttonHorizontalPadding - 10 - saveButton.bounds.width, y: frame.height - ZJImageBrowser.buttonHeight - ZJImageBrowser.buttonVerticalPadding)
        saveButton.frame.size.height = ZJImageBrowser.buttonHeight
    }
    
    fileprivate func setupSaveButton() {
        // 由于self继承ScrollView, 如果直接把button加到self上, 则会跟随滚动
        // 此处可耍小技巧, 把button加到一个空的backgroundView上, 
        // 则可避免修改整个browser的视图结构, 可直接以CollectionView为最底层
        saveButton.setTitle("  Save  ", for: .normal)
        saveButton.titleLabel?.font   = UIFont.systemFont(ofSize: 14)
        saveButton.tintColor          = UIColor.white
        saveButton.layer.cornerRadius = 3
        saveButton.layer.borderWidth  = 1.5/UIScreen.main.scale
        saveButton.layer.borderColor  = UIColor.white.cgColor
        saveButton.backgroundColor    = UIColor(white: 0.0, alpha: 0.5)
        saveButton.sizeToFit()
        saveButton.addTarget(self, action: #selector(saveButtonClicked), for: .touchUpInside)
    }
    
    fileprivate func setupPageIndexLabel() {
        pageIndexLabel.font          = UIFont.boldSystemFont(ofSize: 20)
        pageIndexLabel.textColor     = .white
        pageIndexLabel.textAlignment = .center
        pageIndexLabel.frame.size    = CGSize(width: 60, height: 27)
        pageIndexLabel.center        = CGPoint(x: UIScreen.main.bounds.width/2, y: 30)
        pageIndexLabel.text          = "\(innerInitialIndex + 1)/\(imageWrappers.count)"
    }
}

//MARK: - Show & Hide
extension ZJImageBrowser {
    
    func show(inView view: UIView? = nil, animated: Bool = true, enlargingAnimated: Bool = true, at index: Int? = nil) {
        guard let _superview = view == nil ? UIApplication.shared.keyWindow : view else { return }
        guard isShowing == false else { return }
        _superview.addSubview(self)
        _superview.addSubview(saveButton)
        _superview.addSubview(pageIndexLabel)
        if let index = index { innerInitialIndex = index }
        scrollToItem(at: IndexPath(item: innerInitialIndex, section: 0), at: .centeredHorizontally, animated: false)
        let currentImageWrapper = imageWrappers[innerInitialIndex]
        guard enlargingAnimated, let enlargingView = currentImageWrapper.imageContainer, let enlargingImage = currentImageWrapper.placeholderImage else {
            animate(withEnlargingView: nil, animated: animated)
            return
        }
        
        weak var enlargingViewSuperview  = enlargingView.superview
        let enlargingViewOriginalFrame   = enlargingView.frame
        let enlargingAnimationStartFrame = enlargingView.convert(enlargingView.bounds, to: _superview)
        _superview.addSubview(enlargingView)
        enlargingView.frame              = enlargingAnimationStartFrame
        
        // 使enlargingViewEndFrame的宽度和屏慕宽度保持一致, 宽高比和图片的宽高比一致
        // Make enlargingViewEndFrame's width equals to screen width, and its aspect ratio the same as its inner image;
        var enlargingAnimationEndFrame = CGRect.zero
        enlargingAnimationEndFrame.size.width  = _superview.frame.width
        enlargingAnimationEndFrame.size.height = _superview.frame.width * (enlargingImage.size.height/enlargingImage.size.width)
        enlargingAnimationEndFrame.origin      = CGPoint(x: 0, y: (_superview.frame.height - enlargingAnimationEndFrame.height)/2)
        animate(withEnlargingView: enlargingView, itsSuperview: enlargingViewSuperview, originalFrame: enlargingViewOriginalFrame, animationEndFrame: enlargingAnimationEndFrame, animated: true)
    }
    
    fileprivate func animate(withEnlargingView enlargingView: UIView? = nil, itsSuperview: UIView? = nil, originalFrame: CGRect = .zero, animationEndFrame: CGRect = .zero, animated: Bool) {
        if animated {
            if enlargingView != nil { isHidden = true }
            alpha                = 0
            saveButton.alpha     = 0
            pageIndexLabel.alpha = 0
            UIView.animate(withDuration: 0.25, animations: {
                self.alpha                = 1
                self.saveButton.alpha     = 1
                self.pageIndexLabel.alpha = 1
                if let enlargingView = enlargingView {
                    enlargingView.frame = animationEndFrame
                }
            }, completion: { (_) in
                if let enlargingView = enlargingView {
                    itsSuperview?.addSubview(enlargingView)
                    enlargingView.frame = originalFrame
                    self.isHidden = false
                }
                self.isShowing = true
            })
        } else {
            isShowing = true
        }
    }
    
    func dismiss(animated: Bool = true, force: Bool = false, completion: (() -> Swift.Void)? = nil) {
        if !isShowing && !force { return }
        if animated {
            weak var shrinkingViewSuperview: UIView?
            var originalFrame = CGRect.zero
            var shrinkingAnimationEndFrame = CGRect.zero
            var shrinkingView: UIView?
            if let _shrinkingView = imageWrappers[innerInitialIndex].imageContainer, let _superview = superview, let photoCell = visibleCells.first as? ZJImageCell {
                let rect = _shrinkingView.convert(_shrinkingView.bounds, to: _superview)
                if _superview.bounds.intersects(rect) {
                    shrinkingViewSuperview     = _shrinkingView.superview
                    originalFrame              = _shrinkingView.frame
                    shrinkingAnimationEndFrame = rect
                    shrinkingView              = _shrinkingView
                    _superview.addSubview(_shrinkingView)
                    _shrinkingView.frame = photoCell.imageContainer.frame
                    // 注意, 发现, 不写下面两句, 动画时shrinkingView内部控件的frame将不会是预期的效果
                    // Practice shows, if the following two expression were not called, frames of shrinkingView's subviews would't preform expectantly when animating.
                    _shrinkingView.setNeedsLayout()
                    _shrinkingView.layoutIfNeeded()
                    removeFromSuperview()
                    saveButton.isHidden = true
                }
            }
            
            UIView.animate(withDuration: 0.25, animations: {
                self.alpha                = 0
                self.saveButton.alpha     = 0
                self.pageIndexLabel.alpha = 0
                shrinkingView?.frame      = shrinkingAnimationEndFrame
            }, completion: { (_) in
                self.pageIndexLabel.removeFromSuperview()
                self.saveButton.removeFromSuperview()
                self.removeFromSuperview()
                self.alpha                = 1
                self.saveButton.alpha     = 1
                self.pageIndexLabel.alpha = 1
                self.isShowing = false
                if let shrinkingView = shrinkingView {
                    shrinkingView.frame = originalFrame
                    shrinkingViewSuperview?.addSubview(shrinkingView)
                }
                completion?()
            })
        } else {
            pageIndexLabel.removeFromSuperview()
            saveButton.removeFromSuperview()
            removeFromSuperview()
            isShowing = false
            completion?()
        }
    }
}

//MARK: - Handle Events
extension ZJImageBrowser {
    @objc fileprivate func saveButtonClicked() {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .restricted || status == .denied {
            albumAuthorizingFailed?(self, status)
            guard usesInternalHUD else { return }
            ZJImageBrowserHUD.show(message: ZJImageBrowser.albumAuthorizingFailedHint, inView: self, needsIndicator: false, hideAfter: 2.5)
            return
        }
        if visibleCells.count == 1, let photoCell = visibleCells.first as? ZJImageCell, let image = photoCell.image {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    @objc fileprivate func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: Any?) {
        photoSavingFailed?(self, image)
        guard usesInternalHUD else { return }
        var alertMessage = ""
        if error == nil {
            alertMessage = ZJImageBrowser.imageSavingSucceedHint
        } else {
            alertMessage = ZJImageBrowser.imageSavingFailedHint
        }
        hud?.hide(animated: false)
        ZJImageBrowserHUD.show(message: alertMessage, inView: self, needsIndicator: false)
    }
}

//MARK: - UICollectionViewDataSource & UICollectionViewDelegate
extension ZJImageBrowser: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageWrappers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZJImageCell.reuseIdentifier, for: indexPath) as! ZJImageCell
        cell.setImage(with: imageWrappers[indexPath.item])
        weak var weakCell = cell
        cell.singleTapped = { [weak self] _ in
            guard self != nil, let strongCell = weakCell else { return }
            if let closure = self?.imageViewSingleTapped {
                closure(self!, indexPath.item, strongCell.imageContainer.image)
            } else {
                self?.dismiss()
            }
        }
        cell.imageQueryingFinished = { [weak self] (succeed, image) in
            guard self != nil else { return }
            self?.imageQueryingFinished?(self!, succeed, image)
        }
        
        return cell
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let currentPage      = Int(scrollView.contentOffset.x / flowLayout.itemSize.width)
        innerInitialIndex    = currentPage
        pageIndexLabel.text  = "\(currentPage + 1)/\(imageWrappers.count)"
    }
}

