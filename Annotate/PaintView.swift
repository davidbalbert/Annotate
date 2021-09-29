//
//  PaintView.swift
//  Annotate
//
//  Created by David Albert on 9/29/21.
//

import Cocoa

import os

@IBDesignable
class PaintView: NSView {
    var radius = 4.0

    var paths: [NSBezierPath] = []
    var lastPoint: NSPoint?

    override var isFlipped: Bool {
        true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor.blue.setFill()
        NSBezierPath(rect: dirtyRect).fill()

        NSColor.red.setStroke()

        for path in paths {
            path.stroke()
        }
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)

        let p = convert(event.locationInWindow, from: nil)

        let path = makeLine(from: p, to: p)
        paths.append(path)
        lastPoint = p

        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)

        let p = convert(event.locationInWindow, from: nil)

        let path = makeLine(from: lastPoint ?? p, to: p)
        paths.append(path)
        lastPoint = p

        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)

        lastPoint = nil
    }

    func makeLine(from start: NSPoint, to end: NSPoint) -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: start)
        path.line(to: end)
        path.lineWidth = 2*radius
        path.lineCapStyle = .round

        return path
    }

    @IBAction func clear(_ sender: Any?) {
        paths = []

        needsDisplay = true
    }
}
