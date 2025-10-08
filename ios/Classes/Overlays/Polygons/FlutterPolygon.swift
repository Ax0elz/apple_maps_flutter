//
//  FlutterPolygon.swift
//  apple_maps_flutter
//
//  Created by Luis Thein on 07.03.20.
//

import Foundation
import MapKit

class FlutterPolygon: MKPolygon {
    var strokeColor: UIColor?
    var fillColor: UIColor?
    var isConsumingTapEvents: Bool?
    var width: CGFloat?
    var isVisible: Bool?
    var id: String?
    var zIndex: Int? = -1
    var coordinates: [CLLocationCoordinate2D]?
    
    convenience init(fromDictionaray polygonData: Dictionary<String, Any>) {
        // Safely extract points array
        guard let points = polygonData["points"] as? NSArray,
              points.count > 0 else {
            // Initialize with empty coordinates if no valid points provided
            self.init(coordinates: [], count: 0)
            self.coordinates = []
            self.id = polygonData["polygonId"] as? String
            return
        }

        var _points: [CLLocationCoordinate2D] = []
        for point in points {
            guard let _point = point as? NSArray,
                  _point.count >= 2,
                  let latitude = _point[0] as? CLLocationDegrees,
                  let longitude = _point[1] as? CLLocationDegrees,
                  latitude >= -90 && latitude <= 90,
                  longitude >= -180 && longitude <= 180 else {
                continue
            }
            _points.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        }

        self.init(coordinates: _points, count: _points.count)
        self.coordinates = _points

        // Safely extract colors with fallbacks
        if let strokeColorData = polygonData["strokeColor"] as? NSNumber {
            self.strokeColor = JsonConversions.convertColor(data: strokeColorData)
        }
        if let fillColorData = polygonData["fillColor"] as? NSNumber {
            self.fillColor = JsonConversions.convertColor(data: fillColorData)
        }

        self.isConsumingTapEvents = polygonData["consumeTapEvents"] as? Bool
        self.width = polygonData["strokeWidth"] as? CGFloat
        self.id = polygonData["polygonId"] as? String
        self.isVisible = polygonData["visible"] as? Bool
        self.zIndex = polygonData["zIndex"] as? Int
    }
    
    static func == (lhs: FlutterPolygon, rhs: FlutterPolygon) -> Bool {
        return lhs.strokeColor == rhs.strokeColor &&
               lhs.fillColor == rhs.fillColor &&
               lhs.isConsumingTapEvents == rhs.isConsumingTapEvents &&
               lhs.width == rhs.width &&
               lhs.isVisible == rhs.isVisible &&
               lhs.zIndex == rhs.zIndex &&
               lhs.id == rhs.id
    }
    
    static func != (lhs: FlutterPolygon, rhs: FlutterPolygon) -> Bool {
        return !(lhs == rhs)
    }
}

extension FlutterPolygon: FlutterOverlay {
    func getCAShapeLayer(snapshot: MKMapSnapshotter.Snapshot) -> CAShapeLayer {
        let path = UIBezierPath()
        let shapeLayer = CAShapeLayer()
        
        if !(self.isVisible ?? true) {
            return shapeLayer
        }
            

        // Safely handle coordinates for overlay rendering
        guard let coordinates = self.coordinates, !coordinates.isEmpty else {
            return shapeLayer
        }

        // Thus we use snapshot.point() to save the pain.
        path.move(to: snapshot.point(for: coordinates[0]))
        for coordinate in coordinates {
            path.addLine(to: snapshot.point(for: coordinate))
        }

        path.addLine(to: snapshot.point(for: coordinates[0]))
        path.close()
        
        shapeLayer.path = path.cgPath
        shapeLayer.lineWidth = self.width ?? 0
        shapeLayer.strokeColor = self.strokeColor?.cgColor ?? UIColor.clear.cgColor
        shapeLayer.fillColor = self.fillColor?.cgColor ?? UIColor.clear.cgColor
        shapeLayer.lineCap = .round
        shapeLayer.lineJoin = .round
        
        return shapeLayer
    }
}


public extension MKPolygon {
    func contains(coordinate: CLLocationCoordinate2D) -> Bool {
        let polygonRenderer = MKPolygonRenderer(polygon: self)
        let currentMapPoint: MKMapPoint = MKMapPoint(coordinate)
        let polygonViewPoint: CGPoint = polygonRenderer.point(for: currentMapPoint)
        if polygonRenderer.path == nil {
          return false
        } else{
            return polygonRenderer.path.contains(polygonViewPoint)
        }
    }
}
