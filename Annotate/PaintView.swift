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

extension CATransaction {
    class func withoutAnimations(execute: () -> Void) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        execute()
        CATransaction.commit()
    }
}

struct AutosizingShapeLayerGeometry {
    var layer: CAShapeLayer

    var lineWidth: Double {
        layer.lineWidth
    }

    var radius: Double {
        lineWidth/2.0
    }

    var origin: CGPoint {
        CGPoint(x: layer.position.x + radius, y: layer.position.y + radius)
    }

    var size: CGSize {
        CGSize(width: layer.bounds.width - lineWidth, height: layer.bounds.height - lineWidth)
    }

    func initialFrame(withOrigin point: CGPoint) -> CGRect {
        return CGRect(x: point.x-radius, y: point.y-radius, width: lineWidth, height: lineWidth)
    }

    func frame(afterAdding point: CGPoint) -> CGRect {
        let x = min(origin.x, point.x)
        let y = min(origin.y, point.y)

        let dx = point.x - origin.x
        let dy = point.y - origin.y

        let width = max(size.width - min(dx, 0), dx)
        let height = max(size.height - min(dy, 0), dy)

        return CGRect(x: x-radius, y: y-radius, width: width+lineWidth, height: height+lineWidth)
    }

    func translate(_ path: CGMutablePath, afterAdding point: CGPoint) -> CGMutablePath {
        let dx = point.x - origin.x
        let dy = point.y - origin.y

        if dx >= 0 && dy >= 0 {
            return path
        }

        var transform = CGAffineTransform(translationX: -min(dx, 0), y: -min(dy, 0))
        guard let p = path.mutableCopy(using: &transform) else {
            return path
        }

        return p
    }

    func convert(_ point: CGPoint) -> CGPoint {
        return point - layer.position
    }
}

@IBDesignable
class PaintView: NSView {
    var radius = 4.0

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

        let l = makeLayer(originatingAt: p)
        addPoint(p, to: l)

        CATransaction.withoutAnimations {
            layer?.addSublayer(l)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)

        let p = convert(event.locationInWindow, from: nil)

        guard let l = layer?.sublayers?.last as? CAShapeLayer else {
            return
        }

        CATransaction.withoutAnimations {
            addPoint(p, to: l)
        }
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)

        guard let l = layer?.sublayers?.last as? CAShapeLayer else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4)) {
            CATransaction.begin()
            CATransaction.setAnimationTimingFunction(.init(name: .easeIn))
            CATransaction.setCompletionBlock {
                l.removeFromSuperlayer()
            }

            l.strokeStart = 1.0

            CATransaction.commit()
        }
    }

    func makeLayer(originatingAt point: CGPoint) -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.anchorPoint = .zero
        layer.fillColor = NSColor.clear.cgColor
        layer.strokeColor = NSColor.red.cgColor
        layer.lineWidth = 2*radius
        layer.lineCap = .round
        layer.lineJoin = .round

        let geometry = AutosizingShapeLayerGeometry(layer: layer)
        let frame = geometry.initialFrame(withOrigin: point)
        layer.position = frame.origin
        layer.bounds.size = frame.size

        let path = CGMutablePath()
        path.move(to: geometry.convert(point))
        layer.path = path

        layer.borderColor = CGColor.black
        layer.borderWidth = 1

        return layer
    }

    func addPoint(_ point: CGPoint, to layer: CAShapeLayer) {
        let geometry = AutosizingShapeLayerGeometry(layer: layer)

        guard var path = layer.path?.mutableCopy() else {
            return
        }

        path = geometry.translate(path, afterAdding: point)

        let frame = geometry.frame(afterAdding: point)
        layer.position = frame.origin
        layer.bounds.size = frame.size

        path.addLine(to: geometry.convert(point))

        layer.path = path
    }

    @IBAction func clear(_ sender: Any?) {
        CATransaction.withoutAnimations {
            layer?.sublayers = nil
        }
    }
}
