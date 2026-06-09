//
//  MapScene.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 20.05.26.
//

import Foundation
import EVECompanionKit
import SpriteKit

final class MapScene: SKScene {

    private enum CameraLimits {
        static let minimumScale: CGFloat = 0.15
        static let maximumScale: CGFloat = 5
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
    private var systemNodes: [Int: SKShapeNode] = [:]
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
            y: (maxY - minY) / 2
        )
        cameraNode.position = normalize(coordinate: startPosition)
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
            
            let node = SKShapeNode(circleOfRadius: SystemStyle.radius)

            node.position = CGPoint(
                x: normalizedX,
                y: normalizedY
            )
            node.fillColor = systemColor(for: system.security)
            node.strokeColor = SystemStyle.strokeColor
            node.lineWidth = SystemStyle.strokeWidth
            node.isAntialiased = true
            systemsLayer.addChild(node)
            systemNodes[system.id] = node
            
            let label = SKLabelNode(fontNamed: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize).fontName)
            
            label.text = system.solarSystemName
            label.fontColor = .label
            label.fontSize = 12
            
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            
            label.position = CGPoint(
                x: normalizedX,
                y: normalizedY
            )
            
            systemLabelsLayer.addChild(label)
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
    
    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        guard let view else { return }
        
        let locationInView = sender.location(in: view)
        let translationInView = sender.translation(in: view)
        let velocityInView = sender.velocity(in: view)
        
        defer { lastPanGestureTranslation = translationInView }
        
        guard case .changed = sender.state else {
            return
        }
        
        let dTranslation = CGPoint(
            x: translationInView.x - lastPanGestureTranslation.x,
            y: lastPanGestureTranslation.y - translationInView.y
        )
        
        let offsetInScene = dTranslation
            .applying(CGAffineTransform(scaleX: cameraNode.xScale, y: cameraNode.yScale))
            .applying(CGAffineTransform(rotationAngle: cameraNode.zRotation))
        
        cameraNode.position = cameraNode.position
            .applying(CGAffineTransform(translationX: -offsetInScene.x, y: -offsetInScene.y))
    }
    
    @objc func handlePinchGesture(_ sender: UIPinchGestureRecognizer) {
        guard let view else { return }
        
        let locationInView = sender.location(in: view)
        let scale = sender.scale
        let velocityInView = sender.velocity
        
        defer { lastPinchGestureScale = scale }
        
        guard case .changed = sender.state else {
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

        updateLabelVisibility()
    }

    func focus(on coordinate: CGPoint, targetScale: CGFloat, animated: Bool = true, completion: (() -> Void)? = nil) {
        let normalizedCoordinate = normalize(coordinate: coordinate)
        let clampedScale = max(min(targetScale, CameraLimits.maximumScale), CameraLimits.minimumScale)
        
        if animated {
            let moveAction = SKAction.move(to: normalizedCoordinate, duration: focusAnimationDuration)
            moveAction.timingMode = .easeInEaseOut
            let scaleAction = SKAction.scale(to: clampedScale, duration: focusAnimationDuration)
            scaleAction.timingMode = .easeInEaseOut
            cameraNode.run(.group([moveAction, scaleAction])) { [weak self] in
                self?.updateLabelVisibility()
                completion?()
            }
        } else {
            cameraNode.position = normalizedCoordinate
            cameraNode.setScale(clampedScale)
            updateLabelVisibility()
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

    private func updateLabelVisibility() {
        guard cameraNode.xScale < 1.0 else {
            regionLabelsLayer.isHidden = false
            systemLabelsLayer.isHidden = true
            for case let label as SKLabelNode in regionLabelsLayer.children {
                label.setScale(cameraNode.xScale)
            }
            return
        }
        
        regionLabelsLayer.isHidden = true
        systemLabelsLayer.isHidden = false
        for case let label as SKLabelNode in systemLabelsLayer.children {
            label.setScale(cameraNode.xScale)
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
    
}
