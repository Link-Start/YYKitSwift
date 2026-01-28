#!/usr/bin/env swift
import Foundation

// 获取所有包含 ?? 的 swift 文件
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
task.arguments = ["bash", "-c", "grep -r --include='*.swift' '\\?\\?' /Users/link/Desktop/YYKitSwift --files-with-matches | grep -v remove_nil_coalescing.py | grep -v SWIFT6_FIX_PROGRESS.md | grep -v fix_nil_coalescing.swift"]

let pipe = Pipe()
task.standardOutput = pipe
task.launch()
task.waitUntilExit()

let data = pipe.fileHandleForReading.readDataToEndOfFile()
if let output = String(data: data, encoding: .utf8) {
    let files = output.components(separatedBy: "\n").filter { !$0.isEmpty }
    print("Found \(files.count) files with ?? operator")
    
    for file in files {
        print("Processing: \(URL(fileURLWithPath: file).lastPathComponent)")
    }
}
