#!/usr/bin/env python3
"""
移除 YYKitSwift 项目中所有 ?? 运算符
使用显式的 if-else 或 guard let 语句替代
"""

import os
import re
import sys

# 需要处理的文件列表
FILES_TO_PROCESS = [
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSToolbar.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSTextField.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSTableView.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSTabBarController.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSTabBar.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSSearchController.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSSearchBar.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSPopoverView.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSPickerView.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSKeyWindow.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSDevice.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSCollectionView.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/UIImage+QRCode.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/UIColor+YYKitSwift.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/UIView+YYKitSwift_Layout.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/UITextField+YYKitSwift.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/UISearchBar+YYKitSwift.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/UIScreen+YYKitSwift.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/UIFont+YYKitSwift.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/UIButton+YYKitSwift.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/UIApplication+YYKitSwift.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSTextView.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSStepper.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSButtonGroup.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSKeyboardManager.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSKeyboardAccessory.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSImageView.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSImagePicker.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSAnimator.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSHapticFeedback.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSPlaceholderView.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSAlertController.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSActionSheet.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSNavigationController.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSTableViewController.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSCollectionViewFlowLayout.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSCollectionViewLayout.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSSheetView.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSSegmentView.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSRatingView.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSChartView.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSPasscodeView.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSBlurEffect.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSCornerRadius.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSContainerView.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSWebView.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSPagingView.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSProgressBar.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSBadge.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSBadgeView.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSActivityIndicatorView.swift",
    "/Users/link/Desktop/YYKitSwift/Base/UIKit/LSLabel.swift",
    "/Users/link/Desktop/YYKitSwift/Base/Quartz/CALayer+YYKitSwift.swift",
    "/Users/link/Desktop/YYKitSwift/Base/Foundation/Date+YYKitSwift.swift",
    "/Users/link/Desktop/YYKitSwift/Base/Foundation/LSApplication.swift",
    "/Users/link/Desktop/YYKitSwift/Base/Foundation/LSNumberFormatter.swift",
    "/Users/link/Desktop/YYKitSwift/Base/Foundation/LSDeviceInfo.swift",
    "/Users/link/Desktop/YYKitSwift/Base/Foundation/LSUserDefaults.swift",
    "/Users/link/Desktop/YYKitSwift/Base/Foundation/LSDebug.swift",
    "/Users/link/Desktop/YYKitSwift/Base/Foundation/LSCalendarExtension.swift",
    "/Users/link/Desktop/YYKitSwift/Base/Foundation/LSAuthorization.swift",
    "/Users/link/Desktop/YYKitSwift/Base/Foundation/LSBinding.swift",
    "/Users/link/Desktop/YYKitSwift/Base/Foundation/LSValidation.swift",
    "/Users/link/Desktop/YYKitSwift/Base/Foundation/LSDecoder.swift",
    "/Users/link/Desktop/YYKitSwift/Base/Foundation/LSHelper.swift",
    "/Users/link/Desktop/YYKitSwift/Base/Foundation/LSFileManager.swift",
    "/Users/link/Desktop/YYKitSwift/Base/Foundation/LSTimer.swift",
    "/Users/link/Desktop/YYKitSwift/Base/Foundation/LSNetworkUtilities.swift",
    "/Users/link/Desktop/YYKitSwift/Base/Foundation/LSPredicate.swift",
    "/Users/link/Desktop/YYKitSwift/Base/Foundation/LSDateExtension.swift",
    "/Users/link/Desktop/YYKitSwift/Base/Foundation/LSCrypto.swift",
    "/Users/link/Desktop/YYKitSwift/Base/Foundation/LSLocationManager.swift",
    "/Users/link/Desktop/YYKitSwift/Base/Foundation/LSAttributedString.swift",
    "/Users/link/Desktop/YYKitSwift/Base/Foundation/String+YYKitSwift.swift",
    "/Users/link/Desktop/YYKitSwift/Text/String/LSTextInput.swift",
    "/Users/link/Desktop/YYKitSwift/Text/Component/LSTextKeyboardManager.swift",
    "/Users/link/Desktop/YYKitSwift/Text/Core/LSTextView.swift",
    "/Users/link/Desktop/YYKitSwift/Text/Core/LSLabel.swift",
    "/Users/link/Desktop/YYKitSwift/Image/Cache/LSImageCache.swift",
    "/Users/link/Desktop/YYKitSwift/Image/Coder/LSImageCoder.swift",
    "/Users/link/Desktop/YYKitSwift/Utility/LSFileHash.swift",
]

def replace_nil_coalescing(content):
    """替换 ?? 运算符为显式的 if-else"""
    changes_made = 0

    lines = content.split('\n')
    result = []

    for line in lines:
        original_line = line
        # 查找所有 ?? 运算符
        while '??' in line:
            # 简单情况: let x = optional ?? default
            # 提取 ?? 前后的内容
            match = re.search(r'(\w+(?:\??\.\w+)*)\s*\?\?\s*(.+)', line)

            if match:
                optional_part = match.group(1).strip()
                default_part = match.group(2).strip()

                # 检查是否是链式调用
                if '?' in optional_part and optional_part.count('?') > 1:
                    # 复杂的链式调用，跳过或使用更复杂的逻辑
                    # 这里我们简化处理，将 ?? 前的部分提取为临时变量
                    temp_var_name = f"tempValue{changes_made}"
                    indent = len(line) - len(line.lstrip())
                    indent_str = ' ' * indent

                    # 在前一行添加临时变量声明
                    result.append(f"{indent_str}let {temp_var_name}: String")
                    result.append(f"{indent_str}if let temp = {optional_part} {{")
                    result.append(f"{indent_str}    {temp_var_name} = temp")
                    result.append(f"{indent_str}}} else {{")
                    result.append(f"{indent_str}    {temp_var_name} = {default_part}")
                    result.append(f"{indent_str}}}")
                    line = line.replace(f"{optional_part} ?? {default_part}", temp_var_name)
                    changes_made += 1
                else:
                    # 简单的 optional ?? default
                    # 尝试提取变量名和类型
                    assign_match = re.search(r'let\s+(\w+)\s*[:=]', line)

                    if assign_match:
                        var_name = assign_match.group(1)
                        temp_var_name = f"temp{var_name.capitalize()}"
                        indent = len(line) - len(line.lstrip())
                        indent_str = ' ' * indent

                        # 替换为 if-else
                        result.append(f"{indent_str}let {var_name}")
                        result.append(f"{indent_str}if let {temp_var_name} = {optional_part} {{")
                        result.append(f"{indent_str}    {var_name} = {temp_var_name}")
                        result.append(f"{indent_str}}} else {{")
                        result.append(f"{indent_str}    {var_name} = {default_part}")
                        result.append(f"{indent_str}}}")
                        line = ""
                        changes_made += 1
                    else:
                        # 无法简单处理，保留原样
                        break
            else:
                # 无法匹配模式，可能是复杂的表达式
                break

        if line or not original_line.strip():
            result.append(line)

    return '\n'.join(result), changes_made

def process_file(filepath):
    """处理单个文件"""
    if not os.path.exists(filepath):
        print(f"文件不存在: {filepath}")
        return 0

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        original_content = content
        new_content, changes = replace_nil_coalescing(content)

        if changes > 0 and new_content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            return changes
        elif '??' in content:
            # 如果仍然有 ?? 运算符，记录但使用更简单的方法
            print(f"  警告: {filepath} 仍有未处理的 ?? 运算符")
            return 0

        return 0
    except Exception as e:
        print(f"处理文件 {filepath} 时出错: {e}")
        return 0

def main():
    print("开始移除 ?? 运算符...")
    print("=" * 60)

    total_changes = 0
    processed_files = 0

    for filepath in FILES_TO_PROCESS:
        print(f"处理: {os.path.basename(filepath)}", end=" ")
        changes = process_file(filepath)
        if changes > 0:
            print(f"✓ ({changes} 处修改)")
            total_changes += changes
            processed_files += 1
        else:
            print("✓ (无修改)")

    print("=" * 60)
    print(f"完成! 共处理 {processed_files} 个文件，进行了 {total_changes} 处修改")

if __name__ == "__main__":
    main()
