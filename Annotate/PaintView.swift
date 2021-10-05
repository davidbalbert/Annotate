//
//  PaintView.swift
//  Annotate
//
//  Created by David Albert on 9/29/21.
//

import Cocoa

import os

func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

struct Annotation: Identifiable {
    var id = UUID()
    var layers: [CALayer] = []
}

@IBDesignable
class PaintView: NSView {
    var radius = 4.0
    var lastPoint: NSPoint?
    var currentAnnotationId: UUID?
    var annotations: [UUID: Annotation] = [:]

    override var isFlipped: Bool {
        true
    }

    override var wantsUpdateLayer: Bool {
        true
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        initLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        initLayer()
    }

    func initLayer() {
        let layer = CALayer()
        layer.backgroundColor = NSColor.purple.cgColor
        layer.anchorPoint = .zero

        self.layer = layer
        wantsLayer = true
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)

        let p = convert(event.locationInWindow, from: nil)

        let shapeLayer = layerForLine(from: p, to: p)
        layer?.addSublayer(shapeLayer)
        lastPoint = p

        var a = Annotation()
        a.layers.append(shapeLayer)
        annotations[a.id] = a
        currentAnnotationId = a.id
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)

        let p = convert(event.locationInWindow, from: nil)

        let shapeLayer = layerForLine(from: lastPoint ?? p, to: p)
        layer?.addSublayer(shapeLayer)

        lastPoint = p

        guard let id = currentAnnotationId else {
            return
        }

        annotations[id]?.layers.append(shapeLayer)
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)

        lastPoint = nil

        guard let id = currentAnnotationId else {
            return
        }


        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4)) {
            self.removeAnnotation(id)
        }

        currentAnnotationId = nil
    }

    func removeAnnotation(_ id: UUID) {
        guard let a = annotations[id] else {
            return
        }

        CATransaction.begin()
        CATransaction.setAnimationDuration(1.5)
        for layer in a.layers {
            layer.removeFromSuperlayer()
        }
        CATransaction.commit()

        annotations.removeValue(forKey: a.id)
    }

    func layerForLine(from start: NSPoint, to end: NSPoint) -> CAShapeLayer {
        let lineWidth = 2*radius

        let layer = CAShapeLayer()
        layer.anchorPoint = .zero
        layer.strokeColor = NSColor.red.cgColor
        layer.lineWidth = lineWidth
        layer.lineCap = .round

        let minX = min(start.x, end.x) - radius
        let minY = min(start.y, end.y) - radius
        let origin = CGPoint(x: minX, y: minY)
        layer.position = origin

        let width = lineWidth+abs(end.x-start.x)
        let height = lineWidth+abs(end.y-start.y)

        layer.bounds = CGRect(origin: .zero, size: CGSize(width: width, height: height))

        let path = CGMutablePath()
        path.move(to: start - origin)
        path.addLine(to: end - origin)
        layer.path = path

        return layer
    }

    @IBAction func clear(_ sender: Any?) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer?.sublayers = nil
        CATransaction.commit()

        annotations = [:]
    }
}
