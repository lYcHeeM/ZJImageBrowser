//
//  ZJPhotoBrowser.swift
//
//  Created by luozhijun on 2017/7/5.
//  Copyright © 2017年 RickLuo. All rights reserved.
//

import UIKit
import Photos

let ZJPhotoBrowserButtonHorizontalPadding: CGFloat = 20
let ZJPhotoBrowserButtonVerticalPadding  : CGFloat = 35
let ZJPhotoBrowserButtonHeight           : CGFloat = 27

@objc protocol ZJPhotoBrowserDelegate: NSObjectProtocol {
    @objc optional func photoBrowser(_ browser: ZJPhotoBrowser, placeholderImageAt index: Int) -> UIImage?
}

class ZJPhotoBrowser: UICollectionView {
    
    deinit {
        debugPrint("--ZJPhotoBrowser")
    }
    
    fileprivate var photoWrappers  = [ZJPhotoWrapper]()
    fileprivate var isShowing      = false
    fileprivate var saveButton     = UIButton(type: .system)
    fileprivate var pageIndexLabel = UILabel()
    fileprivate var innerCurrentIndex: Int = 0
    fileprivate weak var hud: ZJPhotoBrowserHUD?
    
    var currentIndex: Int {
        return innerCurrentIndex
    }
    
    var needsPageIndex: Bool = true {
        didSet {
            pageIndexLabel.isHidden = !needsPageIndex
        }
    }
    var placeholderImageAtIndex: ((Int) -> UIImage?)?
    weak var browserDelegate: ZJPhotoBrowserDelegate?
    
    required init(photoWrappers: [ZJPhotoWrapper], currentIndex: Int = 0) {
        let layout = UICollectionViewFlowLayout()
        let screenSize                 = UIScreen.main.bounds.size
        // 每个item, 除了实际内容, 尾部再加一段空白间隙, 以实现和ScrollView一样的翻页效果.
        // 意识到设置minimumLineSpacing = 10, 并增加collectionView相同的宽度, 
        // 似乎也能达到这个效果, 但由于最后一页尾部不存在lineSpacing, collectionView的contentSize将无法完全展示最后一页, 即最后一页末尾10距离的内容将不能显示.
        let pageSpacing: CGFloat       = 10
        layout.itemSize                = CGSize(width: screenSize.width + pageSpacing, height: screenSize.height)
        layout.scrollDirection         = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing      = 0
        
        super.init(frame: CGRect(x: 0, y: 0, width: screenSize.width + pageSpacing, height: screenSize.height), collectionViewLayout: layout)
        self.photoWrappers     = photoWrappers
        self.innerCurrentIndex = currentIndex
        
        isPagingEnabled = true
        dataSource      = self
        delegate        = self
        showsHorizontalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        register(ZJPhotoCell.self, forCellWithReuseIdentifier: ZJPhotoCell.reuseIdentifier)
        
        setupSaveButton()
        setupPageIndexLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

//MARK: - Setup UI
extension ZJPhotoBrowser {
    override func layoutSubviews() {
        super.layoutSubviews()
        saveButton.frame.origin = CGPoint(x: frame.width - ZJPhotoBrowserButtonHorizontalPadding - 10 - saveButton.bounds.width, y: frame.height - ZJPhotoBrowserButtonHeight - ZJPhotoBrowserButtonVerticalPadding)
        saveButton.frame.size.height = ZJPhotoBrowserButtonHeight
    }
    
    fileprivate func setupSaveButton() {
        // 由于self继承ScrollView, 如果直接把button加到self上, 则会跟随滚动
        // 此处可耍小技巧, 把button加到一个空的backgroundView上, 
        // 则可避免修改整个browser的视图结构, 可直接以CollectionView为最底层
        saveButton.setTitle("  保存  ", for: .normal)
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
        pageIndexLabel.text          = "\(innerCurrentIndex + 1)/\(photoWrappers.count)"
    }
}

//MARK: - Show & Hide
extension ZJPhotoBrowser {
    
    func show(animated: Bool = true, enlargingAnimated: Bool = true, at index: Int? = nil) {
        guard let window = UIApplication.shared.keyWindow else { return }
        guard isShowing == false else { return }
        window.addSubview(self)
        window.addSubview(saveButton)
        window.addSubview(pageIndexLabel)
        if let index = index {
            innerCurrentIndex = index
        }
        scrollToItem(at: IndexPath(item: innerCurrentIndex, section: 0), at: .centeredHorizontally, animated: false)
        let currentPhotoWrapper = photoWrappers[innerCurrentIndex]
        guard enlargingAnimated, let enlargingView = currentPhotoWrapper.imageContainer, let enlargingImage = currentPhotoWrapper.placeholderImage else {
            animate(withEnlargingView: nil, animated: animated)
            return
        }
        weak var enlargingViewSuperview  = enlargingView.superview
        let enlargingViewOriginalFrame   = enlargingView.frame
        let enlargingAnimationStartFrame = enlargingView.convert(enlargingView.bounds, to: window)
        window.addSubview(enlargingView)
        enlargingView.frame         = enlargingAnimationStartFrame
        
        // 使图片宽度和屏慕宽度保持一致, 宽高比和图片的宽高比一致
        var enlargingAnimationEndFrame = CGRect.zero
        enlargingAnimationEndFrame.size.width  = window.frame.width
        enlargingAnimationEndFrame.size.height = window.frame.width * (enlargingImage.size.height/enlargingImage.size.width)
        enlargingAnimationEndFrame.origin      = CGPoint(x: 0, y: (window.frame.height - enlargingAnimationEndFrame.height)/2)
        animate(withEnlargingView: enlargingView, itsSuperview: enlargingViewSuperview, originalFrame: enlargingViewOriginalFrame, animationEndFrame: enlargingAnimationEndFrame, animated: true)
    }
    
    fileprivate func animate(withEnlargingView enlargingView: UIView? = nil, itsSuperview: UIView? = nil, originalFrame: CGRect = .zero, animationEndFrame: CGRect = .zero, animated: Bool) {
        if animated {
            if enlargingView != nil {
                isHidden = true
            }
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
    
    func dismiss(animated: Bool = true) {
        guard isShowing else { return }
        if animated {
            weak var shrinkingViewSuperview: UIView?
            var originalFrame = CGRect.zero
            var shrinkingAnimationEndFrame = CGRect.zero
            var shrinkingView: UIView?
            if let _shrinkingView = photoWrappers[innerCurrentIndex].imageContainer, let window = UIApplication.shared.keyWindow, let photoCell = visibleCells.first as? ZJPhotoCell {
                let rect = _shrinkingView.convert(_shrinkingView.bounds, to: window)
                if window.bounds.contains(rect) {
                    shrinkingViewSuperview = _shrinkingView.superview
                    originalFrame = _shrinkingView.frame
                    shrinkingAnimationEndFrame = rect
                    shrinkingView = _shrinkingView
                    window.addSubview(_shrinkingView)
                    _shrinkingView.frame = photoCell.imageContainer.frame
                    // 注意, 发现, 不写下面两句, 动画时enlargingView内部控件的frame将不会是预期的效果
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
            })
        } else {
            pageIndexLabel.removeFromSuperview()
            saveButton.removeFromSuperview()
            removeFromSuperview()
            isShowing = false
        }
    }
}

//MARK: - Handle Events
extension ZJPhotoBrowser {
    @objc fileprivate func saveButtonClicked() {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .restricted || status == .denied {
            ZJPhotoBrowserHUD.show(message: "Saving failed! Can't access your ablum, check in \"Settings\"->\"Privacy\"->\"Photos\".", inView: self, needsIndicator: false, hideAfter: 2)
            return
        }
        if visibleCells.count == 1, let photoCell = visibleCells.first as? ZJPhotoCell, let image = photoCell.image {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    @objc fileprivate func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: Any?) {
        var alertMessage = ""
        if error == nil {
            alertMessage = "Saving succeed!"
        } else {
            alertMessage = "Saving failed!"
        }
        hud?.hide(animated: false)
        ZJPhotoBrowserHUD.show(message: alertMessage, inView: self, needsIndicator: false)
    }
}

//MARK: - UICollectionViewDataSource & UICollectionViewDelegate
extension ZJPhotoBrowser: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoWrappers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZJPhotoCell.reuseIdentifier, for: indexPath) as! ZJPhotoCell
        var placeholderImage = photoWrappers[indexPath.item].placeholderImage
        if let image = placeholderImageAtIndex?(indexPath.item) {
            placeholderImage = image
        }
        if placeholderImage == nil {
            placeholderImage = UIImage(named: "placeholder")
        }
        cell.setImage(withUrl: photoWrappers[indexPath.item].highQualityImageUrl, placeholderImage: placeholderImage)
        cell.singleTapped = { [weak self] _ in
            self?.dismiss()
        }
        
        return cell
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let currentPage      = Int(scrollView.contentOffset.x / flowLayout.itemSize.width)
        innerCurrentIndex    = currentPage
        pageIndexLabel.text  = "\(currentPage + 1)/\(photoWrappers.count)"
    }
}

