//
//  PiecesProgress.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 3/8/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Cocoa
// import CoreGraphics

class PiecesProgress: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)!
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let context: CGContext = NSGraphicsContext.current!.cgContext

        var pieces: [Int] = []
        let pieceCount: Int = 300
        let rectWidth: CGFloat = dirtyRect.width / CGFloat(pieceCount)
        var rects: [CGRect] = []
        
        print(rectWidth)
        
        for n in 0 ..< pieceCount {
            pieces.append(Int.random(in: 0 ..< 2))

            if pieces[n] == 1 {
                let x: CGFloat = CGFloat(CGFloat(n) * rectWidth)
                let y: CGFloat = 0.0
                rects.append(CGRect(x: x, y: y, width: rectWidth, height: dirtyRect.height))
            }
        }

        // Paint the entire view white (as background)
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(dirtyRect)

        // Paint the rects (representing each piece) blue
        context.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
        context.fill(rects)

//        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
//            self.needsDisplay = true
//        }
    }
}
