# ZJImageBrowser
An simple iOS image browser based on UICollectionView written in Swift.

## Requirements

- iOS 8.0+ / macOS 10.10+ 
- Xcode 8.0+
- Swift 3.0+ (You can also use it in Objective-C project.)

## Usage
### Simple 
```swift
let urlStrings: [String] = [
            "https://wx4.sinaimg.cn/bmiddle/8e88b0c1ly1fh5s967ebdj20j60rpn3l.jpg",
            "https://wx4.sinaimg.cn/bmiddle/0064zot3ly1fds16s02lyj30hs1ysq9h.jpg",
            "https://wx1.sinaimg.cn/bmiddle/8e88b0c1ly1fhai40c5uwg20ax0k04qt.gif",
            "https://wx1.sinaimg.cn/bmiddle/8e88b0c1ly1fh2yxyebfpj20j62bvwrw.jpg",
            "http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif",
            "https://wx2.sinaimg.cn/bmiddle/0064zot3ly1fds1693k1vj30rs12375r.jpg"
        ]
var imageWrappers = [ZJImageWrapper]()
for urlStr in urlStrings {
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

## Integration

#### CocoaPods (iOS 8+, OS X 10.9+)

You can use [CocoaPods](http://cocoapods.org/) to install `ZJImageBrowser` by adding it to your `Podfile`:

```ruby
platform :ios, '8.0'
use_frameworks!

target 'YourAppTargetName' do
	pod 'ZJImageBrowser'
end
```

Requires CocoaPods version 1.0.0+

## License

ZJImageBrowser is released under the MIT license. See LICENSE for details.