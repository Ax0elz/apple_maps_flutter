//
//  FlutterCircle.swift
//  apple_maps_flutter
//
//  Created by Luis Thein on 08.03.20.
//

import Foundation
import MapKit

class FlutterCircle: MKCircle {
    var strokeColor: UIColor?
    var fillColor: UIColor?
    var isConsumingTapEvents: Bool?
    var strokeWidth: CGFloat?
    var isVisible: Bool?
    var id: String?
    var zIndex: Int? = -1
    var circleRadius: Double?
    
    convenience init(fromDictionaray circleData: Dictionary<String, Any>) {
        // Safely extract center coordinates
        guard let centerArray = circleData["center"] as? NSArray,
              centerArray.count >= 2,
              let latitude = centerArray[0] as? CLLocationDegrees,
              let longitude = centerArray[1] as? CLLocationDegrees,
              latitude >= -90 && latitude <= 90,
              longitude >= -180 && longitude <= 180 else {
            // Initialize with default values if center is invalid
            self.init(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), radius: 10)
            self.circleRadius = 10
            self.id = circleData["circleId"] as? String
            return
        }

        let centerCoordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let radius = circleData["radius"] as? Double ?? 10
        self.init(center: centerCoordinates, radius: radius)
        self.circleRadius = radius

        // Safely extract colors
        if let strokeColorData = circleData["strokeColor"] as? NSNumber {
            self.strokeColor = JsonConversions.convertColor(data: strokeColorData)
        }
        if let fillColorData = circleData["fillColor"] as? NSNumber {
            self.fillColor = JsonConversions.convertColor(data: fillColorData)
        }

        self.isConsumingTapEvents = circleData["consumeTapEvents"] as? Bool
        self.strokeWidth = circleData["strokeWidth"] as? CGFloat
        self.id = circleData["circleId"] as? String
        self.isVisible = circleData["visible"] as? Bool
        self.zIndex = circleData["zIndex"] as? Int
    }
    
    static func == (lhs: FlutterCircle, rhs: FlutterCircle) -> Bool {
        return lhs.strokeColor == rhs.strokeColor &&
               lhs.fillColor == rhs.fillColor &&
               lhs.isConsumingTapEvents == rhs.isConsumingTapEvents &&
               lhs.strokeWidth == rhs.strokeWidth &&
               lhs.isVisible == rhs.isVisible &&
               lhs.zIndex == rhs.zIndex &&
               lhs.id == rhs.id &&
               lhs.circleRadius == rhs.circleRadius
    }
    
    static func != (lhs: FlutterCircle, rhs: FlutterCircle) -> Bool {
        return !(lhs == rhs)
    }
}

extension FlutterCircle: FlutterOverlay {
    func getCAShapeLayer(snapshot: MKMapSnapshotter.Snapshot) -> CAShapeLayer {
        let shapeLayer = CAShapeLayer()

        if !(self.isVisible ?? true) {
            return shapeLayer
        }

        // Safely handle circle radius for overlay rendering
        guard let circleRadius = self.circleRadius else {
            return shapeLayer
        }

        let centerPoint = snapshot.point(for: self.coordinate)

        // Calculate the radius in screen points using the snapshot
        let offsetPoint = snapshot.point(for: Utils.coordinateWithLatitudeOffset(coordinate: self.coordinate, meters: circleRadius))

        let radius = abs(centerPoint.y - offsetPoint.y)

        let circlePath = UIBezierPath(arcCenter: centerPoint, radius: radius, startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)

        shapeLayer.path = circlePath.cgPath
        shapeLayer.lineWidth = self.strokeWidth ?? 0
        shapeLayer.strokeColor = self.strokeColor?.cgColor ?? UIColor.clear.cgColor
        shapeLayer.fillColor = self.fillColor?.cgColor ?? UIColor.clear.cgColor

        return shapeLayer
    }
}


public extension MKCircle {
    func contains(coordinate: CLLocationCoordinate2D) -> Bool {
        let circleRenderer = MKCircleRenderer(circle: self)
        let currentMapPoint: MKMapPoint = MKMapPoint(coordinate)
        let circleViewPoint: CGPoint = circleRenderer.point(for: currentMapPoint)
        if circleRenderer.path == nil {
          return false
        } else{
            return circleRenderer.path.contains(circleViewPoint)
        }
    }
}
