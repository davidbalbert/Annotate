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
    var points: [CGPoint]
    var layer: CAShapeLayer

    var lineWidth: Double {
        2*radius
    }

    var origin: CGPoint {
        layer.position
    }

    var size: CGSize {
        layer.bounds.size
    }

    init(startingAt point: CGPoint, withRadius radius: Double) {
        self.radius = radius
        points = []
        layer = CAShapeLayer()

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

        layer.position = CGPoint(x: point.x-radius, y: point.y-radius)
        layer.bounds = CGRect(x: 0, y: 0, width: 2*radius, height: 2*radius)
    }

    mutating func addPoint(_ point: CGPoint) {
        let paddingAdjusted = CGPoint(x: point.x-radius, y: point.y-radius)

        let x = min(origin.x, paddingAdjusted.x)
        let y = min(origin.y, paddingAdjusted.y)

        let dx = paddingAdjusted.x - origin.x
        let dy = paddingAdjusted.y - origin.y

        let width = max(size.width + -min(dx, 0), dx + 2*radius)
        let height = max(size.height + -min(dy, 0), dy + 2*radius)

        layer.position = CGPoint(x: x, y: y)
        layer.bounds = CGRect(origin: .zero, size: CGSize(width: width, height: height))

        points.append(point)
        layer.path = makePath()
    }

    func makePath() -> CGPath {
        let path = CGMutablePath()

        guard let start = points.first else {
            return path
        }

        path.move(to: convert(start))

        for p in points {
            path.addLine(to: convert(p))
        }

        return path
    }

    func convert(_ point: CGPoint) -> CGPoint {
        return point - origin
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
