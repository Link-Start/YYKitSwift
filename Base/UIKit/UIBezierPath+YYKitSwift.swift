//
//  UIBezierPath+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  UIBezierPath 扩展，提供常见路径创建方法
//

import UIKit

// MARK: - UIBezierPath 扩展

public extension UIBezierPath {

    /// 创建矩形路径
    static func ls_rect(_ rect: CGRect) -> UIBezierPath {
        return UIBezierPath(rect: rect)
    }

    /// 创建圆角矩形路径
    static func ls_roundedRect(_ rect: CGRect, cornerRadius: CGFloat) -> UIBezierPath {
        return UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
    }

    /// 创建指定角的圆角矩形路径
    static func ls_roundedRect(_ rect: CGRect, byRoundingCorners corners: UIRectCorner, cornerRadii: CGSize) -> UIBezierPath {
        return UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: cornerRadii)
    }

    /// 创建椭圆路径
    static func ls_oval(in rect: CGRect) -> UIBezierPath {
        return UIBezierPath(ovalIn: rect)
    }

    /// 创建圆形路径
    static func ls_circle(center: CGPoint, radius: CGFloat) -> UIBezierPath {
        return UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
    }

    /// 创建圆弧路径
    static func ls_arc(center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, clockwise: Bool) -> UIBezierPath {
        return UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)
    }

    /// 创建三角形路径
    static func ls_triangle(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.close()
        return path
    }

    /// 创建星形路径
    static func ls_star(in rect: CGRect, points: Int, innerRadius: CGFloat) -> UIBezierPath {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let angle = .pi * 2 / CGFloat(points)

        let path = UIBezierPath()
        var radius = outerRadius
        var currentAngle: CGFloat = -.pi / 2

        path.move(to: CGPoint(x: center.x + cos(currentAngle) * radius, y: center.y + sin(currentAngle) * radius))

        for _ in 0..<(points * 2) {
            currentAngle += angle
            radius = radius == outerRadius ? innerRadius : outerRadius
            let x = center.x + cos(currentAngle) * radius
            let y = center.y + sin(currentAngle) * radius
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.close()
        return path
    }

    /// 创建心形路径
    static func ls_heart(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width * 0.5, y: height * 0.3))
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.7),
            controlPoint1: CGPoint(x: width * 0.5, y: height * 0.4),
            controlPoint2: CGPoint(x: width * 0.5, y: height * 0.6)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.1, y: height * 0.2),
            controlPoint1: CGPoint(x: width * 0.3, y: height * 0.8),
            controlPoint2: CGPoint(x: width * 0.1, y: height * 0.5)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.3),
            controlPoint1: CGPoint(x: width * 0.1, y: height * 0.05),
            controlPoint2: CGPoint(x: width * 0.25, y: height * 0.05)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.9, y: height * 0.2),
            controlPoint1: CGPoint(x: width * 0.75, y: height * 0.05),
            controlPoint2: CGPoint(x: width * 0.9, y: height * 0.05)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.7),
            controlPoint1: CGPoint(x: width * 0.9, y: height * 0.5),
            controlPoint2: CGPoint(x: width * 0.7, y: height * 0.8)
        )

        return path
    }

    /// 创建箭头路径
    static func ls_arrow(from start: CGPoint, to end: CGPoint, tailWidth: CGFloat, headWidth: CGFloat, headLength: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        let length = hypot(end.x - start.x, end.y - start.y)
        let angle = atan2(end.y - start.y, end.x - start.x)

        let tailLeft = CGPoint(
            x: start.x + cos(angle + .pi / 2) * tailWidth / 2,
            y: start.y + sin(angle + .pi / 2) * tailWidth / 2
        )
        let tailRight = CGPoint(
            x: start.x + cos(angle - .pi / 2) * tailWidth / 2,
            y: start.y + sin(angle - .pi / 2) * tailWidth / 2
        )
        let headLeft = CGPoint(
            x: end.x + cos(angle + .pi / 2) * headWidth / 2,
            y: end.y + sin(angle + .pi / 2) * headWidth / 2
        )
        let headRight = CGPoint(
            x: end.x + cos(angle - .pi / 2) * headWidth / 2,
            y: end.y + sin(angle - .pi / 2) * headWidth / 2
        )

        path.move(to: tailLeft)
        path.addLine(to: CGPoint(
            x: end.x - cos(angle) * headLength,
            y: end.y - sin(angle) * headLength
        ))
        path.addLine(to: headLeft)
        path.addLine(to: end)
        path.addLine(to: headRight)
        path.addLine(to: CGPoint(
            x: end.x - cos(angle) * headLength,
            y: end.y - sin(angle) * headLength
        ))
        path.addLine(to: tailRight)
        path.close()

        return path
    }
}
