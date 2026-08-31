import UIKit

/// Role: Nail. CAReplicatorLayer pie. Rotation is CATransform3D on the replicator; nails are sibling CALayers.
@MainActor
final class PieCanvasView: UIView {
    private let replicator = CAReplicatorLayer()
    private let wedge = CAShapeLayer()
    private let paintHost = CALayer()
    private let labelHost = CALayer()
    private let nailHost = CALayer()
    private let peg = CAShapeLayer()
    private var hapticTask: Task<Void, Never>?
    private var isCoasting = false
    private var currentDegrees: Double = 0
    private var lastFace: PieFace?

    var replicatorCount: Int { replicator.instanceCount }
    var nailLayerCount: Int { nailHost.sublayers?.count ?? 0 }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        replicator.instanceColor = TentInk.Canvas.accent.cgColor
        wedge.fillColor = UIColor.clear.cgColor
        wedge.strokeColor = UIColor.clear.cgColor
        wedge.lineWidth = 1
        replicator.addSublayer(wedge)
        layer.addSublayer(replicator)
        layer.addSublayer(paintHost)
        layer.addSublayer(labelHost)
        layer.addSublayer(nailHost)
        peg.fillColor = TentInk.Canvas.ink.cgColor
        layer.addSublayer(peg)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        placeHosts()
        rebuildFromLastFace()
        if !isCoasting {
            applyRotation(currentDegrees, animated: false)
        }
    }

    func apply(_ face: PieFace) {
        lastFace = face
        let count = max(face.liveCount, 0)
        replicator.instanceCount = count
        if count == 0 {
            clearPaint()
            return
        }
        let step = (2 * CGFloat.pi) / CGFloat(count)
        replicator.instanceTransform = CATransform3DMakeRotation(-step, 0, 0, 1)
        replicator.instanceRedOffset = -0.07
        replicator.instanceGreenOffset = -0.05
        replicator.instanceBlueOffset = 0.04
        rebuildFromLastFace()
        if !isCoasting {
            currentDegrees = face.rotationDegrees
            applyRotation(currentDegrees, animated: false)
        }
    }

    func coast(
        _ plan: SpinPlan,
        haptics: Bool,
        reduceMotion: Bool,
        onSeat: @escaping () -> Void
    ) {
        hapticTask?.cancel()
        let landed = SpinPlan.normalize(currentDegrees + plan.clockwiseDegrees)
        if reduceMotion {
            currentDegrees = landed
            applyRotation(landed, animated: false)
            isCoasting = false
            onSeat()
            return
        }
        isCoasting = true
        applyRotation(landed, animated: true, duration: plan.duration)
        hapticTask = Task { @MainActor [weak self] in
            if haptics {
                await Self.pulse(plan)
            } else {
                try? await Task.sleep(nanoseconds: UInt64(plan.duration * 1_000_000_000))
            }
            guard let self, !Task.isCancelled else { return }
            if haptics {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
            self.currentDegrees = landed
            self.isCoasting = false
            onSeat()
        }
    }

    func cancel() {
        hapticTask?.cancel()
        hapticTask = nil
        replicator.removeAllAnimations()
        paintHost.removeAllAnimations()
        labelHost.removeAllAnimations()
        nailHost.removeAllAnimations()
        isCoasting = false
    }

    private func placeHosts() {
        let box = bounds
        replicator.bounds = box
        replicator.position = CGPoint(x: box.midX, y: box.midY)
        wedge.frame = box
        paintHost.bounds = box
        paintHost.position = replicator.position
        labelHost.bounds = box
        labelHost.position = replicator.position
        nailHost.bounds = box
        nailHost.position = replicator.position
        peg.path = pegPath(in: box).cgPath
        peg.frame = box
    }

    private func rebuildFromLastFace() {
        guard let face = lastFace else { return }
        let count = face.liveCount
        if count == 0 || bounds.width <= 1 {
            if count == 0 {
                clearPaint()
            }
            return
        }
        wedge.path = wedgePath(ordinal: 0, count: count, in: bounds).cgPath
        wedge.fillColor = UIColor.clear.cgColor
        wedge.strokeColor = UIColor.clear.cgColor
        rebuildPaintedWedges(face)
        rebuildLabels(face)
        rebuildNails(face)
    }

    private func clearPaint() {
        wedge.path = nil
        paintHost.sublayers = nil
        labelHost.sublayers = nil
        nailHost.sublayers = nil
    }

    private func rebuildPaintedWedges(_ face: PieFace) {
        paintHost.sublayers = nil
        let count = face.liveCount
        for (ordinal, item) in face.wedges.enumerated() {
            let slice = CAShapeLayer()
            slice.fillColor = fill(for: ordinal, nailed: item.nailed).cgColor
            slice.strokeColor = TentInk.Canvas.ink.cgColor
            slice.lineWidth = 1.5
            slice.frame = bounds
            slice.path = wedgePath(ordinal: ordinal, count: count, in: bounds).cgPath
            paintHost.addSublayer(slice)
        }
    }

    private func rebuildLabels(_ face: PieFace) {
        labelHost.sublayers = nil
        let count = face.liveCount
        guard count > 0, bounds.width > 1 else { return }
        let scale = window?.screen.scale ?? 3
        let outer = min(bounds.width, bounds.height) / 2
        let fontSize = max(12, min(22, outer * 0.08))
        let size = CGSize(width: max(72, outer * 0.42), height: max(28, outer * 0.12))
        for (ordinal, item) in face.wedges.enumerated() {
            let text = CATextLayer()
            text.string = item.name
            text.font = UIFont.preferredFont(forTextStyle: .caption1)
            text.fontSize = fontSize
            text.foregroundColor = labelColor(on: fill(for: ordinal, nailed: item.nailed)).cgColor
            text.alignmentMode = .center
            text.contentsScale = scale
            text.truncationMode = .end
            text.bounds = CGRect(origin: .zero, size: size)
            text.position = point(ordinal: ordinal, count: count, radiusRatio: 0.72)
            text.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            labelHost.addSublayer(text)
        }
    }

    private func rebuildNails(_ face: PieFace) {
        nailHost.sublayers = nil
        let count = face.liveCount
        guard count > 0, bounds.width > 1 else { return }
        let outer = min(bounds.width, bounds.height) / 2
        let nailSide = max(12, min(22, outer * 0.06))
        for (ordinal, item) in face.wedges.enumerated() where item.nailed {
            let nail = CALayer()
            nail.backgroundColor = TentInk.Canvas.ink.cgColor
            nail.borderColor = TentInk.Canvas.accent.cgColor
            nail.borderWidth = 1
            nail.bounds = CGRect(x: 0, y: 0, width: nailSide, height: nailSide)
            nail.cornerRadius = 2
            nail.position = point(ordinal: ordinal, count: count, radiusRatio: 0.88)
            nailHost.addSublayer(nail)
        }
    }

    private func point(ordinal: Int, count: Int, radiusRatio: CGFloat) -> CGPoint {
        let box = bounds
        let outer = min(box.width, box.height) / 2
        let radius = outer * radiusRatio
        let step = (2 * Double.pi) / Double(max(count, 1))
        let clockwise = (Double(ordinal) + 0.5) * step
        let ui = -Double.pi / 2 + clockwise
        return CGPoint(
            x: box.midX + CGFloat(cos(ui)) * radius,
            y: box.midY + CGFloat(sin(ui)) * radius
        )
    }

    private func wedgePath(ordinal: Int, count: Int, in box: CGRect) -> UIBezierPath {
        let n = max(count, 1)
        let center = CGPoint(x: box.midX, y: box.midY)
        let outer = min(box.width, box.height) / 2 - 10
        let inner = max(outer * 0.40, 8)
        let step = (2 * CGFloat.pi) / CGFloat(n)
        let start = -CGFloat.pi / 2 + CGFloat(ordinal) * step
        let path = UIBezierPath()
        path.addArc(withCenter: center, radius: outer, startAngle: start, endAngle: start + step, clockwise: true)
        path.addArc(withCenter: center, radius: inner, startAngle: start + step, endAngle: start, clockwise: false)
        path.close()
        return path
    }

    private func pegPath(in box: CGRect) -> UIBezierPath {
        let mid = box.midX
        let top = box.minY + 4
        let path = UIBezierPath()
        path.move(to: CGPoint(x: mid, y: top))
        path.addLine(to: CGPoint(x: mid - 8, y: top + 14))
        path.addLine(to: CGPoint(x: mid + 8, y: top + 14))
        path.close()
        return path
    }

    private func fill(for ordinal: Int, nailed: Bool) -> UIColor {
        let paints = Self.wedgePaints
        var color = paints[ordinal % paints.count]
        if nailed {
            var hue: CGFloat = 0
            var sat: CGFloat = 0
            var bright: CGFloat = 0
            var alpha: CGFloat = 0
            if color.getHue(&hue, saturation: &sat, brightness: &bright, alpha: &alpha) {
                color = UIColor(hue: hue, saturation: sat, brightness: max(0.35, bright * 0.78), alpha: alpha)
            }
        }
        return color
    }

    private func labelColor(on fill: UIColor) -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        fill.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        return luminance > 0.45 ? TentInk.Canvas.background : TentInk.Canvas.ink
    }

    private func applyRotation(_ degrees: Double, animated: Bool, duration: TimeInterval = 0) {
        let radians = -degrees * .pi / 180
        let transform = CATransform3DMakeRotation(radians, 0, 0, 1)
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        if animated {
            CATransaction.setAnimationDuration(duration)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.12, 0.72, 0.18, 1))
        }
        replicator.transform = transform
        paintHost.transform = transform
        labelHost.transform = transform
        nailHost.transform = transform
        CATransaction.commit()
    }

    private static func pulse(_ plan: SpinPlan) async {
        let start = Date()
        var fired: Set<Int> = []
        while !Task.isCancelled {
            let elapsed = Date().timeIntervalSince(start)
            for (index, time) in plan.pulseTimes.enumerated() where elapsed >= time && !fired.contains(index) {
                fired.insert(index)
                let style: UIImpactFeedbackGenerator.FeedbackStyle
                if index < 2 {
                    style = .light
                } else if index < 4 {
                    style = .medium
                } else {
                    style = .heavy
                }
                UIImpactFeedbackGenerator(style: style).impactOccurred()
            }
            if elapsed >= plan.duration { return }
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
    }

    private static let wedgePaints: [UIColor] = [
        UIColor(red: 0.902, green: 0.706, blue: 0.133, alpha: 1),
        UIColor(red: 0.953, green: 0.902, blue: 0.769, alpha: 1),
        UIColor(red: 0.760, green: 0.280, blue: 0.180, alpha: 1),
        UIColor(red: 0.361, green: 0.118, blue: 0.141, alpha: 1),
        UIColor(red: 0.720, green: 0.520, blue: 0.180, alpha: 1),
        UIColor(red: 0.880, green: 0.640, blue: 0.220, alpha: 1)
    ]
}
