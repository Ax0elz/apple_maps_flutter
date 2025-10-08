//
//  CircleController.swift
//  apple_maps_flutter
//
//  Created by Luis Thein on 08.03.20.
//

import Foundation
import MapKit

extension AppleMapController: CircleDelegate {
    
    func circleRenderer(overlay: MKOverlay) -> MKOverlayRenderer {
        // Make sure we are rendering a circle.
        guard let circle = overlay as? MKCircle else {
           return MKOverlayRenderer()
        }
        let circleRenderer = MKCircleRenderer(overlay: circle)

        if let flutterCircle: FlutterCircle = overlay as? FlutterCircle {
            if flutterCircle.isVisible ?? true {
                circleRenderer.strokeColor = flutterCircle.strokeColor
                circleRenderer.fillColor = flutterCircle.fillColor
                circleRenderer.lineWidth = flutterCircle.strokeWidth ?? 1.0
            } else {
                circleRenderer.strokeColor = UIColor.clear
                circleRenderer.lineWidth = 0.0
            }
        }
        return circleRenderer
    }

    func addCircles(circleData data: NSArray) {
        for _circle in data {
            guard let circleData = _circle as? Dictionary<String, Any> else {
                continue
            }
            let circle = FlutterCircle(fromDictionaray: circleData)
            addCircle(circle: circle)
        }
    }
    
    private func addCircle(circle: FlutterCircle) {
        if circle.zIndex == nil || circle.zIndex == -1 {
            self.mapView.addOverlay(circle)
        } else if let zIndex = circle.zIndex {
            self.mapView.insertOverlay(circle, at: zIndex)
        } else {
            self.mapView.addOverlay(circle)
        }
    }

    func changeCircles(circleData data: NSArray) {
        let oldOverlays: [MKOverlay] = self.mapView.overlays
        for oldOverlay in oldOverlays {
            guard let oldFlutterCircle = oldOverlay as? FlutterCircle else {
                continue
            }

            for _circle in data {
                guard let circleData = _circle as? Dictionary<String, Any>,
                      let circleId = circleData["circleId"] as? String,
                      oldFlutterCircle.id == circleId else {
                    continue
                }

                let newCircle = FlutterCircle.init(fromDictionaray: circleData)
                if oldFlutterCircle != newCircle {
                    updateCirclesOnMap(oldCircle: oldFlutterCircle, newCircle: newCircle)
                }
            }
        }
    }

    func removeCircles(circleIds: NSArray) {
        for overlay in self.mapView.overlays {
            if let circle = overlay as? FlutterCircle, let circleId = circle.id {
                if circleIds.contains(circleId) {
                    self.mapView.removeOverlay(circle)
                }
            }
        }
    }
    
    func removeAllCircles() {
        for overlay in self.mapView.overlays {
            if let circle = overlay as? FlutterCircle {
                self.mapView.removeOverlay(circle)
            }
        }
    }
    
    private func updateCirclesOnMap(oldCircle: FlutterCircle, newCircle: FlutterCircle) {
        self.mapView.removeOverlay(oldCircle)
        addCircle(circle: newCircle)
    }
}

