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
    var thumbnialUrls: [String] = [
        "https://wx4.sinaimg.cn/thumbnail/8e88b0c1ly1fh5s967ebdj20j60rpn3l.jpg",
        "https://wx4.sinaimg.cn/thumbnail/0064zot3ly1fds16s02lyj30hs1ysq9h.jpg",
        "https://wx1.sinaimg.cn/thumbnail/8e88b0c1ly1fhai40c5uwg20ax0k04qt.gif",
        "https://wx1.sinaimg.cn/thumbnail/8e88b0c1ly1fh2yxyebfpj20j62bvwrw.jpg",
        "http://ww2.sinaimg.cn/thumbnail/642beb18gw1ep3629gfm0g206o050b2a.gif",
        "https://wx2.sinaimg.cn/thumbnail/0064zot3ly1fds1693k1vj30rs12375r.jpg",
        "https://wx1.sinaimg.cn/thumbnail/b3e6a4ebgy1fef6qvmhoxg206o06o7e1.gif",
        "https://wx1.sinaimg.cn/thumbnail/b3e6a4ebgy1fef6r3pt68g20aa05qhdu.gif",
        "http://wx3.sinaimg.cn/thumbnail/93f9748agy1fgra0qkbv4g204j07e1ky.gif",
        "http://wx3.sinaimg.cn/thumbnail/ad673c42gy1fg5tx2one2j20hs0eawjb.jpg",
        "http://wx2.sinaimg.cn/thumbnail/6d7502b7gy1fguzmn355wj20dc0m8wft.jpg",
        "https://wx2.sinaimg.cn/thumbnail/005zZr0Dgy1fepk3pk0jwj30j64sgb29.jpg",
        "https://wx1.sinaimg.cn/thumbnail/62063690gy1fgswzj8n7sj20j60svagq.jpg",
        "https://wx2.sinaimg.cn/thumbnail/bf74a735gy1fguav5gv3dj20c80icwts.jpg",
        "https://wx1.sinaimg.cn/thumbnail/8e88b0c1gy1fh7vp4qdrhj20hs0zmq97.jpg",
        "http://ww4.sinaimg.cn/thumbnail/677febf5gw1erma1g5xd0j20k0esa7wj.jpg",
        "http://ww3.sinaimg.cn/thumbnail/5499ca13gy1fh7l0qj7zqj20qo140wn1.jpg",
        "http://wx4.sinaimg.cn/thumbnail/7a32ccbdly1fhclb6j1koj21kw1kwdur.jpg",
        "http://wx2.sinaimg.cn/thumbnail/ad673c42gy1fgssox1gy9g20c80c8x3x.gif",
        "http://wx1.sinaimg.cn/thumbnail/006yV7D9gy1fhagp8ap75j30u01hcb29.jpg",
        "http://wx4.sinaimg.cn/thumbnail/6aa09e8fly1fgzhz57adcj20qo0f1di3.jpg",
        "http://wx3.sinaimg.cn/thumbnail/ad673c42gy1ff18mqt1dmj20ku1auq8d.jpg",
        "http://wx3.sinaimg.cn/thumbnail/85d1229fgy1fha30boai5j20j60eemy1.jpg",
        "http://wx2.sinaimg.cn/thumbnail/ad673c42gy1fgyiypd707g20dw064qqi.gif"
    ]
    var cellHeights = [CGFloat]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(PhotosCell.self, forCellReuseIdentifier: PhotosCell.reuseIdentifier)
        for index in 0..<numberOfRows {
            let subArrayCount = thumbnialUrls.count/numberOfRows * (index + 1)
            let tempCell = PhotosCell(style: .default, reuseIdentifier: "")
            tempCell.thumbnailUrls = thumbnialUrls.sub(of: 0..<subArrayCount)
            let cellHeight = tempCell.sizeThatFits(CGSize(width: view.frame.width, height: CGFloat.greatestFiniteMagnitude)).height
            cellHeights.append(cellHeight)
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
        cell.thumbnailUrls = thumbnialUrls.sub(of: 0..<subArrayCount)
        cell.buttonDidClicked = { [weak self] button, index in
            guard self != nil else { return }
            let highQualityImageUrlStrings = self!.thumbnialUrls.map({ (url) -> String in
                return (url as NSString).replacingOccurrences(of: "thumbnail", with: "large") as String
            })
            
            var photoWrappers = [ZJPhotoWrapper]()
            var i = 0
            for urlString in highQualityImageUrlStrings.sub(of: 0..<subArrayCount) {
                var bool = true
                if i % 2 == 0 {
                    bool = false
                }
                let wrapper = ZJPhotoWrapper(highQualityImageUrl: urlString, shouldDownloadImage: bool, placeholderImage: cell.imageButtons[i].image(for: .normal), imageContainer: cell.imageButtons[i])
                photoWrappers.append(wrapper)
                i += 1
            }
            
            let browser = ZJPhotoBrowser(photoWrappers: photoWrappers, currentIndex: index)
            browser.show()
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath.row]
    }
}

//MARK: -
class PhotosCell: UITableViewCell {
    static let reuseIdentifier = "PhotosCell"
    
    deinit {
        debugPrint("---PhotosCell")
    }
    
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
                    button.tag                    = index
                    button.clipsToBounds          = true
                    if let url = URL(string: thumbnailUrls[index]) {
                        button.sd_setImage(with: url, for: .normal, placeholderImage: UIImage(named: "whiteplaceholder"))
                    }
                    button.addTarget(self, action: #selector(buttonClicked), for: .touchUpInside)
                    let buttonX = horiozntalMargin + CGFloat(index % maxItemsInOneLine) * (buttonSize + padding)
                    let buttonY = verticalInset + CGFloat(index/maxItemsInOneLine) * (buttonSize + verticalMargin)
                    button.frame = CGRect(x: buttonX, y: buttonY, width: buttonSize, height: buttonSize)
                    button.imageView?.contentMode = .scaleAspectFill
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

