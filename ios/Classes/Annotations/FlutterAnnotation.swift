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
    var icon: AnnotationIcon = AnnotationIcon.init()
    var selectedProgrammatically: Bool = false
    
    // New properties for place markers
    var pointOfInterestCategory: MKPointOfInterestCategory?
    var mapFeatureType: MKMapFeatureType?
    
    public init(fromDictionary annotationData: Dictionary<String, Any>, registrar: FlutterPluginRegistrar) {
        let position: Array<Double> = annotationData["position"] as! Array<Double>
        let infoWindow: Dictionary<String, Any> = annotationData["infoWindow"] as! Dictionary<String, Any>
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
        
        if let alpha: Double = annotationData["alpha"] as? Double {
            self.alpha = alpha
        }
        
        if let anchorJSON: Array<Double> = annotationData["anchor"] as? Array<Double> {
            self.anchor = Offset(from: anchorJSON)
        }
        
        if let iconData: Array<Any> = annotationData["icon"] as? Array<Any> {
            self.icon = FlutterAnnotation.getAnnotationIcon(iconData: iconData, registrar: registrar, annotationId: id)
        }
        
        if let calloutOffsetJSON = infoWindow["anchor"] as? Array<Double> {
            self.calloutOffset = Offset(from: calloutOffsetJSON)
        }
        
        if let poiCategoryString = annotationData["pointOfInterestCategory"] as? String {
            self.pointOfInterestCategory = MKPointOfInterestCategory(rawValue: poiCategoryString)
        } else {
            self.pointOfInterestCategory = nil
        }
        
        if let featureType = annotationData["mapFeatureType"] as? String {
            self.mapFeatureType = MKMapFeatureType(rawValue: featureType)
        }
    }
    
    static private func getAnnotationIcon(iconData: Array<Any>, registrar: FlutterPluginRegistrar, annotationId: String) -> AnnotationIcon {
        let iconTypeMap: Dictionary<String, IconType> = ["fromAssetImage": .CUSTOM_FROM_ASSET, "fromBytes": .CUSTOM_FROM_BYTES, "defaultAnnotation": .PIN, "markerAnnotation": .MARKER]
        let iconType: IconType = iconTypeMap[iconData[0] as! String] ?? .PIN
        var icon: AnnotationIcon =  AnnotationIcon(id: annotationId, iconType: iconType)
        var scaleParam: CGFloat?
        
        if iconType == .CUSTOM_FROM_ASSET {
            let assetPath: String = iconData[1] as! String
            scaleParam = CGFloat(iconData[2] as? Double ?? 1.0)
            icon = AnnotationIcon(withAsset: registrar.lookupKey(forAsset: assetPath), id: annotationId, iconScale: scaleParam)
        } else if iconType == .CUSTOM_FROM_BYTES {
            icon = AnnotationIcon(fromBytes: iconData[1] as! FlutterStandardTypedData, id: annotationId)
        } else if iconData.count > 1 {
            icon = AnnotationIcon(id: annotationId, iconType: iconType, hueColor: iconData[1] as! Double)
            
        }
        return icon
    }
    
    static func == (lhs: FlutterAnnotation, rhs: FlutterAnnotation) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title && lhs.subtitle == rhs.subtitle && lhs.image == rhs.image && lhs.alpha == rhs.alpha && lhs.isDraggable == rhs.isDraggable && lhs.wasDragged == rhs.wasDragged && lhs.isVisible == rhs.isVisible && lhs.icon == rhs.icon && lhs.coordinate.latitude == rhs.coordinate.latitude && lhs.coordinate.longitude == rhs.coordinate.longitude && lhs.infoWindowConsumesTapEvents == rhs.infoWindowConsumesTapEvents && lhs.anchor == rhs.anchor && lhs.calloutOffset == rhs.calloutOffset && lhs.coordinate.latitude == rhs.coordinate.latitude && lhs.coordinate.longitude == rhs.coordinate.longitude && lhs.zIndex == rhs.zIndex
    }
    
    static func != (lhs: FlutterAnnotation, rhs: FlutterAnnotation) -> Bool {
        return !(lhs == rhs)
    }
    
    private static func mapToMKPointOfInterestCategory(_ category: String) -> MKPointOfInterestCategory? {
        switch category {
        case "airport": return .airport
        case "amusementPark": return .amusementPark
        case "aquarium": return .aquarium
        case "atm": return .atm
        case "bakery": return .bakery
        case "bank": return .bank
        case "beach": return .beach
        case "brewery": return .brewery
        case "cafe": return .cafe
        case "campground": return .campground
        case "carRental": return .carRental
        case "evCharger": return .evCharger
        case "fireStation": return .fireStation
        case "fitnessCenter": return .fitnessCenter
        case "foodMarket": return .foodMarket
        case "gasStation": return .gasStation
        case "hospital": return .hospital
        case "hotel": return .hotel
        case "laundry": return .laundry
        case "library": return .library
        case "marina": return .marina
        case "movieTheater": return .movieTheater
        case "museum": return .museum
        case "nationalPark": return .nationalPark
        case "nightlife": return .nightlife
        case "park": return .park
        case "parking": return .parking
        case "pharmacy": return .pharmacy
        case "police": return .police
        case "postOffice": return .postOffice
        case "publicTransport": return .publicTransport
        case "restaurant": return .restaurant
        case "restroom": return .restroom
        case "school": return .school
        case "stadium": return .stadium
        case "store": return .store
        case "theater": return .theater
        case "university": return .university
        case "winery": return .winery
        case "zoo": return .zoo
        default: return nil
        }
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
