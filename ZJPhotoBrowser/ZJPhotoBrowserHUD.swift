//
//  ZJPhotoBrowserHUD.swift
//  ProgressView
//
//  Created by luozhijun on 2017/7/7.
//  Copyright © 2017年 RickLuo. All rights reserved.
//

import UIKit

class ZJPhotoBrowserHUD: UIToolbar {

    fileprivate var label = UILabel()
    fileprivate var indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    required init(message: String?) {
        super.init(frame: .zero)
        layer.cornerRadius = 5
        clipsToBounds = true
        
        addSubview(label)
        label.text          = message
        label.textColor     = .black
        label.font          = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        
        addSubview(indicator)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let horizontalMargin: CGFloat    = 30
        let padding         : CGFloat    = 10
        let maxWidth        : CGFloat    = frame.width - 2 * horizontalMargin
        let indicatorNeedsWidth: CGFloat = indicator.isHidden ? 0 : padding + indicator.bounds.width
        let messageNeedsSize = label.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        label.frame.size = messageNeedsSize
        label.center     = CGPoint(x: bounds.midX + indicatorNeedsWidth/2, y: bounds.midY)
        indicator.center = CGPoint(x: label.frame.minX - padding - indicator.bounds.width/2, y: label.center.y)
    }
    
    @discardableResult
    class func show(message: String?, inView view: UIView? = nil, animated: Bool = true, needsIndicator: Bool = true, hideAfter interval: TimeInterval? = 1.2) -> ZJPhotoBrowserHUD? {
        var superView: UIView!
        if view != nil {
            superView = view
        } else if let window = UIApplication.shared.keyWindow {
            superView = window
        } else {
            return nil
        }
        
        let hud = ZJPhotoBrowserHUD(message: message)
        hud.indicator.isHidden = !needsIndicator
        superView.addSubview(hud)
        let verticalMargin  : CGFloat = 15
        let horizontalMargin: CGFloat = 30
        let padding         : CGFloat = 10
        let maxWidth        : CGFloat = superView.frame.width - 4 * horizontalMargin
        let messageNeedsSize = hud.label.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        var indicatorNeedsWidth: CGFloat = 0
        if needsIndicator {
            hud.indicator.startAnimating()
            indicatorNeedsWidth = padding + hud.indicator.bounds.width
        }
        let hudNeedSize = CGSize(width: messageNeedsSize.width + 2 * horizontalMargin + indicatorNeedsWidth, height: messageNeedsSize.height + 2 * verticalMargin)
        hud.frame.size  = hudNeedSize
        hud.center      = CGPoint(x: superView.bounds.midX, y: superView.bounds.midY)

        if animated {
            hud.alpha = 0
            UIView.animate(withDuration: 0.25, animations: { 
                hud.alpha = 1
            }, completion: { (_) in
                
            })
        }
        
        guard let interval = interval else { return hud }
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            hud.hide()
        }
        return hud
    }
    
    func hide(animated: Bool = true) {
        indicator.stopAnimating()
        UIView.animate(withDuration: 0.25, animations: { 
            self.alpha = 0
        }) { (_) in
            self.removeFromSuperview()
            self.alpha = 1
        }
    }
}
