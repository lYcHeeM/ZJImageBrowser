# ZJImageBrowser
An simple iOS image browser based on UICollectionView written in Swift.

[![Version](https://img.shields.io/badge/pod-v0.0.5-brightgreen.svg)](https://img.shields.io/badge/pod-v0.0.4-brightgreen.svg)

## Requirements

- iOS 8.0+ / macOS 10.10+ 
- Xcode 8.0+
- Swift 3.0+ (You can also use it in Objective-C project.)

## Screen shots
![SwitchImageDemo](http://wx3.sinaimg.cn/mw690/71842c1aly1fhkqr7axc6g20dc0npx6q.gif)
![ProgressDemo](https://wx4.sinaimg.cn/large/71842c1aly1fhkqr0ax2mg20dc0npb2c.gif)
![3dtouchDemo_1](https://wx4.sinaimg.cn/large/71842c1aly1fhkqqlmdisg20dc0np7wi.gif)
![3dtouchDemo_2](https://wx3.sinaimg.cn/large/71842c1aly1fhkqqgu4vbg20dc0npnpd.gif)
![SavingFailedDemo](https://wx2.sinaimg.cn/large/71842c1aly1fhkqqrfh9fg20dc0npkjm.gif)

## Usage
### Simple 
```swift
let urlStrings1: [String] = [
            "https://wx4.sinaimg.cn/bmiddle/8e88b0c1ly1fh5s967ebdj20j60rpn3l.jpg",
            "https://wx4.sinaimg.cn/bmiddle/0064zot3ly1fds16s02lyj30hs1ysq9h.jpg",
            "https://wx1.sinaimg.cn/bmiddle/8e88b0c1ly1fhai40c5uwg20ax0k04qt.gif",
        ]
let localImageNames: [String] = [
    "local_1.jpg",
    "local_2.jpg",
    "local_3.jpg"
]
let urlStrings2: [String] = [
    "https://wx1.sinaimg.cn/bmiddle/8e88b0c1ly1fh2yxyebfpj20j62bvwrw.jpg",
    "http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif",
    "https://wx2.sinaimg.cn/bmiddle/0064zot3ly1fds1693k1vj30rs12375r.jpg"
]
var imageWrappers = [ZJImageWrapper]()
for urlStr in urlStrings1 {
    let imageWrapper = ZJImageWrapper(highQualityImageUrl: urlStr, shouldDownloadImage: true, placeholderImage: nil, imageContainer: nil)
    imageWrappers.append(imageWrapper)
}
for name in localImageNames {
    let image = UIImage(named: name)
    let imageWrapper = ZJImageWrapper(image: image, highQualityImageUrl: nil, shouldDownloadImage: false, placeholderImage: image, imageContainer: nil)
    imageWrappers.append(imageWrapper)
}
for urlStr in urlStrings2 {
    let imageWrapper = ZJImageWrapper(highQualityImageUrl: urlStr, shouldDownloadImage: true, placeholderImage: nil, imageContainer: nil)
    imageWrappers.append(imageWrapper)
}
let browser = ZJImageBrowser(imageWrappers: imageWrappers)
browser.show()
```

### Specify initial image index
```swift
let browser = ZJImageBrowser(imageWrappers: imageWrappers, initialIndex: yourSpecifiedInitialIndex)
browser.show()
// Also can: browser.show(at: yourSpecifiedInitialIndex)
```

### Restrict bounds
By default, ZJImageBrowser is full screen displayed. You can also give a rect to make it smaller and show at where you want.
```swift
let browser = ZJImageBrowser(imageWrappers: imageWrappers, initialIndex: yourSpecifiedInitialIndex, containerRect: yourSpecifiedRect)
browser.show()
```

### Run the demo project to see other usage, such as 3D Touch support.

## Integration

#### CocoaPods (iOS 8+, OS X 10.9+)

You can use [CocoaPods](http://cocoapods.org/) to install `ZJImageBrowser` by adding it to your `Podfile`:

```ruby
platform :ios, '8.0'
use_frameworks!

target 'YourAppTargetName' do
	pod 'ZJImageBrowser', '0.0.5'
end
```

Requires CocoaPods version 1.0.0+

## TODO

* Support landscape orientation;
* Complement demo project, providing more detail examples;
* Pre-download images for indexes other than the initial one;
* Dismissed by vertical pan gesture.


## License

ZJImageBrowser is released under the MIT license. See LICENSE for details.