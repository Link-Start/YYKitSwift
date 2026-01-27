# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

YYKitSwift 是 YYKit 的 Swift 6 重写版本，提供 iOS 13+ 支持。项目采用模块化设计，使用 CocoaPods 进行依赖管理。

- **语言**: Swift 6（严格并发模式）
- **最低支持**: iOS 13.0
- **命名空间**: 使用 `.ls` 前缀或 `.ls` 命名空间扩展避免与系统 API 冲突

## 模块架构

```
YYKitSwift/
├── YYKitSwiftCore/     # 核心模块（必须引入）
│   ├── YYKitSwift.swift           # 主入口类
│   ├── YYKitSwiftNamespace.swift  # 泛型包装器命名空间 (.ls)
│   └── LSExtensions.swift         # 扩展注册
├── Model/                # JSON 模型转换 (LSModel 协议)
├── Cache/                # 内存缓存 (LSMemoryCache) 和磁盘缓存 (LSDiskCache)
├── Image/                # 图片加载、解码、缓存、动画
│   ├── Core/             # LSImage, LSAnimatedImageView, LSFrameImage, LSSpriteSheetImage
│   ├── Coder/            # LSImageCoder (支持 GIF/PNG/JPEG/WebP/APNG)
│   ├── Cache/            # LSImageCache (整合内存和磁盘缓存)
│   └── WebImage/         # LSWebImageManager (网络图片加载)
├── Text/                 # 富文本和文本属性 (LSLabel, LSTextView)
├── Base/                 # Foundation/UIKit/Quartz 扩展
└── Utility/              # 通用工具类
```

## 构建和测试

### CocoaPods 集成

```bash
# 安装依赖
pod install

# 构建项目
# 在 Xcode 中打开 .xcworkspace 文件
```

### 使用 CocoaPods 引入模块

```ruby
pod 'YYKitSwift/Core'      # 核心（必须）
pod 'YYKitSwift/Model'     # JSON 模型转换
pod 'YYKitSwift/Cache'     # 缓存
pod 'YYKitSwift/Image'     # 图片
pod 'YYKitSwift/Text'      # 富文本
pod 'YYKitSwift/Base'      # 基础扩展
pod 'YYKitSwift/Utility'   # 工具类
```

## 命名规范

- **类名前缀**: 使用 `LS` 替代原 YYKit 的 `YY`（如 `LSImage` 替代 `YYImage`）
- **命名空间**: 支持两种扩展方式
  1. 传统前缀方式: `button.ls_setContentLayoutStyle(...)`
  2. 命名空间方式: `button.ls.setContentLayoutStyle(...)`
- **协议方法**: 使用 `ls_` 前缀（如 `ls_modelCustomPropertyMapper`）

## 关键设计模式

### 1. LSModel 协议（Model 模块）

提供 JSON 模型转换功能，支持：
- 自定义属性映射（JSON Key → 属性名）
- 容器属性泛型类型映射
- 忽略/白名单属性
- 转换前后验证
- NSCoding 支持

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

### 2. 缓存系统（Cache 模块）

- **LSMemoryCache**: LRU 内存缓存，支持数量、总开销、年龄限制
- **LSDiskCache**: 磁盘缓存，使用 FileManager + SQLite 索引
- **LSCache**: 整合内存和磁盘缓存的两级缓存

### 3. 图片系统（Image 模块）

- **LSImageCoder**: 统一的图片编解码器，支持 GIF/PNG/JPEG/WebP/APNG
- **LSImageDecoder**: 增量解码支持，适用于网络下载
- **LSImageEncoder**: 多帧动画编码（GIF/APNG/WebP）
- **LSImageCache**: 专用图片缓存，整合 LSWebImageManager
- **LSAnimatedImageView**: 高性能动画图片视图

### 4. 命名空间模式（Core 模块）

使用泛型包装器 `YYKitSwift<Base>` 提供类型安全的扩展：

```swift
extension YYKitSwift where Base: UIButton {
    func setContentLayoutStyle(_ style: LSContentLayoutStyle, spacing: CGFloat) { ... }
}

// 使用
button.ls.setContentLayoutStyle(.centerImageTop, spacing: 8)
```

## 并发和线程安全

- 使用 Swift 6 严格并发模式
- 所有缓存类都是线程安全的
- UI 相关类标记 `@MainActor`
- 使用 `NSLock`/`os_unfair_lock` 保护临界区

## 条件编译

- 使用 `#if canImport(UIKit)` 分离 UIKit 相关代码
- 使用 `@available(iOS 14.0, *)` 处理 WebP 等新特性

## 当前实现状态

根据 `Image/IMPLEMENTATION_PLAN.md`，Image 模块实现进度：

- **阶段 1**: 核心类型和枚举 (LSImageCoder.swift) - ⏳ 进行中
- **阶段 2-10**: 待开始

Image 模块是 P1 优先级的核心模块，实现完整的 YYKit Image 功能对等。
