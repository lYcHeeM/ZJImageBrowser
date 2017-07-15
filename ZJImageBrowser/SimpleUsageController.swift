//
//  SimpleUsageController.swift
//  ZJImageBrowser
//
//  Created by luozhijun on 2017/7/14.
//  Copyright © 2017年 RickLuo. All rights reserved.
//

import UIKit
import SDWebImage

class SimpleUsageController: UIViewController {

    @IBOutlet var imageViews: [UIImageView]!
    
    var browser = ZJImageBrowser(imageWrappers: [])
    var imageWrappers = [ZJImageWrapper]()
    var enlargingShrinkingAnimation = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var index = 0
        for imageView in imageViews {
            imageView.sd_setImage(with: URL(string: thumbnialUrls[index]), placeholderImage: UIImage(named: "whiteplaceholder"))
            
            imageView.isUserInteractionEnabled = true
            imageView.contentMode              = .scaleAspectFill
            imageView.clipsToBounds            = true
            
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
            imageView.addGestureRecognizer(recognizer)
            imageView.tag = index
            index += 1
        }
    }

    @objc fileprivate func imageTapped(recoginzer: UITapGestureRecognizer) {
        guard let imageView = recoginzer.view as? UIImageView else { return }
        if imageWrappers.isEmpty {
            var index = 0
            for imageView in imageViews {
                /// 新浪图片URL结构的规律, 替换thumbnail为large则能获取大图
                ///
                let highQualityUrlString = thumbnialUrls[index].replacingOccurrences(of: "thumbnail", with: "large")
                let wrapper = ZJImageWrapper(highQualityImageUrl: highQualityUrlString, shouldDownloadImage: true, placeholderImage: imageView.image, imageContainer: imageView)
                imageWrappers.append(wrapper)
                index += 1
            }
            browser.imageWrappers = imageWrappers
        }
        browser.show(inView: navigationController?.view, animated: true, enlargingAnimated: enlargingShrinkingAnimation, at: imageView.tag)
    }
    
    @IBAction func enlargingShrinkingAnimationSwitchValueChanged(_ sender: UISwitch) {
        enlargingShrinkingAnimation = sender.isOn
        browser.shrinkingAnimated   = sender.isOn
    }
    
    @IBAction func needsPageIndexSwitchValueChanged(_ sender: UISwitch) {
        browser.needsPageIndex = sender.isOn
    }
    
    @IBAction func isScrollEnabledSwitchValueChanged(_ sender: UISwitch) {
        browser.isScrollEnabled = sender.isOn
    }
    
    @IBAction func needsSaveButtonSwitchValueChanged(_ sender: UISwitch) {
        browser.needsSaveButton = sender.isOn
    }
    
    @IBAction func usesInternalHUDSwitchValueChanged(_ sender: UISwitch) {
        browser.usesInternalHUD = sender.isOn
    }
    
}
