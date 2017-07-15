//
//  PhotosViewController.swift
//  ProgressView
//
//  Created by luozhijun on 2017/7/5.
//  Copyright © 2017年 RickLuo. All rights reserved.
//

import UIKit
import SDWebImage

extension Array {
    func sub(of range: CountableRange<Int>) -> Array {
        var result = [Any]()
        for index in range.lowerBound..<range.upperBound {
            result.append(self[index])
        }
        return result as! Array<Element>
    }
}

class PhotosViewController: UITableViewController {

    deinit {
        print("---PhotosViewController")
    }
    
    let numberOfRows = 4
    
    var cellHeights = [CGFloat]()
    var previewingLocatedIndexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNaviBar()
        setupTableView()
    }
    
    fileprivate func setupNaviBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Prevent downloading", style: .plain, target: self, action: #selector(itemTapped))
    }
    
    fileprivate func setupTableView() {
        tableView.register(PhotosCell.self, forCellReuseIdentifier: PhotosCell.reuseIdentifier)
        for index in 0..<numberOfRows {
            let subArrayCount = thumbnialUrls.count/numberOfRows * (index + 1)
            let tempCell = PhotosCell(style: .default, reuseIdentifier: "")
            tempCell.thumbnailUrls = thumbnialUrls.sub(of: 0..<subArrayCount)
            let cellHeight = tempCell.sizeThatFits(CGSize(width: view.frame.width, height: CGFloat.greatestFiniteMagnitude)).height
            cellHeights.append(cellHeight)
        }
    }
    
    @objc fileprivate func itemTapped() {
        tableView.reloadData()
        if navigationItem.rightBarButtonItem?.title?.contains("Prevent") == true {
            SDImageCache.shared().clearMemory()
            SDImageCache.shared().clearDisk()
            navigationItem.rightBarButtonItem?.title = "Resum downloading"
        } else {
            navigationItem.rightBarButtonItem?.title = "Prevent downloading"
        }
    }
}

//MARK: UITableViewDataSource
extension PhotosViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRows
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PhotosCell.reuseIdentifier, for: indexPath) as! PhotosCell
        
        let subArrayCount = thumbnialUrls.count/numberOfRows * (indexPath.row + 1)
        cell.containerController = self
        cell.thumbnailUrls = thumbnialUrls.sub(of: 0..<subArrayCount)
        cell.buttonDidClicked = { [weak self] button, index in
            guard self != nil else { return }
            let highQualityImageUrlStrings = thumbnialUrls.map({ (url) -> String in
                return url.replacingOccurrences(of: "thumbnail", with: "large")
            })
            
            var imageWrappers = [ZJImageWrapper]()
            var i = 0
            for urlString in highQualityImageUrlStrings.sub(of: 0..<subArrayCount) {
                //FIXME: just for test
                var shouldDownloadImage = true
                if self!.navigationItem.rightBarButtonItem?.title?.contains("Resum") == true {
                    if i % 2 == 0 {
                        shouldDownloadImage = false
                    }
                }
                //End
                
                let wrapper = ZJImageWrapper(highQualityImageUrl: urlString, shouldDownloadImage: shouldDownloadImage, placeholderImage: cell.imageButtons[i].image(for: .normal), imageContainer: cell.imageButtons[i])
                imageWrappers.append(wrapper)
                i += 1
            }
            
            let browser = ZJImageBrowser(imageWrappers: imageWrappers, initialIndex: index)
            browser.show()
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath.row]
    }
}

//MARK: 3D Touch Adapting
@available(iOS 9.0, *)
extension PhotosViewController: UIViewControllerPreviewingDelegate {
 
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        let pointInTableView = previewingContext.sourceView.convert(location, to: tableView)
        guard
            let indexPath   = tableView.indexPathForRow(at: pointInTableView),
            let cell        = tableView.cellForRow(at: indexPath) as? PhotosCell,
            let imageButton = previewingContext.sourceView as? ImageButton
        else { return nil }
        previewingLocatedIndexPath = indexPath
        let index                  = imageButton.tag
        let highQualityImageUrl    = cell.thumbnailUrls[index].replacingOccurrences(of: "thumbnail", with: "large")
        let placeholderImage       = imageButton.image(for: .normal)
        let wrapper = ZJImageWrapper(highQualityImageUrl: highQualityImageUrl, shouldDownloadImage: true, placeholderImage: placeholderImage, imageContainer: nil)
        let target = ZJImageBrowserPreviewingController(imageWrapper: wrapper)
        target.preferredContentSize = target.supposedContentSize(with: placeholderImage)
        return target
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        guard
            let indexPath   = previewingLocatedIndexPath,
            let cell        = tableView.cellForRow(at: indexPath) as? PhotosCell,
            let imageButton = previewingContext.sourceView as? ImageButton
        else { return }
        var imageWrappers = [ZJImageWrapper]()
        let highQualityImageUrlStrings = cell.thumbnailUrls.map({ (url) -> String in
            return url.replacingOccurrences(of: "thumbnail", with: "large")
        })
        var index = 0
        for urlString in highQualityImageUrlStrings {
            let imageContainer   = cell.imageButtons[index]
            let placeholderImage = imageContainer.image(for: .normal)
            let wrapper = ZJImageWrapper(highQualityImageUrl: urlString, shouldDownloadImage: true, placeholderImage: placeholderImage, imageContainer: imageContainer)
            imageWrappers.append(wrapper)
            index += 1
        }
        let browser = ZJImageBrowser(imageWrappers: imageWrappers, initialIndex: imageButton.tag)
        browser.show(animated: false, enlargingAnimated: false)
    }
}

//MARK: -
class PhotosCell: UITableViewCell {
    static let reuseIdentifier = "PhotosCell"
    
    deinit {
        debugPrint("---PhotosCell")
    }
    
    weak var containerController: PhotosViewController?
    var buttonDidClicked: ((UIButton, Int) -> Swift.Void)?
    var thumbnailUrls = [String]() {
        didSet {
            let maxItemsInOneLine         = 3
            let padding         : CGFloat = 2
            let horiozntalMargin: CGFloat = 2
            let verticalMargin  : CGFloat = 2
            let buttonSize      : CGFloat = (UIScreen.main.bounds.width - CGFloat(maxItemsInOneLine + 1) * horiozntalMargin)/CGFloat(maxItemsInOneLine)
            let verticalInset   : CGFloat = 15
            
            var index = 0
            for _ in 0..<thumbnailUrls.count {
                var button: ImageButton!
                if imageButtons.count > index {
                    button = imageButtons[index]
                    button.isHidden = false
                } else {
                    button = ImageButton()
                    contentView.addSubview(button)
                    imageButtons.append(button)
                    button.tag           = index
                    button.clipsToBounds = true
                    if let url = URL(string: thumbnailUrls[index]) {
                        button.sd_setImage(with: url, for: .normal, placeholderImage: UIImage(named: "whiteplaceholder"))
                    }
                    button.addTarget(self, action: #selector(buttonClicked), for: .touchUpInside)
                    let buttonX = horiozntalMargin + CGFloat(index % maxItemsInOneLine) * (buttonSize + padding)
                    let buttonY = verticalInset + CGFloat(index/maxItemsInOneLine) * (buttonSize + verticalMargin)
                    button.frame = CGRect(x: buttonX, y: buttonY, width: buttonSize, height: buttonSize)
                    button.imageView?.contentMode = .scaleAspectFill
                    if #available(iOS 9.0, *), let containerController = containerController {
                        containerController.registerForPreviewing(with: containerController, sourceView: button)
                    }
                }
                index += 1
            }
            
            if index <= imageButtons.count {
                for index1 in index..<imageButtons.count {
                    imageButtons[index1].isHidden = true
                }
            }
        }
    }
    
    var thumbnails: [UIImage] {
        var result = [UIImage]()
        for button in imageButtons {
            if let image = button.image(for: .normal) {
                result.append(image)
            } else {
                result.append(UIImage(named: "placeholder")!)
            }
        }
        return result
    }
    var imageButtons    = [ImageButton]()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var result: CGSize = size
        let buttons = imageButtons.reversed()
        for button in buttons {
            if button.isHidden == false {
                result.height = button.frame.maxY + 15
                break
            }
        }
        return result
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func buttonClicked(sender: ImageButton) {
        buttonDidClicked?(sender, sender.tag)
    }
}

//MARK: -
class ImageButton: UIButton {
    deinit {
        debugPrint("---ImageButton")
    }
    
    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        return contentRect
    }
}

