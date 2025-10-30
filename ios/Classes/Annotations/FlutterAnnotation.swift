//
//  FlutterAnnotation.swift
//  apple_maps_flutter
//
//  Created by Luis Thein on 07.03.20.
//

import Foundation
import MapKit

class FlutterAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D
    var id: String!
    var title: String?
    var subtitle: String?
    var infoWindowConsumesTapEvents: Bool = false
    var image: UIImage?
    var alpha: Double?
    var anchor: Offset = Offset()
    var isDraggable: Bool?
    var wasDragged: Bool = false
    var isVisible: Bool? = true
    var zIndex: Double = -1
    var calloutOffset: Offset = Offset()
    var systemImageName: String?
    var desaturated: Bool = false
    var icon: AnnotationIcon = AnnotationIcon.init()
    var selectedProgrammatically: Bool = false
    
    public init(fromDictionary annotationData: Dictionary<String, Any>, registrar: FlutterPluginRegistrar) {
        guard let position = annotationData["position"] as? Array<Double>,
              let infoWindow = annotationData["infoWindow"] as? Dictionary<String, Any> else {
            // Initialize with defaults if required data is missing
            self.coordinate = CLLocationCoordinate2D()
            self.id = ""
            self.icon = AnnotationIcon()
            return
        }
        let lat: Double = position[0]
        let long: Double = position[1]
        self.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        self.title = infoWindow["title"] as? String
        self.subtitle = infoWindow["snippet"] as? String
        self.infoWindowConsumesTapEvents = infoWindow["consumesTapEvents"] as? Bool ?? false
        self.id = annotationData["annotationId"] as? String
        self.isVisible = annotationData["visible"] as? Bool
        self.isDraggable = annotationData["draggable"] as? Bool
        if let zIndex = annotationData["zIndex"] as? Double {
            self.zIndex = zIndex
        }

        if let systemImageName = annotationData["systemImageName"] as? String {
            self.systemImageName = systemImageName
        }
        
        if let desaturated = annotationData["desaturated"] as? Bool {
            self.desaturated = desaturated
        }
        
        if let alpha: Double = annotationData["alpha"] as? Double {
            self.alpha = alpha
        }
        
        if let anchorJSON: Array<Double> = annotationData["anchor"] as? Array<Double> {
            self.anchor = Offset(from: anchorJSON)
        }
        
        if let iconData: Array<Any> = annotationData["icon"] as? Array<Any> {
            self.icon = FlutterAnnotation.getAnnotationIcon(iconData: iconData, registrar: registrar, annotationId: id, desaturated: self.desaturated)
        }
        
        if let calloutOffsetJSON = infoWindow["anchor"] as? Array<Double> {
            self.calloutOffset = Offset(from: calloutOffsetJSON)
        }
    }
    
    
    static private func getAnnotationIcon(iconData: Array<Any>, registrar: FlutterPluginRegistrar, annotationId: String, desaturated: Bool = false) -> AnnotationIcon {
        let iconTypeMap: Dictionary<String, IconType> = ["fromAssetImage": .CUSTOM_FROM_ASSET, "fromBytes": .CUSTOM_FROM_BYTES, "defaultAnnotation": .PIN, "markerAnnotation": .MARKER]
        guard let iconTypeString = iconData[0] as? String else {
            return AnnotationIcon(id: annotationId, iconType: .PIN)
        }
        let iconType: IconType = iconTypeMap[iconTypeString] ?? .PIN
        var icon: AnnotationIcon =  AnnotationIcon(id: annotationId, iconType: iconType)
        icon.desaturated = desaturated
        var scaleParam: CGFloat?

        if iconType == .CUSTOM_FROM_ASSET {
            guard iconData.count > 1,
                  let assetPath = iconData[1] as? String else {
                return icon
            }
            scaleParam = CGFloat(iconData[2] as? Double ?? 1.0)
            icon = AnnotationIcon(withAsset: registrar.lookupKey(forAsset: assetPath), id: annotationId, iconScale: scaleParam, desaturated: desaturated)
        } else if iconType == .CUSTOM_FROM_BYTES {
            guard iconData.count > 1,
                  let bytes = iconData[1] as? FlutterStandardTypedData else {
                return icon
            }
            icon = AnnotationIcon(fromBytes: bytes, id: annotationId, desaturated: desaturated)
        } else if iconData.count > 1 {
            guard let hueColor = iconData[1] as? Double else {
                return icon
            }
            icon = AnnotationIcon(id: annotationId, iconType: iconType, hueColor: hueColor)
            icon.desaturated = desaturated
        }
        return icon
    }
    
    static func == (lhs: FlutterAnnotation, rhs: FlutterAnnotation) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title && lhs.subtitle == rhs.subtitle && lhs.image == rhs.image && lhs.alpha == rhs.alpha && lhs.isDraggable == rhs.isDraggable && lhs.wasDragged == rhs.wasDragged && lhs.isVisible == rhs.isVisible && lhs.desaturated == rhs.desaturated && lhs.icon == rhs.icon && lhs.coordinate.latitude == rhs.coordinate.latitude && lhs.coordinate.longitude == rhs.coordinate.longitude && lhs.infoWindowConsumesTapEvents == rhs.infoWindowConsumesTapEvents && lhs.anchor == rhs.anchor && lhs.calloutOffset == rhs.calloutOffset && lhs.zIndex == rhs.zIndex
    }
    
    static func != (lhs: FlutterAnnotation, rhs: FlutterAnnotation) -> Bool {
        return !(lhs == rhs)
    }
}

struct Offset {
    let x: Double
    let y: Double
    
    public init(from json: Array<Double>) {
        self.x = json[0]
        self.y = json[1]
    }
    
    public init() {
        self.x = 0
        self.y = 0
    }
    
    static func == (lhs: Offset, rhs: Offset) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
    
    static func != (lhs: Offset, rhs: Offset) -> Bool {
        return !(lhs == rhs)
    }
}
