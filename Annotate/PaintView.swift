//
//  PaintView.swift
//  Annotate
//
//  Created by David Albert on 9/29/21.
//

import Cocoa

import os

class PaintView: NSView {
    var radius = 2.5

    var image: NSImage!
    var lastPoint: NSPoint?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        image = NSImage(size: frameRect.size)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        image = NSImage(size: frame.size)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor.blue.setFill()
        NSBezierPath(rect: dirtyRect).fill()

        image.draw(in: dirtyRect)
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)

        let p = convert(event.locationInWindow, from: nil)

        drawCircle(centeredAt: p)
        lastPoint = p

        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)

        let p = convert(event.locationInWindow, from: nil)

        if let lastPoint = lastPoint {
            interpolateLine(from: lastPoint, to: p)
        } else {
            drawCircle(centeredAt: p)
        }

        lastPoint = p

        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        lastPoint = nil
    }

    func interpolateLine(from start: NSPoint, to end: NSPoint) {
        var p = start

        if start.x != end.x || start.y != end.y {
            let dir: Double = atan2(end.y - start.y, end.x - start.x)
            var dist = sqrt(pow(end.x - start.x, 2) + pow(end.y - start.y, 2))

            repeat {
                os_log("drawCircle(centeredAt: %s)", String(describing: p))
                drawCircle(centeredAt: p)
                p.x += radius*cos(dir)
                p.y += radius*sin(dir)
                dist -= radius
            } while dist > 0
        }
    }

    func drawCircle(centeredAt point: NSPoint) {
        let origin = NSPoint(x: point.x-radius, y: point.y-radius)

        image.lockFocus()

        NSColor.red.setFill()
        let rect = NSRect(origin: origin, size: CGSize(width: 2*radius, height: 2*radius))
        NSBezierPath.init(ovalIn: rect).fill()

        image.unlockFocus()
    }

    override func resize(withOldSuperviewSize oldSize: NSSize) {
        super.resize(withOldSuperviewSize: oldSize)

        os_log("resize %s", String(describing: frame))
    }
}
