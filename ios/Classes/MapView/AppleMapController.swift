//
//  AppleMapController.swift
//  apple_maps_flutter
//
//  Created by Luis Thein on 03.09.19.
//

import Foundation
import UIKit
import MapKit
import Flutter

public class AppleMapController: NSObject, FlutterPlatformView {
    var contentView: UIView
    var mapView: FlutterMapView
    var registrar: FlutterPluginRegistrar
    var channel: FlutterMethodChannel
    var initialCameraPosition: [String: Any]
    var options: [String: Any]
    var currentlySelectedAnnotation: String?
    var snapShotOptions: MKMapSnapshotter.Options = MKMapSnapshotter.Options()
    var snapShot: MKMapSnapshotter?
    
    // State tracking for unclustered annotations
    var unclusteredAnnotations: Set<String> = []
    var originalCoordinates: [String: CLLocationCoordinate2D] = [:]
    var unclusterCenterPoints: [CLLocationCoordinate2D] = []

    // Add at class level
    private var lastZoomLevel: Double = 0.0

    deinit {
        // Cancel any ongoing snapshot operations to prevent memory leaks
        snapShot?.cancel()
        snapShot = nil
    }
    
    public init(withFrame frame: CGRect, withRegistrar registrar: FlutterPluginRegistrar, withargs args: Dictionary<String, Any> ,withId id: Int64) {
        guard let options = args["options"] as? [String: Any] else {
            fatalError("AppleMapController: Missing required 'options' parameter")
        }
        self.options = options

        guard let initialCameraPosition = args["initialCameraPosition"] as? Dictionary<String, Any> else {
            fatalError("AppleMapController: Missing required 'initialCameraPosition' parameter")
        }
        self.initialCameraPosition = initialCameraPosition

        self.channel = FlutterMethodChannel(name: "apple_maps_plugin.luisthein.de/apple_maps_\(id)", binaryMessenger: registrar.messenger())

        self.mapView = FlutterMapView(channel: channel, options: options, initialCameraPosition: initialCameraPosition)
        self.registrar = registrar

        // Use the mapView directly as the content view
        self.contentView = mapView
        
        super.init()

        self.mapView.delegate = self

        self.setMethodCallHandlers()
        
        if let annotationsToAdd: NSArray = args["annotationsToAdd"] as? NSArray {
            self.annotationsToAdd(annotations: annotationsToAdd)
        }
        if let polylinesToAdd: NSArray = args["polylinesToAdd"] as? NSArray {
            self.addPolylines(polylineData: polylinesToAdd)
        }
        if let polygonsToAdd: NSArray = args["polygonsToAdd"] as? NSArray {
            self.addPolygons(polygonData: polygonsToAdd)
        }
        if let circlesToAdd: NSArray = args["circlesToAdd"] as? NSArray {
            self.addCircles(circleData: circlesToAdd)
        }
    }
    
    public func view() -> UIView {
        return contentView
    }
    
    private func setMethodCallHandlers() {
        channel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard let strongSelf = self else {
                return
            }
            if let args: Dictionary<String, Any> = call.arguments as? Dictionary<String,Any> {
                switch(call.method) {
                case "annotations#update":
                    strongSelf.annotationUpdate(args: args)
                    result(nil)
                    break
                case "annotations#showInfoWindow":
                    guard let annotationId = args["annotationId"] as? String else {
                        result(FlutterError(code: "INVALID_ARGUMENT", message: "annotationId is required", details: nil))
                        return
                    }
                    strongSelf.selectAnnotation(with: annotationId)
                    break
                case "annotations#hideInfoWindow":
                    guard let annotationId = args["annotationId"] as? String else {
                        result(FlutterError(code: "INVALID_ARGUMENT", message: "annotationId is required", details: nil))
                        return
                    }
                    strongSelf.hideAnnotation(with: annotationId)
                    break
                case "annotations#isInfoWindowShown":
                    guard let annotationId = args["annotationId"] as? String else {
                        result(FlutterError(code: "INVALID_ARGUMENT", message: "annotationId is required", details: nil))
                        return
                    }
                    result(strongSelf.isAnnotationSelected(with: annotationId))
                    break
                case "polylines#update":
                    strongSelf.polylineUpdate(args: args)
                    result(nil)
                    break
                case "polygons#update":
                    strongSelf.polygonUpdate(args: args)
                    result(nil)
                    break
                case "circles#update":
                    strongSelf.circleUpdate(args: args)
                    result(nil)
                    break
                case "map#update":
                    guard let options = args["options"] as? Dictionary<String, Any> else {
                        result(FlutterError(code: "INVALID_ARGUMENT", message: "options are required", details: nil))
                        return
                    }
                    strongSelf.mapView.interpretOptions(options: options)
                    break
                case "map#updateTheme":
                    guard let themeIndex = args["themeIndex"] as? Int else {
                        result(FlutterError(code: "INVALID_ARGUMENT", message: "themeIndex is required", details: nil))
                        return
                    }
                    if #available(iOS 13.0, *) {
                        strongSelf.mapView.applyTheme(themeIndex)
                    }
                    result(nil)
                    break
                case "camera#animate":
                    strongSelf.animateCamera(args: args)
                    result(nil)
                    break
                case "camera#move":
                    strongSelf.moveCamera(args: args)
                    result(nil)
                    break
                case "camera#convert":
                    strongSelf.cameraConvert(args: args, result: result)
                    break
                case "map#takeSnapshot":
                    strongSelf.takeSnapshot(options: SnapshotOptions.init(options: args), onCompletion: { (snapshot: FlutterStandardTypedData?, error: Error?) -> Void in
                        result(snapshot ?? error)
                    })
                default:
                    result(FlutterMethodNotImplemented)
                    break
                }
            } else {
                switch call.method {
                case "map#getVisibleRegion":
                    result(strongSelf.mapView.getVisibleRegion())
                    break
                case "map#isCompassEnabled":
                    if #available(iOS 9.0, *) {
                        result(strongSelf.mapView.showsCompass)
                    } else {
                        result(false)
                    }
                    break
                case "map#isPitchGesturesEnabled":
                    result(strongSelf.mapView.isPitchEnabled)
                    break
                case "map#isScrollGesturesEnabled":
                    result(strongSelf.mapView.isScrollEnabled)
                    break
                case "map#isZoomGesturesEnabled":
                    result(strongSelf.mapView.isZoomEnabled)
                    break
                case "map#isRotateGesturesEnabled":
                    result(strongSelf.mapView.isRotateEnabled)
                    break
                case "map#isMyLocationButtonEnabled":
                    result(strongSelf.mapView.isMyLocationButtonShowing ?? false)
                    break
                case "map#getMinMaxZoomLevels":
                    result([strongSelf.mapView.minZoomLevel, strongSelf.mapView.maxZoomLevel])
                    break
                case "camera#getZoomLevel":
                    result(strongSelf.mapView.calculatedZoomLevel)
                    break
                default:
                    result(FlutterMethodNotImplemented)
                    break
                }
            }
        })
    }
    
    private func annotationUpdate(args: Dictionary<String, Any>) -> Void {
        if let annotationsToAdd = args["annotationsToAdd"] as? NSArray {
            if annotationsToAdd.count > 0 {
                self.annotationsToAdd(annotations: annotationsToAdd)
            }
        }
        if let annotationsToChange = args["annotationsToChange"] as? NSArray {
            if annotationsToChange.count > 0 {
                self.annotationsToChange(annotations: annotationsToChange)
            }
        }
        if let annotationsToDelete = args["annotationIdsToRemove"] as? NSArray {
            if annotationsToDelete.count > 0 {
                self.annotationsIdsToRemove(annotationIds: annotationsToDelete)
            }
        }
    }
    
    private func polygonUpdate(args: Dictionary<String, Any>) -> Void {
        if let polygonsToAdd: NSArray = args["polygonsToAdd"] as? NSArray {
            self.addPolygons(polygonData: polygonsToAdd)
        }
        if let polygonsToChange: NSArray = args["polygonsToChange"] as? NSArray {
            self.changePolygons(polygonData: polygonsToChange)
        }
        if let polygonsToRemove: NSArray = args["polygonIdsToRemove"] as? NSArray {
            self.removePolygons(polygonIds: polygonsToRemove)
        }
    }
    
    private func polylineUpdate(args: Dictionary<String, Any>) -> Void {
        if let polylinesToAdd: NSArray = args["polylinesToAdd"] as? NSArray {
            self.addPolylines(polylineData: polylinesToAdd)
        }
        if let polylinesToChange: NSArray = args["polylinesToChange"] as? NSArray {
            self.changePolylines(polylineData: polylinesToChange)
        }
        if let polylinesToRemove: NSArray = args["polylineIdsToRemove"] as? NSArray {
            self.removePolylines(polylineIds: polylinesToRemove)
        }
    }
    
    private func circleUpdate(args: Dictionary<String, Any>) -> Void {
        if let circlesToAdd: NSArray = args["circlesToAdd"] as? NSArray {
            self.addCircles(circleData: circlesToAdd)
        }
        if let circlesToChange: NSArray = args["circlesToChange"] as? NSArray {
            self.changeCircles(circleData: circlesToChange)
        }
        if let circlesToRemove: NSArray = args["circleIdsToRemove"] as? NSArray {
            self.removeCircles(circleIds: circlesToRemove)
        }
    }
    
    private func moveCamera(args: Dictionary<String, Any>) -> Void {
        guard let cameraUpdate = args["cameraUpdate"] as? Array<Any> else {
            return
        }
        let positionData: Dictionary<String, Any> = self.toPositionData(data: cameraUpdate, animated: true)
        if !positionData.isEmpty {
            guard let _ = positionData["moveToBounds"] else {
                self.mapView.setCenterCoordinate(positionData, animated: false)
                return
            }
            self.mapView.setBounds(positionData, animated: false)
        }
    }

    private func animateCamera(args: Dictionary<String, Any>) -> Void {
        guard let cameraUpdate = args["cameraUpdate"] as? Array<Any> else {
            return
        }
        let positionData: Dictionary<String, Any> = self.toPositionData(data: cameraUpdate, animated: true)
        if !positionData.isEmpty {
            guard let _ = positionData["moveToBounds"] else {
                self.mapView.setCenterCoordinate(positionData, animated: true)
                return
            }
            self.mapView.setBounds(positionData, animated: true)
        }
    }
    
    private func cameraConvert(args: Dictionary<String, Any>, result: FlutterResult) -> Void {
        guard let annotation = args["annotation"] as? Array<Double>,
              annotation.count >= 2 else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "annotation must contain at least 2 coordinates [latitude, longitude]", details: nil))
            return
        }
        let point = self.mapView.convert(CLLocationCoordinate2D(latitude: annotation[0] , longitude: annotation[1]), toPointTo: self.view() as UIView)
        result(["point": [point.x, point.y]])
    }
    
    private func toPositionData(data: Array<Any>, animated: Bool) -> Dictionary<String, Any> {
        var positionData: Dictionary<String, Any> = [:]
        guard let update: String = data[0] as? String else {
            return [:]
        }

        switch(update) {
        case "newCameraPosition":
            if let _positionData : Dictionary<String, Any> = data[1] as? Dictionary<String, Any> {
                positionData = _positionData
            }
            break
        case "newLatLng":
            if let _positionData : Array<Any> = data[1] as? Array<Any> {
                positionData = ["target": _positionData]
            }
            break
        case "newLatLngZoom":
            if let _positionData: Array<Any> = data[1] as? Array<Any> {
                let zoom: Double = data[2] as? Double ?? 0
                positionData = ["target": _positionData, "zoom": zoom]
            }
            break
        case "newLatLngBounds":
            if let _positionData: Array<Any> = data[1] as? Array<Any> {
                let padding: Double = data[2] as? Double ?? 0
                positionData = ["target": _positionData, "padding": padding, "moveToBounds": true]
            }
            break
        case "zoomBy":
            if let zoomBy: Double = data[1] as? Double {
                mapView.zoomBy(zoomBy: zoomBy, animated: animated)
            }
            // For zoom operations, return empty dict as they don't change position
            return [:]
        case "zoomTo":
            if let zoomTo: Double = data[1] as? Double {
                mapView.zoomTo(newZoomLevel: zoomTo, animated: animated)
            }
            // For zoom operations, return empty dict as they don't change position
            return [:]
        case "zoomIn":
            mapView.zoomIn(animated: animated)
            // For zoom operations, return empty dict as they don't change position
            return [:]
        case "zoomOut":
            mapView.zoomOut(animated: animated)
            // For zoom operations, return empty dict as they don't change position
            return [:]
        default:
            positionData = [:]
        }
        return positionData
    }
}


extension AppleMapController: MKMapViewDelegate {
    // onIdle
    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // Ensure UI operations are performed on main thread
        DispatchQueue.main.async {
            if ((self.mapView.mapContainerView) != nil) {
                let locationOnMap = self.mapView.region.center
                self.channel.invokeMethod("camera#onMove", arguments: ["position": ["heading": self.mapView.actualHeading, "target":  [locationOnMap.latitude, locationOnMap.longitude], "pitch": self.mapView.camera.pitch, "zoom": self.mapView.calculatedZoomLevel]])
            }
            
            // Check if we should automatically uncluster same-location annotations
            self.checkForAutoUnclustering()
            
            // Check if we should re-cluster annotations
            self.checkForReclustering()
            
            self.channel.invokeMethod("camera#onIdle", arguments: "")
        }
    }
    
    /// Automatically unclusters annotations at the same location when zoomed in enough
    private func checkForAutoUnclustering() {
        let currentZoom = self.mapView.calculatedZoomLevel
        
        // Only uncluster when zooming in and reaching 18 or higher
        if currentZoom > self.lastZoomLevel && currentZoom >= 18 {
            // Check all visible cluster annotations
            if #available(iOS 11.0, *) {
                for annotation in self.mapView.annotations {
                    guard let cluster = annotation as? MKClusterAnnotation else {
                        continue
                    }
                    
                    // Skip empty clusters
                    guard !cluster.memberAnnotations.isEmpty else {
                        continue
                    }
                    
                    // Check if all annotations in this cluster are at the same location
                    guard self.allAnnotationsAtSameLocation(cluster.memberAnnotations) else {
                        continue
                    }
                    
                    // Check if any of these annotations are already unclustered
                    var alreadyUnclustered = false
                    for member in cluster.memberAnnotations {
                        if let flutterAnnotation = member as? FlutterAnnotation,
                           self.unclusteredAnnotations.contains(flutterAnnotation.id) {
                            alreadyUnclustered = true
                            break
                        }
                    }
                    
                    // If not already unclustered, uncluster them now
                    if !alreadyUnclustered {
                        self.unclusterAnnotationsAtSameLocation(cluster)
                    }
                }
            }
        }
    }
    
    /// Checks if unclustered annotations should be re-clustered based on zoom/pan changes
    private func checkForReclustering() {
        guard !self.unclusteredAnnotations.isEmpty else {
            return
        }
        
        let currentZoom = self.mapView.calculatedZoomLevel
        
        // Re-cluster only when zooming out below 17
        if currentZoom < self.lastZoomLevel && currentZoom < 17 {
            self.reclusterAnnotations()
        }
    }

    // onMoveStarted
    public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        // Ensure UI operations are performed on main thread
        DispatchQueue.main.async {
            self.channel.invokeMethod("camera#onMoveStarted", arguments: "")
        }
    }
    
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is FlutterPolyline {
            return self.polylineRenderer(overlay: overlay)
        } else if overlay is FlutterPolygon {
            return self.polygonRenderer(overlay: overlay)
        } else if overlay is FlutterCircle {
            return self.circleRenderer(overlay: overlay)
        }
        return MKOverlayRenderer()
    }
}

extension AppleMapController {
    private func takeSnapshot(options: SnapshotOptions, onCompletion: @escaping (FlutterStandardTypedData?, Error?) -> Void) {
        // Cancel any existing snapshot operation to prevent memory leaks
        snapShot?.cancel()
        snapShot = nil

        // MKMapSnapShotOptions setting.
        snapShotOptions.region = self.mapView.region
        snapShotOptions.size = self.mapView.frame.size
        snapShotOptions.scale = UIScreen.main.scale
        snapShotOptions.showsBuildings = options.showBuildings
        snapShotOptions.showsPointsOfInterest = options.showPointsOfInterest

        // Set MKMapSnapShotOptions to MKMapSnapShotter.
        snapShot = MKMapSnapshotter(options: snapShotOptions)
        
        if #available(iOS 10.0, *) {
            snapShot?.start { [weak self] snapshot, error in
                guard let self = self else {
                    return
                }

                guard let snapshot = snapshot, error == nil else {
                    onCompletion(nil, error)
                    return
                }

                // Ensure UI operations are performed on main thread
                DispatchQueue.main.async {
                    self.renderSnapshotImage(snapshot: snapshot, options: options) { image in
                        if let imageData = image.pngData() {
                            onCompletion(FlutterStandardTypedData.init(bytes: imageData), nil)
                        } else {
                            onCompletion(nil, NSError(domain: "SnapshotError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to generate snapshot image"]))
                        }
                    }
                }
            }
        }
    }

    private func renderSnapshotImage(snapshot: MKMapSnapshotter.Snapshot, options: SnapshotOptions, completion: @escaping (UIImage) -> Void) {
        let image = UIGraphicsImageRenderer(size: self.snapShotOptions.size).image { [weak self] context in
            guard let self = self else {
                return
            }
            snapshot.image.draw(at: .zero)
            let rect = self.snapShotOptions.mapRect
            if options.showAnnotations {
                for annotation in self.mapView.getMapViewAnnotations() {
                    if let annotation = annotation {
                        self.drawAnnotations(annotation: annotation, point: snapshot.point(for: annotation.coordinate))
                    }
                }
            }
            if options.showOverlays {
                for overlay in self.mapView.overlays {
                    if ((overlay.intersects?(rect)) != nil) {
                        self.drawOverlays(overlay: overlay, snapshot: snapshot, context: context)
                    }
                }
            }
        }
        completion(image)
    }

    private func drawAnnotations(annotation: FlutterAnnotation?, point: CGPoint) {
        guard annotation != nil else {
            return
        }
        let annotationView = self.getAnnotationView(annotation: annotation!)
        
        var offsetPoint = point
        
        offsetPoint.x -= annotationView.bounds.width / 2
        offsetPoint.y -= annotationView.bounds.height / 2
        
        
        if #available(iOS 11.0, *), annotationView is MKMarkerAnnotationView {
            annotationView.drawHierarchy(in: CGRect(x: offsetPoint.x, y: offsetPoint.y, width: annotationView.bounds.width, height: annotationView.bounds.height), afterScreenUpdates: true)
        } else {
            offsetPoint.x += annotationView.centerOffset.x
            offsetPoint.y += annotationView.centerOffset.y
            let annotationImage = annotationView.image
            annotationImage?.draw(at: offsetPoint)
        }
    }
    
    @available(iOS 10.0, *)
    private func drawOverlays(overlay: MKOverlay?, snapshot: MKMapSnapshotter.Snapshot, context: UIGraphicsRendererContext) {
        guard overlay != nil else {
            return
        }

        if let flutterOverlay: FlutterOverlay = overlay as? FlutterOverlay {
            flutterOverlay.getCAShapeLayer(snapshot: snapshot).render(in: context.cgContext)
        }

    }
}
