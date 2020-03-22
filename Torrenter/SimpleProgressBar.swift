//
//  SimpleProgressBar.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 3/18/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Cocoa

class SimpleProgressBar: NSView {
    var progress: Float

    override init(frame frameRect: NSRect) {
        progress = 0.5
        super.init(frame: frameRect)
    }

    required init(coder: NSCoder) {
        progress = 0.5
        super.init(coder: coder)!
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let context: CGContext = NSGraphicsContext.current!.cgContext

        if let row: NSTableRowView = superview?.superview as? NSTableRowView {
//            if !row.isSelected {
//                // Background
//                context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
//                context.fill(dirtyRect)
//
//                // Foreground
//                context.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
//                let foreground: CGRect = CGRect(x: 0, y: 0, width: CGFloat(progress) * dirtyRect.width, height: dirtyRect.height)
//                context.fill(foreground)
//
//                // Border
//                context.setStrokeColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
//                context.stroke(dirtyRect, width: 2)
//            } else {
//                // Background
//                context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0))
//                context.fill(dirtyRect)
//
//                // Foreground
//                context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
//                let foreground: CGRect = CGRect(x: 0, y: 0, width: CGFloat(progress) * dirtyRect.width, height: dirtyRect.height)
//                context.fill(foreground)
//
//                // Border
//                context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
//                context.stroke(dirtyRect, width: 2)
//            }

            // Background
            context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
            context.fill(dirtyRect)

            // Foreground
            context.setFillColor(CGColor(red: 0, green: 0, blue: 0.8, alpha: 1))
            let foreground: CGRect = CGRect(x: 0, y: 0, width: CGFloat(progress) * dirtyRect.width, height: 3)
            context.fill(foreground)

            // Border
            context.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.5))
            context.stroke(dirtyRect, width: 2)
        }

        // Draw text
        let progressText: NSString = String(format: "%.1f%%", progress * 100) as NSString

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.center
        let attrs = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 12), NSAttributedString.Key.foregroundColor: NSColor(red: 0, green: 0, blue: 0, alpha: 1), NSAttributedString.Key.paragraphStyle: paragraphStyle]
        progressText.draw(in: dirtyRect, withAttributes: attrs)
    }
}
