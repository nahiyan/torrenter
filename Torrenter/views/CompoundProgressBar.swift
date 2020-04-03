//
//  PiecesProgress.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 3/8/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Cocoa

class CompoundProgressBar: NSView {
    var pieces: UnsafeMutablePointer<piece_state_t>?
    var piecesCount: Int

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
            var finishedPieces: [CGRect] = []
            var downloadingPieces: [CGRect] = []

            for n in 0 ..< piecesCount {
                let x: CGFloat = CGFloat(CGFloat(n) * rectWidth)
                let y: CGFloat = 0.0

                if pieces![n] == piece_finished {
                    finishedPieces.append(CGRect(x: x, y: y, width: rectWidth, height: dirtyRect.height))
                } else if pieces![n] == piece_downloading {
                    downloadingPieces.append(CGRect(x: x, y: y, width: rectWidth, height: dirtyRect.height))
                }
            }

            // Paint the finished pieces blue
            context.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
            context.fill(finishedPieces)

            // Paint the pieces being downloaded green
            context.setFillColor(CGColor(red: 0, green: 1, blue: 0, alpha: 1))
            context.fill(downloadingPieces)
        }
    }
}
