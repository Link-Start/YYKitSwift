# YYKitSwift

> YYKit 的 Swift 6 重写版本，提供 iOS 13+ 支持

## 说明

本项目是由 **Claude Code** 重写并上传至 Git 的 Swift 6 版本 YYKit。

## 语言支持

- ✅ **纯 Swift 项目** - 完全使用 Swift 6 编写
- ❌ **不支持 Objective-C** - 这是 YYKit 的纯 Swift 重写版本，不兼容 OC

## 特性

- ✅ Swift 6 严格并发模式支持
- ✅ iOS 13+ 最小版本支持
- ✅ 模块化设计，按需引入
- ✅ 完整的类型安全
- ✅ 使用 `.ls` 命名空间避免冲突

## 功能模块

### Core（核心模块）
必须引入的基础模块，提供命名空间和扩展注册功能。

```ruby
pod 'YYKitSwift/Core'
```

### Model
JSON 模型转换，支持自定义属性映射、容器属性泛型类型映射。

```ruby
pod 'YYKitSwift/Model'
```

```swift
class User: NSObject, LSModel {
    var name: String = ""
    var userId: Int = 0

    static func ls_modelCustomPropertyMapper() -> [String: String] {
        ["user_name": "name", "user_id": "userId"]
    }
}

let user = User.ls_model(with: jsonDict) as User?
```

### Cache
内存缓存（LSMemoryCache）和磁盘缓存（LSDiskCache）。

```ruby
pod 'YYKitSwift/Cache'
```

### Image
图片加载、解码、缓存、动画支持。

```ruby
pod 'YYKitSwift/Image'
```

### Text
富文本和文本属性，提供 LSLabel 和 LSTextView。

```ruby
pod 'YYKitSwift/Text'
```

### Base
Foundation、UIKit 和 Quartz 扩展。

```ruby
pod 'YYKitSwift/Base'
```

### Utility
通用工具类。

```ruby
pod 'YYKitSwift/Utility'
```

## 安装

### CocoaPods

在 Podfile 中添加：

```ruby
# 引入完整功能
pod 'YYKitSwift'

# 或按需引入模块
pod 'YYKitSwift/Core'
pod 'YYKitSwift/Model'
pod 'YYKitSwift/Cache'
pod 'YYKitSwift/Image'
pod 'YYKitSwift/Text'
pod 'YYKitSwift/Base'
pod 'YYKitSwift/Utility'
```

然后运行：

```bash
pod install
```

## 系统要求

- iOS 13.0+
- Swift 6.0+
- Xcode 16.0+

## 命名规范

- **类名前缀**: 使用 `LS` 替代原 YYKit 的 `YY`（如 `LSImage` 替代 `YYImage`）
- **命名空间**: 支持两种扩展方式
  1. 传统前缀方式: `button.ls_setContentLayoutStyle(...)`
  2. 命名空间方式: `button.ls.setContentLayoutStyle(...)`

## 开发说明

本项目由 [Claude Code](https://claude.ai/code) 重写并上传至 Git。

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 原始项目

YYKitSwift 是 [YYKit](https://github.com/ibireme/YYKit) 的 Swift 6 重写版本。
