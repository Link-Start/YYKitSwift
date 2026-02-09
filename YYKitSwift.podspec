Pod::Spec.new do |s|
  s.name             = 'YYKitSwift'
  s.version          = '2.0.0'
  s.summary          = 'YYKit 的 Swift 6 重写版本，提供 iOS 13+ 支持'
  s.description      = <<-DESC
YYKitSwift 是 YYKit 的 Swift 6 重写版本，提供了完整的 iOS 13+ 支持。

## 功能模块

- **Core**: 核心模块（必须引入）
- **Model**: JSON 模型转换
- **Cache**: 内存缓存和磁盘缓存
- **Image**: 图片加载、解码和缓存
- **Text**: 富文本和文本属性
- **Base**: Foundation、UIKit 和 Quartz 扩展
- **Utility**: 通用工具类

## 特性

- ✅ Swift 6 严格并发模式支持
- ✅ iOS 13+ 最小版本支持
- ✅ 模块化设计，按需引入
- ✅ 完整的类型安全
- ✅ 使用 `.ls` 命名空间避免冲突
                       DESC

  s.homepage         = 'https://github.com/Link-Start/YYKitSwift'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Link-Start' => 'your.email@example.com' }
  s.source           = { :git => 'https://github.com/Link-Start/YYKitSwift.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.swift_version = '6.0'

  # 核心模块（必须引入）
  s.default_subspecs = 'Core'
  s.subspec 'Core' do |core|
    core.source_files = 'YYKitSwiftCore/**/*.swift'
    core.resource_bundles = {'YYKitSwiftCore' => 'YYKitSwiftCore/PrivacyInfo.xcprivacy'}
    core.frameworks = 'Foundation'
  end

  # 模型转换模块
  s.subspec 'Model' do |model|
    model.source_files = 'Model/**/*.swift'
    model.dependency 'YYKitSwift/Core'
    model.frameworks = 'Foundation'
  end

  # 缓存模块
  s.subspec 'Cache' do |cache|
    cache.source_files = 'Cache/**/*.swift'
    cache.dependency 'YYKitSwift/Core'
    cache.frameworks = 'Foundation', 'UIKit'
    cache.libraries = 'sqlite3'
  end

  # 图片模块
  s.subspec 'Image' do |image|
    image.source_files = 'Image/**/*.swift'
    image.dependency 'YYKitSwift/Core'
    image.dependency 'YYKitSwift/Cache'
    image.frameworks = 'Foundation', 'UIKit', 'ImageIO'
    image.libraries = 'sqlite3'
  end

  # 文本模块
  s.subspec 'Text' do |text|
    text.source_files = 'Text/**/*.swift'
    text.dependency 'YYKitSwift/Core'
    text.frameworks = 'Foundation', 'UIKit'
  end

  # 基础扩展模块
  s.subspec 'Base' do |base|
    base.source_files = 'Base/**/*.swift'
    base.dependency 'YYKitSwift/Core'
    base.frameworks = 'Foundation', 'UIKit', 'QuartzCore'
  end

  # 工具模块
  s.subspec 'Utility' do |utility|
    utility.source_files = 'Utility/**/*.swift'
    utility.dependency 'YYKitSwift/Core'
    utility.frameworks = 'Foundation', 'UIKit'
    utility.libraries = 'sqlite3'
  end
end
