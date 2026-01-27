# Swift 6 编码规范

> YYKitSwift 项目必须严格遵守的 Swift 6 编码规范

## 核心规则

### 1. @MainActor 使用规范

所有 UIKit 相关类必须使用 `@MainActor` 标记。

```swift
@MainActor
public class LSButton: UIButton {
    // ...
}
```

### 2. @Sendable 使用规范

跨线程传递的类型必须正确实现 `Sendable`。

```swift
public final class LSThreadSafeArray<Element>: NSObject, @unchecked Sendable {
    // 手动实现线程安全
}
```

### 3. 禁止使用 `??` 运算符

```swift
// ❌ 禁止
let name = user.name ?? "默认值"

// ✅ 正确
let name: String
if let userName = user.name {
    name = userName
} else {
    name = "默认值"
}
```

### 4. 关键字转义

使用 Swift 关键字作为标识符时，必须使用反引号。

```swift
public static func `default`(_ title: String) -> LSAction
var `init`: (() -> Void)?
```

### 5. iOS 版本兼容性

使用 iOS 13.0+ 作为最低版本时，必须正确处理 API 可用性。

```swift
if #available(iOS 15.0, *) {
    // iOS 15+ 代码
}
```

### 6. 并发安全

全局可变状态必须保证并发安全。

```swift
private enum AssociatedObjectKey {
    static var key: UInt8 = 0
}
```

---

完整规范请参考: `~/.claude/SWIFT6_CODING_STANDARDS.md`
