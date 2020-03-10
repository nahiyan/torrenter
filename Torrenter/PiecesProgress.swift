//
//  PiecesProgress.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 3/8/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Cocoa

class PiecesProgress: NSView {
    var pieces: UnsafeMutablePointer<Bool>?
    var piecesCount: Int
//    var pieces: [Bool] {
//        get {
//            return self._pieces
//        }
//        set {
//            self.needsDisplay = true
//            self._pieces = newValue
//        }
//    }

    override init(frame frameRect: NSRect) {
        piecesCount = 0
        super.init(frame: frameRect)
    }

    required init(coder: NSCoder) {
        piecesCount = 0
        super.init(coder: coder)!
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let context: CGContext = NSGraphicsContext.current!.cgContext

        // Paint the entire view white (as background)
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(dirtyRect)
        
        if pieces != nil {
            let rectWidth: CGFloat = dirtyRect.width / CGFloat(piecesCount)
            var rects: [CGRect] = []

            for n in 0 ..< piecesCount {
                // pieces.append(Int.random(in: 0 ..< 2))

                if pieces![n] {
                    let x: CGFloat = CGFloat(CGFloat(n) * rectWidth)
                    let y: CGFloat = 0.0
                    rects.append(CGRect(x: x, y: y, width: rectWidth, height: dirtyRect.height))
                }
            }
            
            // Paint the rects (representing each piece) blue
            context.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
            context.fill(rects)
        }
        
//        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
//            self.needsDisplay = true
//        }
    }
}
