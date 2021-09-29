//
//  PaintView.swift
//  Annotate
//
//  Created by David Albert on 9/29/21.
//

import Cocoa

import os

class PaintView: NSView {
    var radius = 4.0

    var paths: [NSBezierPath] = []

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

        let path = NSBezierPath()
        path.lineWidth = 2*radius
        path.lineCapStyle = .round
        path.move(to: p)

        paths.append(path)

        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)

        let p = convert(event.locationInWindow, from: nil)

        paths.last?.line(to: p)

        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)

        let p = convert(event.locationInWindow, from: nil)

        paths.last?.line(to: p)

        needsDisplay = true
    }

    override func resize(withOldSuperviewSize oldSize: NSSize) {
        super.resize(withOldSuperviewSize: oldSize)

        os_log("resize %s", String(describing: frame))
    }

    @IBAction func clear(_ sender: Any?) {
        paths = []

        needsDisplay = true
    }
}
