//
//  MapScene.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 20.05.26.
//

import Foundation
import EVECompanionKit
import Kingfisher
import SpriteKit
import UIKit

final class MapScene: SKScene {

    private enum CameraLimits {
        static let minimumScale: CGFloat = 0.15
        static let maximumScale: CGFloat = 10
    }
    
    private enum PanDeceleration {
        static let rate = CGFloat(UIScrollView.DecelerationRate.fast.rawValue)
        static let minimumVelocity: CGFloat = 40
        static let maximumFrameDuration: CGFloat = 1 / 30
    }
    
    private enum HighlightStyle {
        static let systemRadius: CGFloat = 34
        static let rangeSystemRadius: CGFloat = 30
        static let replacementSystemRadius: CGFloat = 42
        static let constellationInset: CGFloat = 40
        static let regionInset: CGFloat = 40
        static let cornerRadius: CGFloat = 28
        static let lineWidth: CGFloat = 8
        static let rangeLineWidth: CGFloat = 4
        static let replacementLineWidth: CGFloat = 6
        static let strokeColor = UIColor.systemTeal
        static let rangeStrokeColor = UIColor.systemOrange
        static let rangeFillColor = UIColor.systemOrange.withAlphaComponent(0.12)
        static let replacementStrokeColor = UIColor.systemRed
        static let replacementFillColor = UIColor.systemRed.withAlphaComponent(0.12)
    }

    private enum JumpRouteStyle {
        static let lineWidth: CGFloat = 7
        static let destinationRadius: CGFloat = 36
        static let destinationLineWidth: CGFloat = 5
        static let strokeColor = UIColor.systemBlue
        static let fillColor = UIColor.systemBlue.withAlphaComponent(0.12)
        static let alpha: CGFloat = 0.85
    }
    
    enum MapAreaHighlightInset {
        static let constellation = HighlightStyle.constellationInset
        static let region = HighlightStyle.regionInset
    }

    private enum SystemStyle {
        static let radius: CGFloat = 20
        static let strokeWidth: CGFloat = 1
        static let strokeColor = UIColor.systemBackground.withAlphaComponent(0.5)
        static let labelFontSize: CGFloat = 10
        static let labelVisibilityPadding: CGFloat = 60
        static let labelFadeScale: CGFloat = 1.5
        static let labelFadeScaleRange: CGFloat = 0.5
    }
    
    private enum ConstellationStyle {
        static let labelFontSize: CGFloat = 12
        static let labelColor = UIColor.secondaryLabel
        static let labelFadeScale: CGFloat = 3.5
        static let labelFadeScaleRange: CGFloat = 0.75
    }
    
    private enum RegionStyle {
        static let labelFontSize: CGFloat = 16
        static let labelColor = UIColor.label
    }
    
    private enum CharacterStyle {
        static let markerRadius: CGFloat = 16
        static let markerStrokeWidth: CGFloat = 3
        static let clusterRadius: CGFloat = 34
        static let moveAnimationDuration: TimeInterval = 0.35
        static let moveActionKey = "characterMarkerMove"
        static let labelFontSize: CGFloat = 10
        static let labelOffset: CGFloat = 22
        static let labelFadeScale: CGFloat = 2
        static let labelFadeScaleRange: CGFloat = 0.75
        static let onlineColor = UIColor.systemGreen
        static let offlineColor = UIColor.systemGray
        static let unknownColor = UIColor.systemBlue
        static let placeholderColor = UIColor.secondarySystemBackground
        static let strokeColor = UIColor.systemBackground.withAlphaComponent(0.9)
    }

    private enum CharacterNodeName {
        static let ring = "ring"
        static let border = "border"
        static let portrait = "portrait"
        static let label = "label"
    }

    private enum NodeName {
        static let gates = "gates"
    }

    private enum LabelUserDataKey {
        static let systemId = "systemId"
        static let fontSize = "fontSize"
    }

    private struct GateConnection: Hashable {
        let lowerSystemId: Int
        let upperSystemId: Int
        
        init(solarSystemId: Int, destinationSolarSystemId: Int) {
            self.lowerSystemId = min(solarSystemId, destinationSolarSystemId)
            self.upperSystemId = max(solarSystemId, destinationSolarSystemId)
        }
    }

    struct CharacterMarker: Identifiable, Hashable {
        let characterId: Int
        let name: String
        let solarSystemId: Int
        let isOnline: Bool?

        var id: Int {
            characterId
        }
    }

    private let focusAnimationDuration: TimeInterval = 0.4
    private let gatesLayer = SKNode()
    private let systemsLayer = SKNode()
    private let systemLabelsLayer = SKNode()
    private let constellationLabelsLayer = SKNode()
    private let regionLabelsLayer = SKNode()
    private let jumpRouteLayer = SKNode()
    private let jumpRouteDestinationLayer = SKNode()
    private let rangeHighlightLayer = SKNode()
    private let replacementHighlightLayer = SKNode()
    private let selectionHighlightLayer = SKNode()
    private let charactersLayer = SKNode()
    private var characterMarkerNodesById: [Int: SKNode] = [:]
    
    private let systems: [Int: ECKSolarSystem]
    private let constellations: [String: CGPoint]
    private let regions: [String: CGPoint]
    private let gateConnections: [(solarSystemId: Int, destinationSolarSystemId: Int)]
    
    private var minX: CGFloat = 0
    private var minY: CGFloat = 0
    private var maxX: CGFloat = 0
    private var maxY: CGFloat = 0
    private var scale: CGFloat = 0.000000000000015
    private var lastPanGestureTranslation: CGPoint = .zero
    private let cameraNode = SKCameraNode()
    private var lastPinchGestureScale: CGFloat = 1
    private var panDecelerationVelocity: CGPoint?
    private var lastUpdateTime: TimeInterval?
    private var systemNodes: [Int: SKNode] = [:]
    private var systemLabelNodes: [SKLabelNode] = []
    private var highSecuritySystemTexture: SKTexture?
    private var lowSecuritySystemTexture: SKTexture?
    private var nullSecuritySystemTexture: SKTexture?
    private var selectionHighlightNode: SKNode?
    private var rangeHighlightSystemIds: Set<Int> = []
    private var replacementHighlightSystemId: Int?
    private var jumpRouteSystemIds: [Int] = []
    var hasSelectionHighlight: Bool {
        selectionHighlightNode?.parent != nil
    }
    var selectionHighlightCount: Int {
        selectionHighlightLayer.children.count
    }
    private var lastLabelCameraScale: CGFloat?
    private var lastLabelCameraPosition: CGPoint?
    private var userInterfaceStyleOverride: UIUserInterfaceStyle?
    var systemSelected: ((Int) -> Void)?
    var isCharacterLayerHidden: Bool {
        charactersLayer.isHidden
    }
    
    init(systems: [Int: ECKSolarSystem], constellations: [String: CGPoint], regions: [String: CGPoint], gateConnections: [(solarSystemId: Int, destinationSolarSystemId: Int)]) {
        self.systems = systems
        self.constellations = constellations
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
        systemLabelsLayer.zPosition = ECKMapLayerZPosition.mapLabels
        systemsLayer.zPosition = ECKMapLayerZPosition.mapSystems
        constellationLabelsLayer.zPosition = ECKMapLayerZPosition.mapLabels
        regionLabelsLayer.zPosition = ECKMapLayerZPosition.mapLabels
        jumpRouteLayer.zPosition = ECKMapLayerZPosition.jumpRoute
        jumpRouteDestinationLayer.zPosition = ECKMapLayerZPosition.jumpRouteDestinations
        rangeHighlightLayer.zPosition = ECKMapLayerZPosition.rangeHighlight
        replacementHighlightLayer.zPosition = ECKMapLayerZPosition.selectionHighlight
        selectionHighlightLayer.zPosition = ECKMapLayerZPosition.selectionHighlight
        charactersLayer.zPosition = ECKMapLayerZPosition.characterMarkers
        constellationLabelsLayer.alpha = 0
        regionLabelsLayer.alpha = 0
        addChild(gatesLayer)
        addChild(systemsLayer)
        addChild(systemLabelsLayer)
        addChild(constellationLabelsLayer)
        addChild(regionLabelsLayer)
        addChild(jumpRouteLayer)
        addChild(jumpRouteDestinationLayer)
        addChild(rangeHighlightLayer)
        addChild(replacementHighlightLayer)
        addChild(charactersLayer)
        addChild(selectionHighlightLayer)
        view.ignoresSiblingOrder = true
        view.shouldCullNonVisibleNodes = true
        view.preferredFramesPerSecond = 60
        backgroundColor = appearanceColor(.systemBackground)
        scaleMode = .resizeFill
        #if DEBUG
        view.showsFPS = true
        view.showsNodeCount = true
        #endif
        renderSystems()
        refreshJumpRoute()
        refreshRangeHighlights()
        refreshReplacementHighlight()
        renderGates()
        renderConstellations()
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
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        tapRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapRecognizer)
        updateLabelVisibility()
    }
    
    func setCharactersVisible(_ isVisible: Bool) {
        charactersLayer.isHidden = isVisible == false
    }

    func updateCharacters(_ markers: [CharacterMarker]) {
        let renderableMarkers = markers.filter { systemNodes[$0.solarSystemId] != nil }
        let activeCharacterIds = Set(renderableMarkers.map(\.characterId))
        let removedCharacterIds = characterMarkerNodesById.keys.filter { activeCharacterIds.contains($0) == false }
        for characterId in removedCharacterIds {
            guard let markerNode = characterMarkerNodesById[characterId] else {
                continue
            }

            markerNode.removeAllActions()
            markerNode.removeFromParent()
            characterMarkerNodesById[characterId] = nil
        }

        let markersBySystem = Dictionary(grouping: renderableMarkers, by: \.solarSystemId)
        for (solarSystemId, systemMarkers) in markersBySystem {
            guard let systemNode = systemNodes[solarSystemId] else {
                continue
            }

            let sortedMarkers = systemMarkers.sorted(using: KeyPathComparator(\.name))
            for (index, marker) in sortedMarkers.enumerated() {
                let targetPosition = characterMarkerPosition(
                    around: systemNode.position,
                    index: index,
                    count: sortedMarkers.count
                )

                if let markerNode = characterMarkerNodesById[marker.characterId] {
                    updateCharacterMarkerNode(markerNode, with: marker)
                    moveCharacterMarkerNode(markerNode, to: targetPosition)
                } else {
                    let markerNode = characterMarkerNode(for: marker)
                    markerNode.position = targetPosition
                    markerNode.setScale(max(cameraNode.xScale, CameraLimits.minimumScale))
                    charactersLayer.addChild(markerNode)
                    characterMarkerNodesById[marker.characterId] = markerNode
                }
            }
        }

        updateCharacterLabelVisibility()
    }

    private func characterMarkerNode(for marker: CharacterMarker) -> SKNode {
        let node = SKNode()
        let markerDiameter = CharacterStyle.markerRadius * 2
        let portraitNode = SKSpriteNode(
            color: appearanceColor(CharacterStyle.placeholderColor),
            size: CGSize(width: markerDiameter, height: markerDiameter)
        )
        portraitNode.name = CharacterNodeName.portrait

        let cropNode = SKCropNode()
        let maskNode = SKShapeNode(circleOfRadius: CharacterStyle.markerRadius)
        maskNode.fillColor = .white
        maskNode.strokeColor = .clear
        cropNode.maskNode = maskNode
        cropNode.addChild(portraitNode)

        let ring = SKShapeNode(circleOfRadius: CharacterStyle.markerRadius + CharacterStyle.markerStrokeWidth / 2)
        ring.fillColor = .clear
        ring.strokeColor = characterMarkerColor(for: marker.isOnline)
        ring.lineWidth = CharacterStyle.markerStrokeWidth
        ring.isAntialiased = true
        ring.name = CharacterNodeName.ring

        let border = SKShapeNode(circleOfRadius: CharacterStyle.markerRadius + CharacterStyle.markerStrokeWidth)
        border.fillColor = .clear
        border.strokeColor = appearanceColor(CharacterStyle.strokeColor)
        border.lineWidth = 1
        border.isAntialiased = true
        border.name = CharacterNodeName.border

        let label = SKLabelNode(fontNamed: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize).fontName)
        label.text = marker.name
        label.fontSize = CharacterStyle.labelFontSize
        label.fontColor = appearanceColor(.label)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .bottom
        label.position = CGPoint(x: 0, y: CharacterStyle.labelOffset)
        label.name = CharacterNodeName.label

        node.addChild(cropNode)
        node.addChild(ring)
        node.addChild(border)
        node.addChild(label)
        loadCharacterPortrait(characterId: marker.characterId, into: portraitNode)
        return node
    }

    private func updateCharacterMarkerNode(_ markerNode: SKNode, with marker: CharacterMarker) {
        if let ring = markerNode.childNode(withName: CharacterNodeName.ring) as? SKShapeNode {
            ring.strokeColor = characterMarkerColor(for: marker.isOnline)
        }

        if let label = markerNode.childNode(withName: CharacterNodeName.label) as? SKLabelNode {
            label.text = marker.name
        }
    }

    private func moveCharacterMarkerNode(_ markerNode: SKNode, to targetPosition: CGPoint) {
        let distance = hypot(markerNode.position.x - targetPosition.x, markerNode.position.y - targetPosition.y)
        guard distance > 0.5 else {
            markerNode.position = targetPosition
            markerNode.removeAction(forKey: CharacterStyle.moveActionKey)
            return
        }

        let action = SKAction.move(to: targetPosition, duration: CharacterStyle.moveAnimationDuration)
        action.timingMode = .easeInEaseOut
        markerNode.run(action, withKey: CharacterStyle.moveActionKey)
    }

    private func loadCharacterPortrait(characterId: Int, into portraitNode: SKSpriteNode) {
        guard let url = URL(string: "https://images.evetech.net/characters/\(characterId)/portrait") else {
            return
        }

        KingfisherManager.shared.retrieveImage(
            with: url,
            options: [.callbackQueue(.mainAsync)]
        ) { [weak portraitNode] result in
            guard let portraitNode,
                  portraitNode.parent != nil,
                  case .success(let value) = result else {
                return
            }

            let texture = SKTexture(image: value.image)
            texture.usesMipmaps = true
            portraitNode.texture = texture
            portraitNode.color = .clear
        }
    }

    private func characterMarkerColor(for isOnline: Bool?) -> UIColor {
        switch isOnline {
        case .some(true):
            return appearanceColor(CharacterStyle.onlineColor)
        case .some(false):
            return appearanceColor(CharacterStyle.offlineColor)
        case .none:
            return appearanceColor(CharacterStyle.unknownColor)
        }
    }

    private func characterMarkerPosition(around point: CGPoint, index: Int, count: Int) -> CGPoint {
        guard count > 1 else {
            return CGPoint(x: point.x, y: point.y - CharacterStyle.clusterRadius)
        }

        let angle = (CGFloat(index) / CGFloat(count)) * .pi * 2 - .pi / 2
        return CGPoint(
            x: point.x + cos(angle) * CharacterStyle.clusterRadius,
            y: point.y + sin(angle) * CharacterStyle.clusterRadius
        )
    }

    private func renderSystems() {
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
            .foregroundColor: appearanceColor(.label),
            .paragraphStyle: paragraphStyle
        ]
        let securityAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: fontSize),
            .foregroundColor: appearanceColor(.label),
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
    
    private func resetSystemLabels(isHidden: Bool = false) {
        for label in systemLabelNodes {
            updateSystemLabel(
                label,
                fontSize: SystemStyle.labelFontSize,
                isHidden: isHidden
            )
        }
    }
    
    private func renderGates() {
        let path = CGMutablePath()
        var renderedConnections = Set<GateConnection>()
        
        for gateConnection in gateConnections {
            let connectionKey = GateConnection(
                solarSystemId: gateConnection.solarSystemId,
                destinationSolarSystemId: gateConnection.destinationSolarSystemId
            )
            guard renderedConnections.insert(connectionKey).inserted else {
                continue
            }
            
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
        lines.name = NodeName.gates
        lines.strokeColor = appearanceColor(.tertiaryLabel)
        lines.lineWidth = 1
        lines.alpha = 1
        lines.isAntialiased = false
        gatesLayer.addChild(lines)
    }
    
    private func renderRegions() {
        for region in regions {
            let label = mapAreaLabel(
                text: region.key,
                position: region.value,
                fontSize: RegionStyle.labelFontSize,
                fontColor: RegionStyle.labelColor
            )
            regionLabelsLayer.addChild(label)
        }
    }
    
    private func renderConstellations() {
        for constellation in constellations {
            let label = mapAreaLabel(
                text: constellation.key,
                position: constellation.value,
                fontSize: ConstellationStyle.labelFontSize,
                fontColor: ConstellationStyle.labelColor
            )
            constellationLabelsLayer.addChild(label)
        }
    }
    
    private func mapAreaLabel(text: String, position: CGPoint, fontSize: CGFloat, fontColor: UIColor) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize).fontName)
        
        label.text = text
        label.fontSize = fontSize
        label.fontColor = appearanceColor(fontColor)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.position = normalize(coordinate: position)
        
        return label
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

        if lastLabelCameraScale != cameraNode.xScale || lastLabelCameraPosition != cameraNode.position {
            updateLabelVisibility(refreshTextures: false)
        }
        
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
        
        switch sender.state {
        case .began:
            lastPanGestureTranslation = translationInView
            stopPanDeceleration(refreshLabels: false)
            
        case .changed:
            stopPanDeceleration(refreshLabels: false)
            
            let dTranslation = CGPoint(
                x: translationInView.x - lastPanGestureTranslation.x,
                y: lastPanGestureTranslation.y - translationInView.y
            )
            applyPanTranslation(dTranslation, refreshLabelTextures: false)
            lastPanGestureTranslation = translationInView
            
        case .ended:
            startPanDeceleration(with: velocityInView)
            lastPanGestureTranslation = .zero
            
        case .cancelled, .failed:
            stopPanDeceleration(refreshLabels: true)
            lastPanGestureTranslation = .zero
            
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

    @objc func handleTapGesture(_ sender: UITapGestureRecognizer) {
        guard let view, sender.state == .ended else {
            return
        }

        let scenePoint = view.convert(sender.location(in: view), to: self)
        guard let systemId = systemId(at: scenePoint) else {
            return
        }

        systemSelected?(systemId)
    }

    private func systemId(at point: CGPoint) -> Int? {
        let tapRadius = max(SystemStyle.radius, 24 * max(cameraNode.xScale, CameraLimits.minimumScale))

        return systemNodes
            .compactMap { systemId, node -> (systemId: Int, distance: CGFloat)? in
                let distance = hypot(node.position.x - point.x, node.position.y - point.y)
                guard distance <= tapRadius else {
                    return nil
                }

                return (systemId, distance)
            }
            .min { lhs, rhs in
                lhs.distance < rhs.distance
            }?
            .systemId
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
            resetSelectionHighlight()
            return
        }
        
        resetSelectionHighlight()
        
        let highlightNode = SKShapeNode(circleOfRadius: HighlightStyle.systemRadius)
        highlightNode.position = systemNode.position
        highlightNode.strokeColor = appearanceColor(HighlightStyle.strokeColor)
        highlightNode.lineWidth = HighlightStyle.lineWidth
        highlightNode.fillColor = .clear
        highlightNode.isAntialiased = true
        
        selectionHighlightLayer.addChild(highlightNode)
        selectionHighlightNode = highlightNode
    }

    func highlightSystems(ids: Set<Int>) {
        rangeHighlightSystemIds = ids
        rangeHighlightLayer.removeAllChildren()

        for id in ids.sorted() {
            guard let systemNode = systemNodes[id] else {
                continue
            }

            let highlightNode = SKShapeNode(circleOfRadius: HighlightStyle.rangeSystemRadius)
            highlightNode.position = systemNode.position
            highlightNode.strokeColor = appearanceColor(HighlightStyle.rangeStrokeColor)
            highlightNode.lineWidth = HighlightStyle.rangeLineWidth
            highlightNode.fillColor = appearanceColor(HighlightStyle.rangeFillColor)
            highlightNode.isAntialiased = true

            rangeHighlightLayer.addChild(highlightNode)
        }
    }

    func drawJumpRoute(systemIds: [Int]) {
        jumpRouteSystemIds = systemIds
        jumpRouteLayer.removeAllChildren()
        jumpRouteDestinationLayer.removeAllChildren()

        let path = CGMutablePath()
        var hasRenderableSegment = false

        for routeSegment in ECKCapitalJumpMapOverlay.routeSegments(systemIds: systemIds) {
            guard let startNode = systemNodes[routeSegment.startSystemId],
                  let destinationNode = systemNodes[routeSegment.destinationSystemId] else {
                continue
            }

            path.move(to: startNode.position)
            path.addLine(to: destinationNode.position)
            hasRenderableSegment = true
        }

        guard hasRenderableSegment else {
            return
        }

        highlightJumpRouteDestinations(systemIds: ECKCapitalJumpMapOverlay.highlightedRouteSystemIds(systemIds: systemIds))

        let routeNode = SKShapeNode(path: path)
        routeNode.strokeColor = appearanceColor(JumpRouteStyle.strokeColor)
        routeNode.lineWidth = JumpRouteStyle.lineWidth
        routeNode.alpha = JumpRouteStyle.alpha
        routeNode.lineCap = .round
        routeNode.lineJoin = .round
        routeNode.isAntialiased = true
        jumpRouteLayer.addChild(routeNode)
    }

    private func highlightJumpRouteDestinations(systemIds: Set<Int>) {
        for id in systemIds.sorted() {
            guard let systemNode = systemNodes[id] else {
                continue
            }

            let highlightNode = SKShapeNode(circleOfRadius: JumpRouteStyle.destinationRadius)
            highlightNode.position = systemNode.position
            highlightNode.strokeColor = appearanceColor(JumpRouteStyle.strokeColor)
            highlightNode.lineWidth = JumpRouteStyle.destinationLineWidth
            highlightNode.fillColor = appearanceColor(JumpRouteStyle.fillColor)
            highlightNode.isAntialiased = true

            jumpRouteDestinationLayer.addChild(highlightNode)
        }
    }

    func highlightReplacementSystem(id: Int?) {
        replacementHighlightSystemId = id
        replacementHighlightLayer.removeAllChildren()

        guard let id,
              let systemNode = systemNodes[id] else {
            return
        }

        let highlightNode = SKShapeNode(circleOfRadius: HighlightStyle.replacementSystemRadius)
        highlightNode.position = systemNode.position
        highlightNode.strokeColor = appearanceColor(HighlightStyle.replacementStrokeColor)
        highlightNode.lineWidth = HighlightStyle.replacementLineWidth
        highlightNode.fillColor = appearanceColor(HighlightStyle.replacementFillColor)
        highlightNode.isAntialiased = true

        replacementHighlightLayer.addChild(highlightNode)
    }
    
    func highlightConstellation(bounds: CGRect) {
        highlightMapArea(bounds: bounds, inset: HighlightStyle.constellationInset)
    }
    
    func highlightRegion(bounds: CGRect) {
        highlightMapArea(bounds: bounds, inset: HighlightStyle.regionInset)
    }
    
    private func highlightMapArea(bounds: CGRect, inset: CGFloat) {
        resetSelectionHighlight()
        
        let normalizedBounds = normalize(rect: bounds)
        let highlightRect = normalizedBounds.insetBy(dx: -inset, dy: -inset)
        let highlightNode = SKShapeNode(
            rect: highlightRect,
            cornerRadius: HighlightStyle.cornerRadius
        )
        highlightNode.strokeColor = appearanceColor(HighlightStyle.strokeColor)
        highlightNode.lineWidth = HighlightStyle.lineWidth
        highlightNode.fillColor = .clear
        highlightNode.isAntialiased = true
        
        selectionHighlightLayer.addChild(highlightNode)
        selectionHighlightNode = highlightNode
    }

    func targetScaleToFit(rect: CGRect, padding: CGFloat = 1.4, inset: CGFloat = 0) -> CGFloat {
        let normalizedRect = normalize(rect: rect)
            .insetBy(dx: -inset, dy: -inset)
        
        guard size.width > 0, size.height > 0 else {
            return 1
        }
        
        let widthScale = max(normalizedRect.width * padding / size.width, CameraLimits.minimumScale)
        let heightScale = max(normalizedRect.height * padding / size.height, CameraLimits.minimumScale)
        return max(widthScale, heightScale)
    }

    private func updateLabelVisibility(refreshTextures: Bool = true) {
        let cameraScale = max(cameraNode.xScale, CameraLimits.minimumScale)
        let regionAlpha = labelFadeAlpha(
            for: cameraScale,
            fadeScale: ConstellationStyle.labelFadeScale,
            fadeScaleRange: ConstellationStyle.labelFadeScaleRange
        )
        let systemAlpha = 1 - labelFadeAlpha(
            for: cameraScale,
            fadeScale: SystemStyle.labelFadeScale,
            fadeScaleRange: SystemStyle.labelFadeScaleRange
        )
        let constellationAlpha = 1 - regionAlpha

        systemLabelsLayer.alpha = systemAlpha
        constellationLabelsLayer.alpha = constellationAlpha
        regionLabelsLayer.alpha = regionAlpha

        for case let label as SKLabelNode in constellationLabelsLayer.children {
            label.setScale(cameraScale)
        }
        
        for case let label as SKLabelNode in regionLabelsLayer.children {
            label.setScale(cameraScale)
        }

        for markerNode in charactersLayer.children {
            markerNode.setScale(cameraScale)
        }
        updateCharacterLabelVisibility()

        if systemAlpha > 0 {
            updateSystemLabels(refreshTextures: refreshTextures)
        } else if refreshTextures {
            resetSystemLabels(isHidden: true)
        }

        lastLabelCameraScale = cameraNode.xScale
        lastLabelCameraPosition = cameraNode.position
    }

    func refreshAppearance(userInterfaceStyle: UIUserInterfaceStyle? = nil) {
        userInterfaceStyleOverride = userInterfaceStyle

        backgroundColor = appearanceColor(.systemBackground)
        invalidateSystemTextures()
        refreshSystems()
        refreshSystemLabels()
        refreshMapAreaLabels()
        refreshGates()
        refreshCharacterMarkers()
        refreshJumpRoute()
        refreshRangeHighlights()
        refreshReplacementHighlight()
        refreshSelectionHighlight()
        updateLabelVisibility(refreshTextures: true)
        view?.setNeedsDisplay()
    }

    private func refreshJumpRoute() {
        let systemIds = jumpRouteSystemIds
        jumpRouteSystemIds = []
        drawJumpRoute(systemIds: systemIds)
    }

    private func refreshRangeHighlights() {
        let systemIds = rangeHighlightSystemIds
        rangeHighlightSystemIds = []
        highlightSystems(ids: systemIds)
    }

    private func refreshReplacementHighlight() {
        let systemId = replacementHighlightSystemId
        replacementHighlightSystemId = nil
        highlightReplacementSystem(id: systemId)
    }

    private func updateCharacterLabelVisibility() {
        let cameraScale = max(cameraNode.xScale, CameraLimits.minimumScale)
        let labelAlpha = 1 - labelFadeAlpha(
            for: cameraScale,
            fadeScale: CharacterStyle.labelFadeScale,
            fadeScaleRange: CharacterStyle.labelFadeScaleRange
        )

        for markerNode in charactersLayer.children {
            for case let label as SKLabelNode in markerNode.children {
                label.alpha = labelAlpha
            }
        }
    }

    private func labelFadeAlpha(for cameraScale: CGFloat, fadeScale: CGFloat, fadeScaleRange: CGFloat) -> CGFloat {
        let halfFadeRange = fadeScaleRange / 2
        let fadeStartScale = fadeScale - halfFadeRange
        let fadeEndScale = fadeScale + halfFadeRange

        guard cameraScale > fadeStartScale else {
            return 0
        }
        guard cameraScale < fadeEndScale else {
            return 1
        }
        
        return (cameraScale - fadeStartScale) / (fadeEndScale - fadeStartScale)
    }
    
    private func applyPanTranslation(_ dTranslation: CGPoint, refreshLabelTextures: Bool) {
        let offsetInScene = dTranslation
            .applying(CGAffineTransform(scaleX: cameraNode.xScale, y: cameraNode.yScale))
            .applying(CGAffineTransform(rotationAngle: cameraNode.zRotation))
        
        cameraNode.position = cameraNode.position
            .applying(CGAffineTransform(translationX: -offsetInScene.x, y: -offsetInScene.y))
        
        if systemLabelsLayer.alpha > 0 {
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
    
    func resetSelectionHighlight() {
        selectionHighlightNode?.removeAllActions()
        selectionHighlightNode?.removeFromParent()
        selectionHighlightNode = nil
    }

    private func invalidateSystemTextures() {
        highSecuritySystemTexture = nil
        lowSecuritySystemTexture = nil
        nullSecuritySystemTexture = nil
    }

    private func refreshSystems() {
        for (systemId, node) in systemNodes {
            guard let system = systems[systemId],
                  let spriteNode = node as? SKSpriteNode else {
                continue
            }

            spriteNode.texture = systemTexture(for: system.security)
        }
    }

    private func refreshSystemLabels() {
        for label in systemLabelNodes {
            guard let systemId = (label.userData?[LabelUserDataKey.systemId] as? NSNumber)?.intValue,
                  let system = systems[systemId] else {
                continue
            }

            let fontSizeNumber = label.userData?[LabelUserDataKey.fontSize] as? NSNumber
            let fontSize = fontSizeNumber.map { CGFloat($0.doubleValue) } ?? SystemStyle.labelFontSize
            label.attributedText = systemLabelText(for: system, fontSize: fontSize)
        }
    }

    private func refreshMapAreaLabels() {
        for case let label as SKLabelNode in constellationLabelsLayer.children {
            label.fontColor = appearanceColor(ConstellationStyle.labelColor)
        }

        for case let label as SKLabelNode in regionLabelsLayer.children {
            label.fontColor = appearanceColor(RegionStyle.labelColor)
        }
    }

    private func refreshGates() {
        for case let gateNode as SKShapeNode in gatesLayer.children where gateNode.name == NodeName.gates {
            gateNode.strokeColor = appearanceColor(.tertiaryLabel)
        }
    }

    private func refreshCharacterMarkers() {
        for markerNode in characterMarkerNodesById.values {
            if let border = markerNode.childNode(withName: CharacterNodeName.border) as? SKShapeNode {
                border.strokeColor = appearanceColor(CharacterStyle.strokeColor)
            }

            if let label = markerNode.childNode(withName: CharacterNodeName.label) as? SKLabelNode {
                label.fontColor = appearanceColor(.label)
            }

            if let cropNode = markerNode.children.compactMap({ $0 as? SKCropNode }).first,
               let portrait = cropNode.children.compactMap({ $0 as? SKSpriteNode }).first,
               portrait.texture == nil {
                portrait.color = appearanceColor(CharacterStyle.placeholderColor)
            }
        }
    }

    private func refreshSelectionHighlight() {
        guard let highlightNode = selectionHighlightNode as? SKShapeNode else {
            return
        }

        highlightNode.strokeColor = appearanceColor(HighlightStyle.strokeColor)
    }
    
    private func systemTexture(for security: Double) -> SKTexture {
        if security >= 0.5 {
            if let texture = highSecuritySystemTexture {
                return texture
            }
            
            let texture = makeSystemTexture(fillColor: .lightGray)
            highSecuritySystemTexture = texture
            return texture
        } else if security >= 0.1 {
            if let texture = lowSecuritySystemTexture {
                return texture
            }
            
            let texture = makeSystemTexture(fillColor: .orange)
            lowSecuritySystemTexture = texture
            return texture
        } else {
            if let texture = nullSecuritySystemTexture {
                return texture
            }
            
            let texture = makeSystemTexture(fillColor: .red)
            nullSecuritySystemTexture = texture
            return texture
        }
    }

    private func appearanceColor(_ color: UIColor) -> UIColor {
        let traitCollection: UITraitCollection
        if let userInterfaceStyleOverride {
            traitCollection = UITraitCollection(userInterfaceStyle: userInterfaceStyleOverride)
        } else {
            traitCollection = view?.traitCollection ?? UITraitCollection.current
        }
        return color.resolvedColor(with: traitCollection)
    }
    
    private func makeSystemTexture(fillColor: UIColor) -> SKTexture {
        let diameter = SystemStyle.radius * 2
        let size = CGSize(width: diameter, height: diameter)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            context.cgContext.setAllowsAntialiasing(true)

            let rect = CGRect(origin: .zero, size: size)
                .insetBy(dx: SystemStyle.strokeWidth / 2, dy: SystemStyle.strokeWidth / 2)
            let path = UIBezierPath(ovalIn: rect)

            appearanceColor(fillColor).setFill()
            path.fill()

            appearanceColor(SystemStyle.strokeColor).setStroke()
            path.lineWidth = SystemStyle.strokeWidth
            path.stroke()
        }

        let texture = SKTexture(image: image)
        texture.usesMipmaps = true
        return texture
    }

}
