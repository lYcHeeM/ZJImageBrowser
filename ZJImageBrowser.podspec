
Pod::Spec.new do |s|
  s.name         = "ZJImageBrowser"
  s.version      = “0.0.4”
  s.summary      = "An simple iOS photo browser based on UICollectionView written in Swift."

  s.homepage     = "https://github.com/lYcHeeM/ZJImageBrowser"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"

  s.license    = "MIT"

  s.author             = { "luozhijun" => "luo_zhijun@163.com" }
  # Or just: s.author    = "luozhijun"
  # s.authors            = { "luozhijun" => "luo_zhijun@163.com" }
  # s.social_media_url   = "http://twitter.com/luozhijun"

  s.platform     = :ios, "8.0"

  #  When using multiple platforms
  # s.ios.deployment_target = "8.0"
  # s.osx.deployment_target = "10.10"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"

  s.source       = { :git => "https://github.com/lYcHeeM/ZJImageBrowser.git", :tag => "#{s.version}" }
  s.source_files  = "ZJImageBrowser/ZJImageBrowser/*.swift"
  s.requires_arc = true
  s.frameworks = 'Photos'
  s.resource_bundles = {
    'ZJImageBrowser' => ['Assets/*.png']
  }

  s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  s.dependency "SDWebImage", "~> 3.7.5"

end
