//
//  ZJImageBrowser.swift
//
//  Created by luozhijun on 2017/7/5.
//  Copyright © 2017年 RickLuo. All rights reserved.
//

import UIKit
import Photos

internal func bundleImage(named: String) -> UIImage? {
    var path = "ZJImageBrowser.bundle" + "/\(named)"
    if let image = UIImage(named: path) {
        return image
    } else {
        path = "Frameworks/ZJImageBrowser.framework/" + path
        return UIImage(named: path)
    }
}

/// An simple full screen photo browser based on UICollectionView.
open class ZJImageBrowser: UICollectionView {
    open static var buttonHorizontalPadding: CGFloat = 20
    open static var buttonVerticalPadding  : CGFloat = 35
    open static var buttonHeight           : CGFloat = 27
    open static var pageSpacing            : CGFloat = 10
    
    open static var maximumZoomScale: CGFloat = 3
    
    open static var albumAuthorizingFailedHint = "Saving failed! Can't access your ablum, check in \"Settings\"->\"Privacy\"->\"Photos\"."
    open static var imageSavingSucceedHint     = "Saving succeed"
    open static var imageSavingFailedHint      = "Saving failed!"
    open static var retryButtonTitle           = "Downloading failed, Tap to retry"
    open static var saveActionTitle            = "Save to Album"
    open static var copyToPastboardActionTitle = "Copy to pastboard"
    open static var showsDebugHud              = false
    
    fileprivate var isShowing         = false
    fileprivate var saveButton        = UIButton(type: .system)
    fileprivate var deleteButton      = UIButton(type: .system)
    fileprivate var pageIndexLabel    = UILabel()
    fileprivate var innerCurrentIndex = 0 {
        didSet {
            if imageWrappers.count > 0 {
                pageIndexLabel.text = "\(innerCurrentIndex + 1)/\(imageWrappers.count)"
            } else {
                pageIndexLabel.text = nil
            }
        }
    }
    fileprivate weak var hud: ZJImageBrowserHUD?
    
    open var imageWrappers = [ZJImageWrapper]() {
        didSet {
            reloadData()
        }
    }
    open var currentIndex: Int {
        return innerCurrentIndex
    }
    open var containerRect: CGRect = UIScreen.main.bounds {
        didSet {
            let pageSpacing: CGFloat = ZJImageBrowser.pageSpacing
            frame = CGRect(x: containerRect.minX, y: containerRect.minY, width: containerRect.width + pageSpacing, height: containerRect.height)
            if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
                layout.itemSize = CGSize(width: containerRect.width + pageSpacing, height: containerRect.height)
                collectionViewLayout = layout
            }
        }
    }
    override open var isScrollEnabled: Bool {
        didSet {
            needsPageIndex = isScrollEnabled
            let tempValue  = isScrollEnabled
            super.isScrollEnabled = tempValue
        }
    }
    open var needsPageIndex: Bool = true {
        didSet {
            pageIndexLabel.isHidden = !needsPageIndex
        }
    }
    open var needsSaveButton: Bool = true {
        didSet {
            saveButton.isHidden = !needsSaveButton
        }
    }
    open var needsDeleteButton: Bool = false {
        didSet {
            deleteButton.isHidden = !needsDeleteButton
        }
    }
    
    /// Default is true. trun off it if you want use loacl HUD.
    /// 默认打开, 如果想用项目本地的hud提示异常, 请置为false
    open var usesInternalHUD   = true
    open var shrinkingAnimated = true
    open var imageViewSingleTapped : ((ZJImageBrowser, Int, UIImage?)         -> Swift.Void)?
    open var deleteActionAt        : ((ZJImageBrowser, Int, UIImage?)         -> Swift.Void)?
    open var albumAuthorizingFailed: ((ZJImageBrowser, PHAuthorizationStatus) -> Swift.Void)?
    open var photoSavingFailed     : ((ZJImageBrowser, UIImage)               -> Swift.Void)?
    /// 注意: 此闭包将不在主线程执行
    /// Note: this closure excutes in the global queue.
    open var imageQueryingFinished : ((ZJImageBrowser, Bool, UIImage?)        -> Swift.Void)?
    
    required public init(imageWrappers: [ZJImageWrapper], initialIndex: Int = 0, containerRect: CGRect = UIScreen.main.bounds) {
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
        self.imageWrappers = imageWrappers
        if initialIndex >= 0 && initialIndex < imageWrappers.count {
            self.innerCurrentIndex = initialIndex
        }
        
        isPagingEnabled = true
        dataSource      = self
        delegate        = self
        showsHorizontalScrollIndicator = false
        register(ZJImageCell.self, forCellWithReuseIdentifier: ZJImageCell.reuseIdentifier)
        
        setupSaveButton()
        setupDeleteButton()
        setupPageIndexLabel()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

//MARK: - Setup UI
extension ZJImageBrowser {
    override open func layoutSubviews() {
        super.layoutSubviews()
        saveButton.frame.origin = CGPoint(x: frame.width - ZJImageBrowser.buttonHorizontalPadding - 10 - saveButton.bounds.width, y: frame.height - ZJImageBrowser.buttonHeight - ZJImageBrowser.buttonVerticalPadding)
        
        var deleteButtonX = saveButton.frame.minX - 10 - deleteButton.bounds.width
        if needsSaveButton == false {
            deleteButtonX = saveButton.frame.origin.x
        }
        deleteButton.center.y = saveButton.center.y
        deleteButton.frame.origin.x = deleteButtonX
    }
    
    fileprivate func setupSaveButton() {
        saveButton.setImage(bundleImage(named: "icon_save")?.withRenderingMode(.alwaysOriginal), for: .normal)
        saveButton.sizeToFit()
        saveButton.addTarget(self, action: #selector(saveButtonClicked), for: .touchUpInside)
    }
    
    fileprivate func setupDeleteButton() {
        deleteButton.setImage(bundleImage(named: "icon_delete")?.withRenderingMode(.alwaysOriginal), for: .normal)
        deleteButton.sizeToFit()
        deleteButton.addTarget(self, action: #selector(deleteButtonClicked), for: .touchUpInside)
    }
    
    fileprivate func setupPageIndexLabel() {
        pageIndexLabel.font          = UIFont.boldSystemFont(ofSize: 20)
        pageIndexLabel.textColor     = .white
        pageIndexLabel.textAlignment = .center
        pageIndexLabel.frame.size    = CGSize(width: 60, height: 27)
        pageIndexLabel.center        = CGPoint(x: UIScreen.main.bounds.width/2, y: 30)
        pageIndexLabel.text          = "\(innerCurrentIndex + 1)/\(imageWrappers.count)"
    }
}

//MARK: - Show & Hide
extension ZJImageBrowser {
    
    open func show(inView view: UIView? = nil, animated: Bool = true, enlargingAnimated: Bool = true, at index: Int? = nil) {
        guard let _superview = view == nil ? UIApplication.shared.keyWindow : view else { return }
        guard isShowing == false else { return }
        _superview.addSubview(self)
        _superview.addSubview(saveButton)
        _superview.addSubview(deleteButton)
        _superview.addSubview(pageIndexLabel)
        saveButton.isHidden = !needsSaveButton
        deleteButton.isHidden = !needsDeleteButton
        if let index = index, index >= 0, index < imageWrappers.count { innerCurrentIndex = index }
        scrollToItem(at: IndexPath(item: innerCurrentIndex, section: 0), at: .centeredHorizontally, animated: false)
        let currentImageWrapper = imageWrappers[innerCurrentIndex]
        guard enlargingAnimated, let enlargingView = currentImageWrapper.imageContainer, let enlargingImage = currentImageWrapper.placeholderImage else {
            animate(animated: animated)
            return
        }
        
        let enlargingViewOriginalFrame   = enlargingView.frame
        let enlargingAnimationStartFrame = enlargingView.convert(enlargingView.bounds, to: _superview)
        
        let tempImageView           = UIImageView()
        tempImageView.frame         = enlargingAnimationStartFrame
        tempImageView.image         = currentImageWrapper.placeholderImage
        tempImageView.contentMode   = .scaleAspectFill
        tempImageView.clipsToBounds = true
        enlargingView.isHidden      = true
        _superview.addSubview(tempImageView)
        
        // 使enlargingViewEndFrame的宽度和屏慕宽度保持一致, 宽高比和图片的宽高比一致
        // Make enlargingViewEndFrame's width equals to screen width, and its aspect ratio the same as its inner image;
        var enlargingAnimationEndFrame = CGRect.zero
        enlargingAnimationEndFrame.size.width  = _superview.frame.width
        enlargingAnimationEndFrame.size.height = _superview.frame.width * (enlargingImage.size.height/enlargingImage.size.width)
        enlargingAnimationEndFrame.origin      = CGPoint(x: 0, y: (_superview.frame.height - enlargingAnimationEndFrame.height)/2)
        animate(withMirroredImageView: tempImageView, enlargingView: enlargingView, originalFrame: enlargingViewOriginalFrame, animationEndFrame: enlargingAnimationEndFrame, animated: true)
    }
    
    fileprivate func animate(withMirroredImageView mirroredImageView: UIImageView? = nil, enlargingView: UIView? = nil, originalFrame: CGRect = .zero, animationEndFrame: CGRect = .zero, animated: Bool) {
        if animated {
            if enlargingView != nil { isHidden = true }
            alpha                = 0
            saveButton.alpha     = 0
            deleteButton.alpha   = 0
            pageIndexLabel.alpha = 0
            UIView.animate(withDuration: 0.25, animations: {
                self.alpha                = 1
                self.saveButton.alpha     = 1
                self.deleteButton.alpha   = 1
                self.pageIndexLabel.alpha = 1
                if let mirroredImageView = mirroredImageView {
                    mirroredImageView.frame = animationEndFrame
                } else if let enlargingView = enlargingView {
                    enlargingView.frame     = animationEndFrame
                }
            }, completion: { (_) in
                self.isHidden = false
                enlargingView?.isHidden = false
                mirroredImageView?.removeFromSuperview()
                self.isShowing = true
            })
        } else {
            enlargingView?.isHidden = false
            isShowing = true
        }
    }
    
    open func dismiss(animated: Bool = true, shrinkingAnimated: Bool = true , force: Bool = false, completion: (() -> Swift.Void)? = nil) {
        if !isShowing && !force { return }
        if animated {
            var shrinkingView              : UIView?
            var mirroredImageView          : UIImageView!
            var shrinkingAnimationEndFrame = CGRect.zero
            if shrinkingAnimated, let _shrinkingView = imageWrappers[innerCurrentIndex].imageContainer, let _superview = superview, let photoCell = visibleCells.first as? ZJImageCell {
                let rect = _shrinkingView.convert(_shrinkingView.bounds, to: _superview)
                if _superview.bounds.intersects(rect) {
                    shrinkingAnimationEndFrame = rect
                    shrinkingView              = _shrinkingView
                    shrinkingView?.isHidden    = true

                    mirroredImageView = UIImageView()
                    _superview.addSubview(mirroredImageView)
                    mirroredImageView.frame         = photoCell.imageContainer.frame
                    mirroredImageView.image         = photoCell.image != nil ? photoCell.image : imageWrappers[innerCurrentIndex].placeholderImage
                    mirroredImageView.contentMode   = .scaleAspectFill
                    mirroredImageView.clipsToBounds = true
                    
                    removeFromSuperview()
                    saveButton.isHidden = true
                }
            }
            
            UIView.animate(withDuration: 0.25, animations: {
                self.alpha                = 0
                self.saveButton.alpha     = 0
                self.deleteButton.alpha   = 0
                self.pageIndexLabel.alpha = 0
                mirroredImageView?.frame  = shrinkingAnimationEndFrame
            }, completion: { (_) in
                self.pageIndexLabel.removeFromSuperview()
                self.saveButton.removeFromSuperview()
                self.deleteButton.removeFromSuperview()
                self.removeFromSuperview()
                self.alpha                = 1
                self.saveButton.alpha     = 1
                self.deleteButton.alpha   = 1
                self.pageIndexLabel.alpha = 1
                self.isShowing            = false
                shrinkingView?.isHidden   = false
                mirroredImageView?.removeFromSuperview()
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
    
    @objc fileprivate func deleteButtonClicked() {
        var image: UIImage?
        if visibleCells.count == 1, let photoCell = visibleCells.first as? ZJImageCell {
            image = photoCell.image
        }
        if imageWrappers.count <= 1 {
            dismiss()
            imageWrappers.remove(at: innerCurrentIndex)
            deleteActionAt?(self, innerCurrentIndex, image)
            innerCurrentIndex = 0
            return
        }
        
        performBatchUpdates({
            self.imageWrappers.remove(at: self.innerCurrentIndex)
            self.deleteItems(at: [IndexPath(item: self.innerCurrentIndex, section: 0)])
        }, completion: { _ in
            self.deleteActionAt?(self, self.innerCurrentIndex, image)
            if let currentIndexPath = self.indexPathsForVisibleItems.first {
                self.innerCurrentIndex = currentIndexPath.item
            } else {
                self.innerCurrentIndex -= 1
            }
        })
    }
}

//MARK: - UICollectionViewDataSource & UICollectionViewDelegate
extension ZJImageBrowser: UICollectionViewDelegate, UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageWrappers.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZJImageCell.reuseIdentifier, for: indexPath) as! ZJImageCell
        cell.setImage(with: imageWrappers[indexPath.item])
        weak var weakCell = cell
        cell.singleTapped = { [weak self] _ in
            guard self != nil, let strongCell = weakCell else { return }
            if let closure = self?.imageViewSingleTapped {
                closure(self!, indexPath.item, strongCell.imageContainer.image)
            } else {
                self!.dismiss(shrinkingAnimated: self!.shrinkingAnimated)
            }
        }
        cell.imageQueryingFinished = { [weak self] (succeed, image) in
            guard self != nil else { return }
            self?.imageQueryingFinished?(self!, succeed, image)
        }
        
        return cell
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let currentPage      = Int(scrollView.contentOffset.x / flowLayout.itemSize.width)
        innerCurrentIndex    = currentPage
    }
}

