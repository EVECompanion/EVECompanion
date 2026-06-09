//
//  MapScene.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 20.05.26.
//

import Foundation
import EVECompanionKit
import SpriteKit
import UIKit

final class MapScene: SKScene {

    private enum CameraLimits {
        static let minimumScale: CGFloat = 0.15
        static let maximumScale: CGFloat = 5
    }
    
    private enum PanDeceleration {
        static let rate = CGFloat(UIScrollView.DecelerationRate.fast.rawValue)
        static let minimumVelocity: CGFloat = 40
        static let maximumFrameDuration: CGFloat = 1 / 30
    }
    
    private enum HighlightStyle {
        static let systemRadius: CGFloat = 34
        static let regionInset: CGFloat = 40
        static let cornerRadius: CGFloat = 28
        static let lineWidth: CGFloat = 8
        static let strokeColor = UIColor.systemTeal
    }

    private enum SystemStyle {
        static let radius: CGFloat = 20
        static let strokeWidth: CGFloat = 1
        static let strokeColor = UIColor.systemBackground.withAlphaComponent(0.5)
        static let labelFontSize: CGFloat = 10
        static let labelVisibilityPadding: CGFloat = 60
        static let labelVisibilityScale: CGFloat = 1.5
    }
    
    private enum LabelUserDataKey {
        static let systemId = "systemId"
        static let fontSize = "fontSize"
    }

    private enum SecurityBand: Hashable {
        case highSecurity
        case lowSecurity
        case nullSecurity
    }

    private let focusAnimationDuration: TimeInterval = 0.4
    private let gatesLayer = SKNode()
    private let systemsLayer = SKNode()
    private let systemLabelsLayer = SKNode()
    private let regionLabelsLayer = SKNode()
    private let selectionHighlightLayer = SKNode()
    
    private let systems: [Int: ECKSolarSystem]
    private let regions: [String: CGPoint]
    private let gateConnections: [(solarSystemId: Int, destinationSolarSystemId: Int)]
    
    private var minX: CGFloat = 0
    private var minY: CGFloat = 0
    private var maxX: CGFloat = 0
    private var maxY: CGFloat = 0
    private var scale: CGFloat = 0.000000000000015
    var lastPanGestureTranslation: CGPoint = .zero
    let cameraNode = SKCameraNode()
    var lastPinchGestureScale: CGFloat = 1
    private var panDecelerationVelocity: CGPoint?
    private var lastUpdateTime: TimeInterval?
    private var systemNodes: [Int: SKNode] = [:]
    private var systemLabelNodes: [SKLabelNode] = []
    private var systemTextures: [SecurityBand: SKTexture] = [:]
    private var selectionHighlightNode: SKNode?
    
    init(systems: [Int: ECKSolarSystem], regions: [String: CGPoint], gateConnections: [(solarSystemId: Int, destinationSolarSystemId: Int)]) {
        self.systems = systems
        self.regions = regions
        self.gateConnections = gateConnections
        self.minX = CGFloat(systems.values.compactMap(\.position2D?.x).min() ?? 0)
        self.minY = CGFloat(systems.values.compactMap(\.position2D?.y).min() ?? 0)
        self.maxX = CGFloat(systems.values.compactMap(\.position2D?.x).max() ?? 0)
        self.maxY = CGFloat(systems.values.compactMap(\.position2D?.y).max() ?? 0)
        super.init(size: UIScreen.main.bounds.size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        systemLabelsLayer.zPosition += 1
        regionLabelsLayer.zPosition += 1
        selectionHighlightLayer.zPosition = 10
        regionLabelsLayer.isHidden = true
        addChild(gatesLayer)
        addChild(systemsLayer)
        addChild(systemLabelsLayer)
        addChild(regionLabelsLayer)
        addChild(selectionHighlightLayer)
        view.ignoresSiblingOrder = true
        view.shouldCullNonVisibleNodes = true
        view.preferredFramesPerSecond = 60
        backgroundColor = .systemBackground
        scaleMode = .resizeFill
        #if DEBUG
        view.showsFPS = true
        view.showsNodeCount = true
        #endif
        renderSystems()
        renderGates()
        renderRegions()
        let startPosition = CGPoint(
            x: (maxX + minX) / 2,
            y: (maxY + minY) / 2
        )
        cameraNode.position = normalize(coordinate: startPosition)
        cameraNode.setScale(CameraLimits.maximumScale)
        camera = cameraNode
        addChild(cameraNode)
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        view.addGestureRecognizer(panRecognizer)
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture))
        view.addGestureRecognizer(pinchRecognizer)
        updateLabelVisibility()
    }
    
    func renderSystems() {
        for system in systems.values {
            guard let position = system.position2D else {
                continue
            }

            let normalizedX = (CGFloat(position.x) - minX) * scale
            let normalizedY = (CGFloat(position.y) - minY) * scale

            let node = SKSpriteNode(texture: systemTexture(for: system.security))

            node.position = CGPoint(
                x: normalizedX,
                y: normalizedY
            )
            systemsLayer.addChild(node)
            systemNodes[system.id] = node
            
            let label = SKLabelNode(fontNamed: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize).fontName)
            
            label.attributedText = systemLabelText(for: system)
            label.numberOfLines = 2
            label.userData = NSMutableDictionary(dictionary: [
                LabelUserDataKey.systemId: NSNumber(value: system.id),
                LabelUserDataKey.fontSize: NSNumber(value: Double(SystemStyle.labelFontSize))
            ])
            
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            
            label.position = CGPoint(
                x: normalizedX,
                y: normalizedY
            )
            
            systemLabelsLayer.addChild(label)
            systemLabelNodes.append(label)
        }
    }
    
    private func systemLabelText(for system: ECKSolarSystem) -> NSAttributedString {
        systemLabelText(for: system, fontSize: SystemStyle.labelFontSize)
    }
    
    private func systemLabelText(for system: ECKSolarSystem, fontSize: CGFloat) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize),
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraphStyle
        ]
        let securityAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: fontSize),
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraphStyle
        ]
        
        let labelText = NSMutableAttributedString(
            string: system.solarSystemName,
            attributes: nameAttributes
        )
        labelText.append(
            NSAttributedString(
                string: "\n\(ECFormatters.securityStatus(Float(system.security)))",
                attributes: securityAttributes
            )
        )
        
        return labelText
    }
    
    private func visibleRect() -> CGRect? {
        guard let view else {
            return nil
        }
        
        let topLeft = view.convert(CGPoint(x: view.bounds.minX, y: view.bounds.minY), to: self)
        let bottomRight = view.convert(CGPoint(x: view.bounds.maxX, y: view.bounds.maxY), to: self)
        return CGRect(
            x: min(topLeft.x, bottomRight.x),
            y: min(topLeft.y, bottomRight.y),
            width: abs(bottomRight.x - topLeft.x),
            height: abs(bottomRight.y - topLeft.y)
        )
        .insetBy(dx: -SystemStyle.labelVisibilityPadding, dy: -SystemStyle.labelVisibilityPadding)
    }
    
    private func updateSystemLabel(_ label: SKLabelNode, fontSize: CGFloat?, isHidden: Bool) {
        if label.isHidden != isHidden {
            label.isHidden = isHidden
        }
        
        guard let fontSize else {
            return
        }
        
        let currentFontSize = (label.userData?[LabelUserDataKey.fontSize] as? NSNumber)?.doubleValue
        guard currentFontSize != Double(fontSize),
              let systemId = (label.userData?[LabelUserDataKey.systemId] as? NSNumber)?.intValue,
              let system = systems[systemId] else {
            return
        }
        
        label.attributedText = systemLabelText(for: system, fontSize: fontSize)
        label.setScale(SystemStyle.labelFontSize / fontSize)
        label.userData?[LabelUserDataKey.fontSize] = NSNumber(value: Double(fontSize))
    }
    
    private func updateSystemLabels(refreshTextures: Bool) {
        let rect = visibleRect()
        let cameraScale = max(cameraNode.xScale, CameraLimits.minimumScale)
        let visibleFontSize = ceil(SystemStyle.labelFontSize / cameraScale)
        
        for label in systemLabelNodes {
            let isVisible = rect?.contains(label.position) ?? true
            updateSystemLabel(
                label,
                fontSize: refreshTextures ? (isVisible ? visibleFontSize : SystemStyle.labelFontSize) : nil,
                isHidden: !isVisible
            )
        }
    }
    
    private func resetSystemLabels() {
        for label in systemLabelNodes {
            updateSystemLabel(
                label,
                fontSize: SystemStyle.labelFontSize,
                isHidden: false
            )
        }
    }
    
    private func renderGates() {
        let path = CGMutablePath()
        for gateConnection in gateConnections {
            guard let startSystem = systems[gateConnection.solarSystemId],
                  let startPosition = startSystem.position2D,
                  let destinationSystem = systems[gateConnection.destinationSolarSystemId],
                  let destinationPosition = destinationSystem.position2D else {
                continue
            }
            
            path.move(to: normalize(coordinate: startPosition))
            path.addLine(to: normalize(coordinate: destinationPosition))
        }
        
        let lines = SKShapeNode(path: path)
        lines.strokeColor = UIColor.tertiaryLabel
        lines.lineWidth = 1
        lines.alpha = 1
        lines.isAntialiased = false
        gatesLayer.addChild(lines)
    }
    
    func renderRegions() {
        for region in regions {
            let label = SKLabelNode(fontNamed: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize).fontName)
            
            label.text = region.key
            label.fontColor = .label
//            label.fontSize = 12
            
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            
            label.position = normalize(coordinate: region.value)
            
            regionLabelsLayer.addChild(label)
        }
    }
    
    private func normalize(coordinate: CGPoint) -> CGPoint {
        return CGPoint(
            x: (coordinate.x - minX) * scale,
            y: (coordinate.y - minY) * scale
        )
    }
    
    private func normalize(coordinate: SIMD2<Float>) -> CGPoint {
        return CGPoint(
            x: (CGFloat(coordinate.x) - minX) * scale,
            y: (CGFloat(coordinate.y) - minY) * scale
        )
    }
    
    private func normalize(rect: CGRect) -> CGRect {
        CGRect(
            x: (rect.minX - minX) * scale,
            y: (rect.minY - minY) * scale,
            width: rect.width * scale,
            height: rect.height * scale
        )
    }
    
    override func update(_ currentTime: TimeInterval) {
        defer { lastUpdateTime = currentTime }
        
        guard var panDecelerationVelocity,
              let lastUpdateTime else {
            return
        }
        
        let elapsedTime = CGFloat(currentTime - lastUpdateTime)
        guard elapsedTime > 0 else {
            return
        }
        
        let frameDuration = min(elapsedTime, PanDeceleration.maximumFrameDuration)
        let dTranslation = CGPoint(
            x: panDecelerationVelocity.x * frameDuration,
            y: -panDecelerationVelocity.y * frameDuration
        )
        applyPanTranslation(dTranslation, refreshLabelTextures: false)
        
        let deceleration = pow(PanDeceleration.rate, elapsedTime * 1000)
        panDecelerationVelocity = CGPoint(
            x: panDecelerationVelocity.x * deceleration,
            y: panDecelerationVelocity.y * deceleration
        )
        
        if hypot(panDecelerationVelocity.x, panDecelerationVelocity.y) < PanDeceleration.minimumVelocity {
            stopPanDeceleration(refreshLabels: true)
        } else {
            self.panDecelerationVelocity = panDecelerationVelocity
        }
    }
    
    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        guard let view else {
            return
        }
        
        let translationInView = sender.translation(in: view)
        let velocityInView = sender.velocity(in: view)
        
        defer { lastPanGestureTranslation = translationInView }
        
        switch sender.state {
        case .began:
            stopPanDeceleration(refreshLabels: false)
            
        case .changed:
            stopPanDeceleration(refreshLabels: false)
            
            let dTranslation = CGPoint(
                x: translationInView.x - lastPanGestureTranslation.x,
                y: lastPanGestureTranslation.y - translationInView.y
            )
            applyPanTranslation(dTranslation, refreshLabelTextures: false)
            
        case .ended:
            startPanDeceleration(with: velocityInView)
            
        case .cancelled, .failed:
            stopPanDeceleration(refreshLabels: true)
            
        default:
            break
        }
    }
    
    @objc func handlePinchGesture(_ sender: UIPinchGestureRecognizer) {
        guard let view else {
            return
        }
        
        let locationInView = sender.location(in: view)
        let scale = sender.scale
        
        defer { lastPinchGestureScale = scale }
        
        if sender.state == .began || sender.state == .changed {
            stopPanDeceleration(refreshLabels: false)
        }
        
        guard case .changed = sender.state else {
            if sender.state == .ended || sender.state == .cancelled || sender.state == .failed {
                updateLabelVisibility(refreshTextures: true)
            }
            return
        }
        
        let dScale = lastPinchGestureScale - scale
        
        let locationInSceneBeforeScaling = view.convert(locationInView, to: self)
        let nextScale = max(min(cameraNode.xScale + dScale * cameraNode.xScale, CameraLimits.maximumScale), CameraLimits.minimumScale)
        cameraNode.xScale = nextScale
        cameraNode.yScale = nextScale
        let locationInSceneAfterScaling = view.convert(locationInView, to: self)
        
        let offsetInScene = CGPoint(
            x: locationInSceneAfterScaling.x - locationInSceneBeforeScaling.x,
            y: locationInSceneAfterScaling.y - locationInSceneBeforeScaling.y
        )
        
        cameraNode.position = cameraNode.position
            .applying(CGAffineTransform(translationX: -offsetInScene.x, y: -offsetInScene.y))

        updateLabelVisibility(refreshTextures: false)
    }

    func focus(on coordinate: CGPoint, targetScale: CGFloat, animated: Bool = true, completion: (() -> Void)? = nil) {
        stopPanDeceleration(refreshLabels: false)
        
        let normalizedCoordinate = normalize(coordinate: coordinate)
        let clampedScale = max(min(targetScale, CameraLimits.maximumScale), CameraLimits.minimumScale)
        
        if animated {
            let moveAction = SKAction.move(to: normalizedCoordinate, duration: focusAnimationDuration)
            moveAction.timingMode = .easeInEaseOut
            let scaleAction = SKAction.scale(to: clampedScale, duration: focusAnimationDuration)
            scaleAction.timingMode = .easeInEaseOut
            cameraNode.run(.group([moveAction, scaleAction])) { [weak self] in
                self?.updateLabelVisibility(refreshTextures: true)
                completion?()
            }
        } else {
            cameraNode.position = normalizedCoordinate
            cameraNode.setScale(clampedScale)
            updateLabelVisibility(refreshTextures: true)
            completion?()
        }
    }

    func highlightSystem(id: Int) {
        guard let systemNode = systemNodes[id] else {
            clearSelectionHighlight()
            return
        }
        
        clearSelectionHighlight()
        
        let highlightNode = SKShapeNode(circleOfRadius: HighlightStyle.systemRadius)
        highlightNode.position = systemNode.position
        highlightNode.strokeColor = HighlightStyle.strokeColor
        highlightNode.lineWidth = HighlightStyle.lineWidth
        highlightNode.fillColor = .clear
        highlightNode.isAntialiased = true
        
        selectionHighlightLayer.addChild(highlightNode)
        selectionHighlightNode = highlightNode
    }
    
    func highlightRegion(bounds: CGRect) {
        clearSelectionHighlight()
        
        let normalizedBounds = normalize(rect: bounds)
        let highlightRect = normalizedBounds.insetBy(dx: -HighlightStyle.regionInset, dy: -HighlightStyle.regionInset)
        let highlightNode = SKShapeNode(
            rect: highlightRect,
            cornerRadius: HighlightStyle.cornerRadius
        )
        highlightNode.strokeColor = HighlightStyle.strokeColor
        highlightNode.lineWidth = HighlightStyle.lineWidth
        highlightNode.fillColor = .clear
        highlightNode.isAntialiased = true
        
        selectionHighlightLayer.addChild(highlightNode)
        selectionHighlightNode = highlightNode
    }

    func targetScaleToFit(rect: CGRect, padding: CGFloat = 1.4) -> CGFloat {
        let normalizedRect = normalize(rect: rect)
        
        guard size.width > 0, size.height > 0 else {
            return 1
        }
        
        let widthScale = max(normalizedRect.width * padding / size.width, CameraLimits.minimumScale)
        let heightScale = max(normalizedRect.height * padding / size.height, CameraLimits.minimumScale)
        return max(widthScale, heightScale)
    }

    private func updateLabelVisibility(refreshTextures: Bool = true) {
        guard cameraNode.xScale < SystemStyle.labelVisibilityScale else {
            regionLabelsLayer.isHidden = false
            systemLabelsLayer.isHidden = true
            if refreshTextures {
                resetSystemLabels()
            }
            for case let label as SKLabelNode in regionLabelsLayer.children {
                label.setScale(cameraNode.xScale)
            }
            return
        }
        
        regionLabelsLayer.isHidden = true
        systemLabelsLayer.isHidden = false
        updateSystemLabels(refreshTextures: refreshTextures)
    }
    
    private func applyPanTranslation(_ dTranslation: CGPoint, refreshLabelTextures: Bool) {
        let offsetInScene = dTranslation
            .applying(CGAffineTransform(scaleX: cameraNode.xScale, y: cameraNode.yScale))
            .applying(CGAffineTransform(rotationAngle: cameraNode.zRotation))
        
        cameraNode.position = cameraNode.position
            .applying(CGAffineTransform(translationX: -offsetInScene.x, y: -offsetInScene.y))
        
        if cameraNode.xScale < SystemStyle.labelVisibilityScale {
            updateLabelVisibility(refreshTextures: refreshLabelTextures)
        }
    }
    
    private func startPanDeceleration(with velocityInView: CGPoint) {
        guard hypot(velocityInView.x, velocityInView.y) >= PanDeceleration.minimumVelocity else {
            stopPanDeceleration(refreshLabels: true)
            return
        }
        
        panDecelerationVelocity = velocityInView
    }
    
    private func stopPanDeceleration(refreshLabels: Bool) {
        panDecelerationVelocity = nil
        
        if refreshLabels {
            updateLabelVisibility(refreshTextures: true)
        }
    }
    
    private func clearSelectionHighlight() {
        selectionHighlightNode?.removeAllActions()
        selectionHighlightNode?.removeFromParent()
        selectionHighlightNode = nil
    }
    
    private func systemColor(for security: Double) -> UIColor {
        if security >= 0.5 {
            return .lightGray
        } else if security >= 0.1 {
            return .orange
        } else {
            return .red
        }
    }

    private func securityBand(for security: Double) -> SecurityBand {
        if security >= 0.5 {
            return .highSecurity
        } else if security >= 0.1 {
            return .lowSecurity
        } else {
            return .nullSecurity
        }
    }

    private func systemTexture(for security: Double) -> SKTexture {
        let band = securityBand(for: security)
        if let texture = systemTextures[band] {
            return texture
        }

        let diameter = SystemStyle.radius * 2
        let size = CGSize(width: diameter, height: diameter)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            context.cgContext.setAllowsAntialiasing(true)

            let rect = CGRect(origin: .zero, size: size)
                .insetBy(dx: SystemStyle.strokeWidth / 2, dy: SystemStyle.strokeWidth / 2)
            let path = UIBezierPath(ovalIn: rect)

            systemColor(for: security).setFill()
            path.fill()

            SystemStyle.strokeColor.setStroke()
            path.lineWidth = SystemStyle.strokeWidth
            path.stroke()
        }

        let texture = SKTexture(image: image)
        texture.usesMipmaps = true
        systemTextures[band] = texture
        return texture
    }

}
