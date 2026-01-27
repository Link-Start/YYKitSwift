# YYKitSwift Image 模块实现计划

## 任务概述

实现 YYKitSwift 的 Image 图片系统，这是 P1 优先级的核心模块。该模块提供图片加载、缓存、动画显示等功能，支持 GIF、PNG、JPEG、WebP、APNG 等格式。

**项目位置**: `/Users/link/Desktop/XiaoYueYun`
**实现语言**: Swift 6
**最低支持**: iOS 13.0
**完整功能**: 100% YYKit Image 模块功能对等

## 模块架构

```
Image/
├── Core/                                  # 核心图片类
│   ├── LSImage.swift                     # 图片基类 (YYImage → LSImage)
│   ├── LSImageFrame.swift                # 帧数据类
│   ├── LSAnimatedImageView.swift         # 动画图片视图
│   ├── LSFrameImage.swift                # 帧动画图片
│   └── LSSpriteSheetImage.swift          # 精灵图
├── Coder/                                 # 编解码器
│   └── LSImageCoder.swift                # 图片编解码 (YYImageCoder → LSImageCoder)
│                                         # 包含: 枚举类型, LSImageDecoder, LSImageEncoder
├── Cache/                                 # 缓存
│   ├── LSImageCache.swift                # 图片缓存 (YYImageCache → LSImageCache)
│   ├── LSImageCacheKey.swift             # 缓存键生成器
│   ├── LSMemoryCache.swift               # 内存缓存 (LRU 实现)
│   └── LSDiskCache.swift                 # 磁盘缓存 (FileManager + SQLite)
├── WebImage/                              # Web 图片加载
│   ├── LSWebImageManager.swift           # 管理器
│   ├── LSWebImageOperation.swift         # 下载操作
│   └── LSWebImageOptions.swift           # 选项定义
└── Categories/                            # 扩展
    ├── UIImageView+YYKitSwift.swift
    ├── UIButton+YYKitSwift.swift
    ├── CALayer+YYKitSwift.swift
    └── UIImage+YYKitSwift.swift          # 解码扩展
```

## 实现顺序（10 个阶段）

### 阶段 1: 核心类型和枚举 (LSImageCoder.swift)
**状态**: ⏳ 进行中
**文件**: `Image/Coder/LSImageCoder.swift`

**内容**:
- `LSImageType` 枚举（PNG, JPEG, GIF, WebP, APNG 等）
- `LSImageDisposeMethod` 枚举
- `LSImageBlendOperation` 枚举
- `LSImageFrame` 类（帧数据结构）
- 辅助函数（类型检测、颜色空间、CGImage 操作）
- **WebP 支持**: 条件编译，iOS 14+ 使用原生 WebP 框架

---

### 阶段 2: 图片基类 (LSImage.swift)
**状态**: ⏸️ 待开始
**文件**: `Image/Core/LSImage.swift`

---

### 阶段 3: 解码器 (LSImageDecoder)
**状态**: ⏸️ 待开始
**文件**: `Image/Coder/LSImageCoder.swift`（续）

---

### 阶段 4: 编码器 (LSImageEncoder)
**状态**: ⏸️ 待开始
**文件**: `Image/Coder/LSImageCoder.swift`（续）

---

### 阶段 5: 动画图片视图 (LSAnimatedImageView.swift)
**状态**: ⏸️ 待开始
**文件**: `Image/Core/LSAnimatedImageView.swift`

---

### 阶段 6: 帧动画图片 (LSFrameImage.swift)
**状态**: ⏸️ 待开始
**文件**: `Image/Core/LSFrameImage.swift`

---

### 阶段 7: 精灵图图片 (LSSpriteSheetImage.swift)
**状态**: ⏸️ 待开始
**文件**: `Image/Core/LSSpriteSheetImage.swift`

---

### 阶段 8: 图片缓存 (LSImageCache.swift)
**状态**: ⏸️ 待开始
**文件**: `Image/Cache/LSImageCache.swift`

---

### 阶段 9: 网络图片管理器 (LSWebImageManager.swift)
**状态**: ⏸️ 待开始
**文件**: `Image/WebImage/LSWebImageManager.swift`

---

### 阶段 10: 扩展实现 (Categories)
**状态**: ⏸️ 待开始
**文件**: `Image/Categories/*.swift`

---

## 完成状态

- [ ] 阶段 1: 核心类型和枚举 (LSImageCoder.swift)
- [ ] 阶段 2: 图片基类 (LSImage.swift)
- [ ] 阶段 3: 解码器 (LSImageDecoder)
- [ ] 阶段 4: 编码器 (LSImageEncoder)
- [ ] 阶段 5: 动画图片视图 (LSAnimatedImageView.swift)
- [ ] 阶段 6: 帧动画图片 (LSFrameImage.swift)
- [ ] 阶段 7: 精灵图图片 (LSSpriteSheetImage.swift)
- [ ] 阶段 8: 图片缓存 (LSImageCache.swift)
- [ ] 阶段 9: 网络图片管理器 (LSWebImageManager.swift)
- [ ] 阶段 10: 扩展实现 (Categories)

---

**创建日期**: 2026-01-24
**最后更新**: 2026-01-24
**预估时间**: 21-33 天
**优先级**: P1 (最高)
