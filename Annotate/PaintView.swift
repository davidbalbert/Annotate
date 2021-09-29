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

    var image: NSImage
    var lastPoint: NSPoint?

    override init(frame frameRect: NSRect) {
        image = NSImage(size: frameRect.size)

        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        image = NSImage(size: .zero)

        super.init(coder: coder)

        image.size = frame.size
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

        drawLine(from: p, to: p)
        lastPoint = p

        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)

        let p = convert(event.locationInWindow, from: nil)

        drawLine(from: lastPoint ?? p, to: p)
        lastPoint = p

        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        lastPoint = nil
    }

    func drawLine(from start: NSPoint, to end: NSPoint) {
        let path = NSBezierPath()
        path.move(to: start)
        path.line(to: end)
        path.lineWidth = 2*radius
        path.lineCapStyle = .round

        image.lockFocus()
        NSColor.red.setStroke()
        path.stroke()
        image.unlockFocus()
    }

    override func resize(withOldSuperviewSize oldSize: NSSize) {
        super.resize(withOldSuperviewSize: oldSize)

        os_log("resize %s", String(describing: frame))
    }

    @IBAction func clear(_ sender: Any?) {
        image = NSImage(size: frame.size)

        needsDisplay = true
    }
}
