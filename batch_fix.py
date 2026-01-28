#!/usr/bin/env python3
import re
import os
import subprocess

def find_files_with_nil_coalescing():
    """查找所有包含 ?? 的 swift 文件"""
    result = subprocess.run(
        ['grep', '-r', '--include=*.swift', '\\?\\?', '.', '--files-with-matches'],
        capture_output=True, text=True, cwd='/Users/link/Desktop/YYKitSwift'
    )
    files = result.stdout.strip().split('\n')
    # 过滤掉不需要处理的文件
    exclude = ['remove_nil_coalescing.py', 'SWIFT6_FIX_PROGRESS.md', 'batch_fix.py', 'fix_nil_coalescing.swift']
    return [f for f in files if f and not any(e in f for e in exclude)]

def fix_nil_coalescing_in_file(filepath):
    """修复单个文件中的 ?? 运算符"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original = content
        changes = 0
        
        # 匹配模式: optional ?? default
        # 使用正则表达式逐步替换
        
        # 模式1: simple_var ?? default (不包括链式调用)
        # let x = optional ?? default
        pattern1 = r'(\w+)\s*\?\?\s*([^,\n\)]+)'
        
        def replace_simple(match):
            nonlocal changes
            var = match.group(1)
            default = match.group(2).strip()
            changes += 1
            # 返回原样，因为这种简单替换需要更多上下文
            return match.group(0)  # 暂时不替换，让更精确的模式处理
        
        # 更精确的模式：在 let/var 声明中
        # let x: Type = optional ?? default
        # 或 let x = optional ?? default
        lines = content.split('\n')
        new_lines = []
        i = 0
        
        while i < len(lines):
            line = lines[i]
            
            # 检查是否有 ??
            if '??' in line:
                # 获取缩进
                indent = len(line) - len(line.lstrip())
                indent_str = ' ' * indent
                
                # 尝试匹配 let/var 声明
                let_match = re.search(r'(let|var)\s+(\w+)\s*[:=]\s*([^?]+)\s*\?\?\s*(.+)', line)
                if let_match:
                    decl_type = let_match.group(1)  # let or var
                    var_name = let_match.group(2)
                    optional_part = let_match.group(3).strip()
                    default_part = let_match.group(4).strip()
                    
                    # 移除行尾可能的注释
                    default_part = re.split(r'//', default_part)[0].strip()
                    
                    changes += 1
                    
                    # 生成 if-else 代码
                    new_lines.append(f"{indent_str}{decl_type} {var_name}")
                    new_lines.append(f"{indent_str}if let tempValue = {optional_part} {{")
                    new_lines.append(f"{indent_str}    {var_name} = tempValue")
                    new_lines.append(f"{indent_str}}} else {{")
                    new_lines.append(f"{indent_str}    {var_name} = {default_part}")
                    new_lines.append(f"{indent_str}}}")
                else:
                    # 尝试匹配函数调用参数中的 ??
                    # function(optional ?? default)
                    arg_match = re.search(r'(\w+)\(([^)]*)\?\?([^)]*)\)', line)
                    if arg_match:
                        # 暂时跳过复杂情况
                        new_lines.append(line)
                    else:
                        # 尝试匹配 return 语句
                        return_match = re.search(r'return\s+(.+?)\s*\?\?\s+(.+)', line)
                        if return_match:
                            optional_part = return_match.group(1).strip()
                            default_part = return_match.group(2).split('//')[0].strip()
                            
                            changes += 1
                            new_lines.append(f"{indent_str}if let tempValue = {optional_part} {{")
                            new_lines.append(f"{indent_str}    return tempValue")
                            new_lines.append(f"{indent_str}}}")
                            new_lines.append(f"{indent_str}return {default_part}")
                        else:
                            # 其他情况，尝试直接替换
                            # 处理形如 optional.property ?? default 的情况
                            prop_match = re.search(r'([\w.]+)\s*\?\?\s*([^,)\n]+)', line)
                            if prop_match:
                                optional_part = prop_match.group(1).strip()
                                default_part = prop_match.group(2).strip()
                                
                                # 检查是否在赋值语句中
                                assign_match = re.search(r'(\w+)\s*=\s*', line[:prop_match.start()])
                                if assign_match:
                                    var_name = assign_match.group(1)
                                    changes += 1
                                    new_lines.append(f"{indent_str}if let tempValue = {optional_part} {{")
                                    new_lines.append(f"{indent_str}    {var_name} = tempValue")
                                    new_lines.append(f"{indent_str}}} else {{")
                                    new_lines.append(f"{indent_str}    {var_name} = {default_part}")
                                    new_lines.append(f"{indent_str}}}")
                                else:
                                    new_lines.append(line)
                            else:
                                new_lines.append(line)
            else:
                new_lines.append(line)
            
            i += 1
        
        new_content = '\n'.join(new_lines)
        
        if changes > 0 and new_content != original:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            return changes
        
        # 如果仍有 ??，尝试更简单的替换
        if '??' in content:
            # 简单替换：text ?? "" -> text ?? ""（转为 if-else）
            # 这个需要非常小心
            pass
        
        return 0
    except Exception as e:
        print(f"Error processing {filepath}: {e}")
        return 0

def main():
    files = find_files_with_nil_coalescing()
    print(f"Found {len(files)} files with ?? operator")
    
    total_changes = 0
    processed = 0
    
    for filepath in files:
        filename = os.path.basename(filepath)
        changes = fix_nil_coalescing_in_file(os.path.join('/Users/link/Desktop/YYKitSwift', filepath))
        if changes > 0:
            print(f"✓ {filename}: {changes} changes")
            total_changes += changes
            processed += 1
        else:
            print(f"  {filename}: no changes")
    
    print(f"\nTotal: {processed} files, {total_changes} changes")

if __name__ == "__main__":
    main()
