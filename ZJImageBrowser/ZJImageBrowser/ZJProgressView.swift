//
//  ZJProgressView.swift
//  ProgressView
//
//  Created by luozhijun on 2017/7/4.
//  Copyright © 2017年 RickLuo. All rights reserved.
//

import UIKit

public enum ZJProgressViewStyle: Int {
    /// 饼状
    case pie
    /// 环形
    case loop
    /// 长条
    case bar
}

open class ZJProgressView: UIView {
    
    fileprivate var style: ZJProgressViewStyle = .pie
    fileprivate var backgroundLayer: CAShapeLayer = CAShapeLayer()
    fileprivate var outLineLayer   : CAShapeLayer = CAShapeLayer()
    fileprivate var progressLayer  : CAShapeLayer = CAShapeLayer()
    fileprivate var progressBar    : UIView!
    
    fileprivate var previousProgress: CGFloat = 0
    open var progress: CGFloat = 0 {
        didSet {
            var usingProgress = progress
            if usingProgress < 0 || usingProgress == -0 {
                usingProgress = 0
            } else if usingProgress > 1 {
                usingProgress = 1
            }
            isHidden = usingProgress <= 0
            drawShape(withProgress: usingProgress, animated: animated)
        }
    }
    open var animated             : Bool         = false
    open var animationDuration    : TimeInterval = 0.25
    open var isRemovedOnCompletion: Bool         = true
    open var backgroundMaskColor  : UIColor = UIColor(white: 0, alpha: 0.15) {
        didSet {
            backgroundLayer.fillColor = backgroundMaskColor.cgColor
        }
    }
    open override var tintColor: UIColor? {
        didSet {
            outLineLayer.strokeColor     = tintColor?.cgColor
            progressLayer.strokeColor    = tintColor?.cgColor
            progressBar?.backgroundColor = tintColor
        }
    }
    
    public required init(frame: CGRect, style: ZJProgressViewStyle = .pie, initialProgress: CGFloat = 0, outlineWidth: CGFloat = 1, animated: Bool = false, animationDuration: TimeInterval = 0.25) {
        self.style                = style
        self.progress             = initialProgress
        self.animated             = animated
        self.animationDuration    = animationDuration
        backgroundLayer.fillColor = UIColor(white: 0, alpha: 0.15).cgColor
        outLineLayer.lineWidth    = outlineWidth
        outLineLayer.fillColor    = UIColor.clear.cgColor
        outLineLayer.strokeColor  = UIColor.white.cgColor
        if style != .bar {
            progressLayer.strokeColor = UIColor.white.cgColor
            progressLayer.fillColor   = UIColor.clear.cgColor
        } else {
            progressBar = UIView()
            progressBar.backgroundColor = UIColor.white
        }
        
        // 使宽高一致
        // keep width == height, when pie\loop style;
        var tempF = frame
        if style == .pie || style == .loop {
            let minValue      = min(frame.width, frame.height)
            tempF.size.width  = minValue
            tempF.size.height = minValue
        }
        
        super.init(frame: tempF)
        tintColor       = .white
        backgroundColor = UIColor.clear
        layer.addSublayer(backgroundLayer)
        layer.addSublayer(outLineLayer)
        if style != .bar {
            layer.addSublayer(progressLayer)
        } else {
            addSubview(progressBar)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(animationDidStop), name: .animationDidStop, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

//MARK: - SetupUI
extension ZJProgressView {
    
    open override var frame: CGRect {
        didSet {
            backgroundLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: bounds.height/2).cgPath
            let outlineRect = CGRect(x: outLineLayer.lineWidth/2, y: outLineLayer.lineWidth/2, width: frame.width - outLineLayer.lineWidth, height: frame.height - outLineLayer.lineWidth)
            let outline = UIBezierPath(roundedRect: outlineRect, cornerRadius: bounds.height/2)
            outLineLayer.path = outline.cgPath
            let space = outLineLayer.lineWidth * 3
            
            if style == .bar {
                let startXY = outLineLayer.lineWidth + space
                progressBar?.frame = CGRect(x: startXY, y: startXY, width: 0, height: frame.height - startXY * 2)
                if progressBar != nil {
                    progressBar.layer.cornerRadius = progressBar!.frame.height/2
                }
            }
            
            let tempF = frame
            super.frame = tempF
            
            if progress > 0 && progress <= 1 {
                drawShape(withProgress: progress, animated: animated)
            }
        }
    }
    
    fileprivate func drawShape(withProgress progress: CGFloat = 0, animated: Bool = false) {
        let spacing: CGFloat = outLineLayer.lineWidth * 3
        switch style {
        case .pie, .loop:
            var progressPath: UIBezierPath!
            let arcCenter   : CGPoint = CGPoint(x: frame.width/2, y: frame.height/2)
            var arcRadius   : CGFloat!
            var startAngle  : CGFloat = -CGFloat.pi/2 + CGFloat.pi * 2 * previousProgress
            // 实测发现, 如果从上次结束的角度开始画当前进度的图形, 会有一条缝隙
            // 为了无缝连接上一次画出的图形, 此处不从上次结束的位置开始画, 而是回退5度后再画, 重叠5度无视觉影响
            // Practice shows that, if we start drawing a layer segment (which will display current progress) from previous angle, then a tinny gap between current layer segment and the previous one appears.
            // So I turn back 5 degrees current layer segment begins to draw to achieve a much better appearance.
            // 注意当previousProgress <= 5/360时, 如果也回退5度, 会造成起始角度小于-2/π的现象.
            if previousProgress > 5/360 && previousProgress < 1 {
                startAngle -= CGFloat.pi * 2 / 360 * 5
            }
            let endAngle : CGFloat = -CGFloat.pi/2 + CGFloat.pi * 2 * progress
            var lineWidth: CGFloat!
            var lineCap  : String = "butt"
            
            if style == .pie {
                // 注意lineWidth属性, 它有一半的宽度是超出path所包住的范围
                // 鉴于此, 为实现画一个实心圆, 可把UIBezierPath中的arcRadius设为此圆半径的一半(所以下面除以4), 再把lineWidth与此圆的半径保持一致
                // Notice that half scope of 'lineWidth' will overstep the wrapped area by path.
                // So in order to draw a solid circle, one of the many ways is making 'arcRadius' half value as the final circle's radius (that's why in the following expression, 'arcRadius' is divided by 4), and set the 'lineWidth' equal to the final circle's radius.
                arcRadius = (frame.width - outLineLayer.lineWidth * 2 - spacing * 2)/4
                lineWidth = arcRadius * 2
            } else {
                lineWidth = frame.width/12.5
                arcRadius = (frame.width - outLineLayer.lineWidth * 2 - spacing * 2 - lineWidth)/2
                lineCap   = "round"
            }
            progressPath = UIBezierPath(arcCenter: arcCenter, radius: arcRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            
            let segmentLayer = CAShapeLayer()
            segmentLayer.fillColor   = UIColor.clear.cgColor
            segmentLayer.strokeColor = tintColor?.cgColor
            segmentLayer.lineWidth   = lineWidth
            segmentLayer.lineCap     = lineCap
            segmentLayer.path        = progressPath.cgPath
            layer.addSublayer(segmentLayer)
            
            if animated {
                let animation = CABasicAnimation(keyPath: "strokeEnd")
                animation.fromValue = 0
                animation.toValue   = 1
                animation.duration  = animationDuration
                animation.delegate  = ZJProgressViewAnimationDelegate()
                animation.isRemovedOnCompletion = false
                segmentLayer.add(animation, forKey: "animation")
            } else {
                if progress >= 1 && isRemovedOnCompletion {
                    removeFromSuperview()
                }
            }
        case .bar:
            let startX: CGFloat = outLineLayer.lineWidth + spacing
            let width : CGFloat = frame.width - 2 * startX
            if animated {
                UIView.animate(withDuration: animationDuration, animations: {
                    self.progressBar.frame.size.width = progress * width
                }, completion: { (_) in
                    if self.progress >= 1 && self.isRemovedOnCompletion {
                        self.removeFromSuperview()
                    }
                })
            } else {
                progressBar.frame.size.width = progress * width
                if progress >= 1 && isRemovedOnCompletion {
                    removeFromSuperview()
                }
            }
        }
        previousProgress = progress
        
        // reset
        if progress >= 1 {
            previousProgress = 0
        }
    }
    
    @objc fileprivate func animationDidStop() {
        if progress >= 1 && isRemovedOnCompletion {
            removeFromSuperview()
        }
    }
}

fileprivate extension Notification.Name {
    static let animationDidStop: Notification.Name = Notification.Name("__animationDidStop")
}

/// 因CABasicAnimation的delegate是strong类型, 用weak var设置此delegate自然也无效果, 这里用一个中间类来避免循环引用.
/// Considering 'delegate' of 'CABasicAnimation' is strong, and 'weak var' doesn't make sense, so this intermediate class is born to avoid retain cycle.
fileprivate class ZJProgressViewAnimationDelegate: NSObject, CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            NotificationCenter.default.post(name: .animationDidStop, object: self)
        }
    }
}
