//
//  MapView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 19.05.26.
//

import SwiftUI
import EVECompanionKit
import simd

extension ECKSolarSystem {
    var cgPoint: CGPoint {
        guard let position2D else { return .zero }
        return CGPoint(x: Double(position2D.x), y: Double(position2D.y))
    }
}

//extension CGRect {
//    init(_ from: CGSize) {
//        self.init(origin: .zero, size: from)
//    }
//}
//
//struct MapView: View {
//    
//    @State private var systems: [Int: ECKSolarSystem] = [:]
//    
//    @State private var storedTranslation: CGSize = CGSize(width: 500, height: 500)
//    @GestureState private var translation: CGSize = .zero   // auto-resets to .zero on gesture end
//    @State private var storedScale = 1.0
//    @GestureState private var scale = 1.0
//    
//    var currentScale: CGFloat {
//        storedScale * scale
//    }
//    
//    var currentTranslation: CGSize {
//        CGSize(width: storedTranslation.width + translation.width,
//               height: storedTranslation.height + translation.height)
//    }
//    
//    @State private var stargates: [(solarSystemId: Int, destinationSolarSystemId: Int)] = []
//    
//    @State private var regions: [String: CGPoint] = [:]
//    
//    @State private var images: [Int: Image] = [:]
//    
//    var body: some View {
//        VStack {
//            Text("Map goes here.")
//            Text("Systems loaded: \(systems.count)")
//            Canvas(rendersAsynchronously: true) { context, size in
//                context.scaleBy(x: currentScale, y: currentScale)
//                context.translateBy(x: currentTranslation.width, y: currentTranslation.height)
//                
//                
//                systems.values.forEach { system in
//                    if system.position2D != nil {
//                        let cgPoint = system.cgPoint
//                        let transformed = CGPointApplyAffineTransform(cgPoint, context.transform)
//                        let inset: CGFloat = -50
//                        if CGRectContainsPoint(CGRectInset(CGRect(size), inset, inset), transformed) {
//                            context.fill(
//                                Path.init(ellipseIn:
//                                            CGRect(origin: cgPoint,
//                                                   size: .init(width: 4, height: 4))).applying(CGAffineTransform(translationX: -2, y: -2)),
//                                with: .color(.red)
//                            )
//                            
//                            
//                            
//                            context.opacity = simd_mix(0, 1, currentScale - 4.0)
//                            if context.opacity > 0.0 {
//                                let fontPoint = CGPointApplyAffineTransform(cgPoint, CGAffineTransform(translationX: 0, y: -2))
//                                
//                                // No prerendering
//                                context.draw(Text(system.solarSystemName).font(.system(size: 2)), at: fontPoint)
//                                // Prerendering:
//                                //context.draw(images[system.id]!, at: fontPoint)
//                            }
//                            context.opacity = 1.0
//                        }
//                    }
//                }
//                
//                stargates.forEach { (solarSystemId: Int, destinationSolarSystemId: Int) in
//                    let from = systems[solarSystemId]!.cgPoint
//                    let to = systems[destinationSolarSystemId]!.cgPoint
//                    
//                    let rect = CGRect(
//                        x:      min(from.x, to.x),
//                        y:      min(from.y, to.y),
//                        width:  abs(to.x - from.x),
//                        height: abs(to.y - from.y)
//                    )
//                    let transformed = CGRectApplyAffineTransform(rect, context.transform)
//
//                    if CGRectIntersectsRect(CGRect(size), transformed) {
//                        let path = Path { path in
//                            path.move(to: from)
//                            path.addLine(to: to)
//                        }
//                        context.stroke(path, with: .color(.green), lineWidth: 0.2)
//                    }
//                }
//                
//                regions.forEach { (key: String, value: CGPoint) in
//                    context.opacity = simd_mix(1, 0, currentScale - 4.0)
//                    if context.opacity > 0.0 {
//                        context.draw(Text(key), at: value)
//                    }
//                    context.opacity = 1.0
//                }
//                
//                
//            }
//            .background(.white)
//            .clipShape(Rectangle())
//            .gesture(
//                DragGesture(minimumDistance: 0)
//                    .updating($translation) { value, state, _ in
//                        state.width  = value.translation.width  / storedScale
//                        state.height = value.translation.height / storedScale
//                    }
//                    .onEnded { value in
//                        storedTranslation.width  += value.translation.width  / storedScale
//                        storedTranslation.height += value.translation.height / storedScale
//                    }
//            )
//            .gesture(MagnificationGesture(minimumScaleDelta: 0.01)
//                .updating($scale) { value, state, _ in
//                    state = value
//                }
//                .onEnded { value in
//                    storedScale *= value
//                }
//            )
//            .ignoresSafeArea()
//        }
//
//        .task {
//            let dbSystems = ECKSDEManager.shared.getAllSolarSystems()
//            systems = Dictionary(uniqueKeysWithValues: dbSystems.map { ($0.id, $0) })
//            stargates = ECKSDEManager.shared.getAllGateConnections().filter { $0.solarSystemId < $0.destinationSolarSystemId }
//            /*
//             Only needed when using prerendering.
//            images = systems.mapValues({ system in
//                let renderer = ImageRenderer(content: Text(system.solarSystemName))
//                renderer.scale = 2
//                return Image(decorative: renderer.cgImage!, scale: 10, orientation: .up)
//            })
//             */
//            regions = Dictionary(grouping: dbSystems, by: \.region.name)
//                .mapValues { solarSystems in
//                    let midPoint = solarSystems.reduce(CGPoint()) { partialResult, solarSystem in
//                        partialResult.applying(CGAffineTransform(translationX: solarSystem.cgPoint.x, y: solarSystem.cgPoint.y))
//                    }
//                    return CGPointApplyAffineTransform(midPoint, CGAffineTransform(scaleX: 1.0 / CGFloat(solarSystems.count), y: 1.0 / CGFloat(solarSystems.count)))
//                }
//            
//        }
//    }
//    
//}
//
//
//#Preview {
//    MapView()
//}


import SwiftUI
import EVECompanionKit
import SpriteKit

struct MapView: View {
    
    @State private var systems: [Int: ECKSolarSystem] = [:]
    @State private var gateConnections: [(solarSystemId: Int, destinationSolarSystemId: Int)] = []
    @State private var regions: [String: CGPoint] = [:]
    
    @State private var scene: MapScene?
    
    var body: some View {
        if let scene {
            SpriteView(scene: scene)
                .ignoresSafeArea()
        } else {
            ProgressView()
                .task {
                    gateConnections = ECKSDEManager.shared.getAllGateConnections()
                    let dbSystems = ECKSDEManager.shared.getAllSolarSystems()
                    systems = Dictionary(uniqueKeysWithValues: dbSystems.map { ($0.id, $0) })
                    regions = Dictionary(grouping: dbSystems, by: \.region.name)
                                    .mapValues { solarSystems in
                                        let midPoint = solarSystems.reduce(CGPoint()) { partialResult, solarSystem in
                                            partialResult.applying(CGAffineTransform(translationX: solarSystem.cgPoint.x, y: solarSystem.cgPoint.y))
                                        }
                                        return CGPointApplyAffineTransform(midPoint, CGAffineTransform(scaleX: 1.0 / CGFloat(solarSystems.count), y: 1.0 / CGFloat(solarSystems.count)))
                                    }
                    self.scene = MapScene(systems: systems, regions: regions, gateConnections: gateConnections)
                }
        }
    }
    
}

#Preview {
    MapView()
}
