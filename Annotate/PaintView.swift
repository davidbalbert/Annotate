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

struct Path: Identifiable {
    var id = UUID()
    var radius: Double
    var layer: CAShapeLayer
    var path: CGMutablePath

    var lineWidth: Double {
        2*radius
    }

    var origin: CGPoint {
        get {
            CGPoint(x: layer.position.x + radius, y: layer.position.y + radius)
        }

        set {
            layer.position = CGPoint(x: newValue.x-radius, y: newValue.y-radius)
        }
    }

    var size: CGSize {
        get {
            CGSize(width: layer.bounds.width - 2*radius, height: layer.bounds.height - 2*radius)
        }

        set {
            layer.bounds.size = CGSize(width: newValue.width + 2*radius, height: newValue.height + 2*radius)
        }
    }

    init(startingAt point: CGPoint, withRadius radius: Double) {
        self.radius = radius
        layer = CAShapeLayer()
        path = CGMutablePath()
        origin = point
        size = .zero

        setupLayer(withOrigin: point)
        addPoint(point)
    }

    func setupLayer(withOrigin point: CGPoint) {
        layer.anchorPoint = .zero
        layer.fillColor = NSColor.clear.cgColor
        layer.strokeColor = NSColor.red.cgColor
        layer.lineWidth = lineWidth
        layer.lineCap = .round
        layer.lineJoin = .round
        layer.bounds.origin = .zero

        path.move(to: convert(point))
        layer.path = path

        layer.borderColor = CGColor.black
        layer.borderWidth = 1
    }

    mutating func addPoint(_ point: CGPoint) {
        let x = min(origin.x, point.x)
        let y = min(origin.y, point.y)

        let dx = point.x - origin.x
        let dy = point.y - origin.y

        let width = max(size.width + -min(dx, 0), dx)
        let height = max(size.height + -min(dy, 0), dy)

        origin = CGPoint(x: x, y: y)
        size = CGSize(width: width, height: height)

        if dx < 0 || dy < 0 {
            var t = CGAffineTransform(translationX: -min(dx, 0), y: -min(dy, 0))
            guard let p = path.mutableCopy(using: &t) else {
                return
            }

            path = p
        }

        path.addLine(to: convert(point))
        layer.path = path
    }

    func convert(_ point: CGPoint) -> CGPoint {
        return point - layer.position
    }
}

@IBDesignable
class PaintView: NSView {
    var radius = 4.0
    var paths: [UUID: Path] = [:]
    var currentPathId: UUID?

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

        let path = Path(startingAt: p, withRadius: radius)
        CATransaction.withoutAnimations {
            layer?.addSublayer(path.layer)
        }

        paths[path.id] = path
        currentPathId = path.id
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)

        let p = convert(event.locationInWindow, from: nil)

        guard let id = currentPathId else {
            return
        }

        CATransaction.withoutAnimations {
            paths[id]?.addPoint(p)
        }
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)

        guard let id = currentPathId else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4)) {
            guard let layer = self.paths[id]?.layer else {
                return
            }

            CATransaction.begin()
            CATransaction.setAnimationTimingFunction(.init(name: .easeIn))

            CATransaction.setCompletionBlock {
                layer.removeFromSuperlayer()
                self.paths.removeValue(forKey: id)
            }

            layer.strokeStart = 1.0
            CATransaction.commit()
        }

        currentPathId = nil
    }

    @IBAction func clear(_ sender: Any?) {
        CATransaction.withoutAnimations {
            layer?.sublayers = nil
        }
    }
}
