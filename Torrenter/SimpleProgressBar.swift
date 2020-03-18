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
        progress = 0.0
        super.init(frame: frameRect)
    }

    required init(coder: NSCoder) {
        progress = 0.0
        super.init(coder: coder)!
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let context: CGContext = NSGraphicsContext.current!.cgContext

        // Background
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.5))
        context.fill(dirtyRect)

        // Foreground
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.5))
        let foreground: CGRect = CGRect(x: 0, y: 0, width: CGFloat(progress) * dirtyRect.width, height: dirtyRect.height)
        context.fill(foreground)
    }
}
