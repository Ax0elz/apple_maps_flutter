//
//  AnnotationController.swift
//  apple_maps_flutter
//
//  Created by Luis Thein on 09.09.19.
//

import Foundation
import MapKit

extension AppleMapController: AnnotationDelegate {

    public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)  {
        if #available(iOS 11.0, *), let cluster = view.annotation as? MKClusterAnnotation {
            // Handle cluster tap - validate cluster has members before zooming
            guard !cluster.memberAnnotations.isEmpty else {
                return
            }

            let region = self.getRegionForCluster(cluster)
            mapView.setRegion(region, animated: true)
            return
        }
        
        if let annotation: FlutterAnnotation = view.annotation as? FlutterAnnotation  {
            self.currentlySelectedAnnotation = annotation.id
            if !annotation.selectedProgrammatically {
                if !self.isAnnotationInFront(zIndex: annotation.zIndex) {
                    self.moveToFront(annotation: annotation)
                }
                self.onAnnotationClick(annotation: annotation)
            } else {
                annotation.selectedProgrammatically = false
            }

            if annotation.infoWindowConsumesTapEvents {
                let tapGestureRecognizer = InfoWindowTapGestureRecognizer(target: self, action: #selector(onCalloutTapped))
                tapGestureRecognizer.annotationId = annotation.id
                tapGestureRecognizer.annotationView = view
                view.addGestureRecognizer(tapGestureRecognizer)
            }
        }
    }

    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        } 
        // Handle single FlutterAnnotation
        else if let flutterAnnotation = annotation as? FlutterAnnotation {
            let view = self.getAnnotationView(annotation: flutterAnnotation)
            if #available(iOS 11.0, *), let mapView = self.mapView as? FlutterMapView, mapView.clusteringEnabled {
                view.clusteringIdentifier = "flutterAnnotation"
            }
            return view
        } 
        // Handle cluster annotation
        else if #available(iOS 11.0, *), let cluster = annotation as? MKClusterAnnotation {
            // Validate cluster has members before creating view
            guard !cluster.memberAnnotations.isEmpty else {
                return nil
            }

            let identifier = "cluster"
            var clusterView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            if clusterView == nil {
                clusterView = MKMarkerAnnotationView(annotation: cluster, reuseIdentifier: identifier)
                clusterView?.displayPriority = .defaultHigh
                clusterView?.titleVisibility = .hidden
                clusterView?.subtitleVisibility = .hidden
                clusterView?.canShowCallout = false
            } else {
                clusterView?.annotation = cluster
            }
            
            // Determine the most common hueColor among member annotations
            var hueCount: [Double: Int] = [:]
            var validAnnotationsCount = 0

            for member in cluster.memberAnnotations {
                // Validate member annotation first
                guard let flutterAnnotation = member as? FlutterAnnotation else {
                    continue
                }

                // Only consider MARKER and PIN icon types for color calculation
                guard flutterAnnotation.icon.iconType == .MARKER || flutterAnnotation.icon.iconType == .PIN else {
                    continue
                }

                // Validate hue color exists and is in valid range [0, 1]
                guard let hueColor = flutterAnnotation.icon.hueColor,
                      hueColor >= 0 && hueColor <= 1 && hueColor.isFinite else {
                    continue
                }

                hueCount[hueColor, default: 0] += 1
                validAnnotationsCount += 1
            }

            // Select the most common hueColor or default to blue (hue = 0.6667)
            let mostCommonHue: Double
            if let (hue, count) = hueCount.max(by: { $0.value < $1.value }), count > 0 {
                mostCommonHue = hue
            } else {
                // Default to blue if no valid colors found or no annotations with colors
                mostCommonHue = 0.6667 // Default to blue
            }

            // Set cluster color with improved saturation based on cluster size and validity
            let saturation = validAnnotationsCount > 0 ? min(CGFloat(validAnnotationsCount) / 10.0, 1.0) : 0.5
            clusterView?.markerTintColor = UIColor(hue: CGFloat(mostCommonHue), saturation: saturation, brightness: 1, alpha: 1)
            clusterView?.glyphText = "\(cluster.memberAnnotations.count)"
            
            return clusterView
        }
        return nil
    }

    func getAnnotationView(annotation: FlutterAnnotation) -> MKAnnotationView {
        let identifier = "flutterAnnotation"  // Use consistent identifier for clustering
        var annotationView = self.mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        let oldflutterAnnoation = annotationView?.annotation as? FlutterAnnotation
        if annotationView == nil || oldflutterAnnoation?.icon.iconType != annotation.icon.iconType {
            if #available(iOS 11.0, *), annotation.icon.iconType == IconType.MARKER {
                annotationView = getMarkerAnnotationView(annotation: annotation, id: identifier)
            } else if annotation.icon.iconType == .CUSTOM_FROM_ASSET || annotation.icon.iconType == .CUSTOM_FROM_BYTES {
                annotationView = getCustomAnnotationView(annotation: annotation, id: identifier)
            } else {
                annotationView = getPinAnnotationView(annotation: annotation, id: identifier)
            }
        }
        guard annotationView != nil else {
            return FlutterAnnotationView()
        }
        annotationView!.annotation = annotation
        // If annotation is not visible set alpha to 0 and don't let the user interact with it
        if !(annotation.isVisible ?? true) {
            annotationView!.canShowCallout = false
            annotationView!.alpha = CGFloat(0.0)
            annotationView!.isDraggable = false
            return annotationView! as! FlutterAnnotationView
        }
        if annotation.icon.iconType != .MARKER {
            self.initInfoWindow(annotation: annotation, annotationView: annotationView!)
            if annotation.icon.iconType != .PIN {
                let x = (0.5 - annotation.anchor.x) * Double(annotationView!.frame.size.width)
                let y = (0.5 - annotation.anchor.y) * Double(annotationView!.frame.size.height)
                annotationView!.centerOffset = CGPoint(x: x, y: y)
            }
        }
        annotationView!.canShowCallout = true
        annotationView!.alpha = CGFloat(annotation.alpha ?? 1.00)
        annotationView!.isDraggable = annotation.isDraggable ?? false

        return annotationView!
    }

    func annotationsToAdd(annotations: NSArray) {
        for annotation in annotations {
            guard let annotationData = annotation as? Dictionary<String, Any> else {
                continue
            }
            addAnnotation(annotationData: annotationData)
        }
    }

    func annotationsToChange(annotations: NSArray) {
        let oldAnnotations: [MKAnnotation] = self.mapView.annotations
        for annotation in annotations {
            guard let annotationData = annotation as? Dictionary<String, Any>,
                  let annotationId = annotationData["annotationId"] as? String else {
                continue
            }
            let filteredAnnotations = oldAnnotations.filter({($0 as? FlutterAnnotation)?.id == annotationId})
            if let annotationToChange = filteredAnnotations.first as? FlutterAnnotation {
                let newAnnotation = FlutterAnnotation.init(fromDictionary: annotationData, registrar: registrar)
                if annotationToChange != newAnnotation {
                    if !annotationToChange.wasDragged {
                        updateAnnotation(annotation: newAnnotation)
                    } else {
                        annotationToChange.wasDragged = false
                    }
                }
            }
        }
    }

    func annotationsIdsToRemove(annotationIds: NSArray) {
        for annotationId in annotationIds {
            if let _annotationId: String = annotationId as? String {
                removeAnnotation(id: _annotationId)
            }
        }
    }

    func removeAllAnnotations() {
        self.mapView.removeAnnotations(self.mapView.annotations)
    }

    func onAnnotationClick(annotation: MKAnnotation) {
        if let flutterAnnotation: FlutterAnnotation = annotation as? FlutterAnnotation {
            flutterAnnotation.wasDragged = true
            channel.invokeMethod("annotation#onTap", arguments: ["annotationId" : flutterAnnotation.id])
        }
    }

    func selectAnnotation(with id: String) {
        if let annotation: FlutterAnnotation = self.getAnnotation(with: id) {
            annotation.selectedProgrammatically = true
            self.mapView.selectAnnotation(annotation, animated: true)
        }
    }

    func hideAnnotation(with id: String) {
        if let annotation: FlutterAnnotation = self.getAnnotation(with: id) {
            self.mapView.deselectAnnotation(annotation, animated: true)
        }
    }

    func isAnnotationSelected(with id: String) -> Bool {
        return self.mapView.selectedAnnotations.contains(where: { annotation in return self.getAnnotation(with: id) == (annotation as? FlutterAnnotation)})
    }


    private func removeAnnotation(id: String) {
        if let flutterAnnotation: FlutterAnnotation = self.getAnnotation(with: id) {
            self.mapView.removeAnnotation(flutterAnnotation)
        }
    }

    private func initInfoWindow(annotation: FlutterAnnotation, annotationView: MKAnnotationView) {
        let x = self.getInfoWindowXOffset(annotationView: annotationView, annotation: annotation)
        let y = self.getInfoWindowYOffset(annotationView: annotationView, annotation: annotation)
        annotationView.calloutOffset = CGPoint(x: x, y: y)
        if #available(iOS 9.0, *) {
            if let subtitle = annotation.subtitle,
               let lines = subtitle.split(whereSeparator: { $0.isNewline }) as? [String],
               !lines.isEmpty {
                let customCallout = UIStackView()
                customCallout.axis = .vertical
                customCallout.alignment = .fill
                customCallout.distribution = .fill
                for line in lines {
                    let subtitleLabel = UILabel()
                    subtitleLabel.text = String(line)
                    customCallout.addArrangedSubview(subtitleLabel)
                }
                annotationView.detailCalloutAccessoryView = customCallout
            }
        }
    }

    @objc func onCalloutTapped(infoWindowTap: InfoWindowTapGestureRecognizer) {
        guard let annotationId = infoWindowTap.annotationId else {
            return
        }

        if self.currentlySelectedAnnotation == annotationId {
            self.channel.invokeMethod("infoWindow#onTap", arguments: ["annotationId": annotationId])
        }

        if infoWindowTap.annotationView != nil && self.currentlySelectedAnnotation != annotationId {
            infoWindowTap.annotationView?.removeGestureRecognizer(infoWindowTap)
        }
    }

    private func getAnnotation(with id: String) -> FlutterAnnotation? {
        return self.mapView.annotations.filter { annotation in return (annotation as? FlutterAnnotation)?.id == id }.first as? FlutterAnnotation
    }

    private func annotationExists(with id: String) -> Bool {
        return self.getAnnotation(with: id) != nil
    }

    private func addAnnotation(annotationData: Dictionary<String, Any>) {
        let annotation: FlutterAnnotation = FlutterAnnotation(fromDictionary: annotationData, registrar: registrar)
        self.addAnnotation(annotation: annotation)
    }

    /**
     Checks if an Annotation with the same id exists and removes it before adding if necessary
     - Parameter annotation: the FlutterAnnotation that should be added
     */
    private func addAnnotation(annotation: FlutterAnnotation) {
        if self.annotationExists(with: annotation.id) {
            self.removeAnnotation(id: annotation.id)
        }
        if annotation.zIndex == -1 {
            annotation.zIndex = self.getNextAnnotationZIndex()
            if let annotationId = annotation.id {
                channel.invokeMethod("annotation#onZIndexChanged", arguments: ["annotationId": annotationId, "zIndex": annotation.zIndex])
            }
        }
        self.mapView.addAnnotation(annotation)
    }

    private func updateAnnotation(annotation: FlutterAnnotation) {
        if let oldAnnotation = self.getAnnotation(with: annotation.id) {
            UIView.animate(withDuration: 0.1, animations: {
                oldAnnotation.coordinate = annotation.coordinate
                oldAnnotation.zIndex = annotation.zIndex
                oldAnnotation.anchor = annotation.anchor
                oldAnnotation.alpha = annotation.alpha
                oldAnnotation.isVisible = annotation.isVisible
                oldAnnotation.title = annotation.title
                oldAnnotation.subtitle = annotation.subtitle
                oldAnnotation.systemImageName = annotation.systemImageName
                oldAnnotation.desaturated = annotation.desaturated
                
                // Update badge properties
                oldAnnotation.badgeSystemImageName = annotation.badgeSystemImageName
                oldAnnotation.badgeOffset = annotation.badgeOffset
                oldAnnotation.badgeSizeRatio = annotation.badgeSizeRatio
                oldAnnotation.badgeAlpha = annotation.badgeAlpha
                oldAnnotation.badgeBackgroundColor = annotation.badgeBackgroundColor
                oldAnnotation.badgeShape = annotation.badgeShape
            })
            
            // Update the annotation view with the new appearance
            if let view = self.mapView.view(for: oldAnnotation) {
                let newAnnotationView = getAnnotationView(annotation: annotation)

                // For marker annotation views, we need to update the specific properties
                if #available(iOS 11.0, *), let markerView = view as? MKMarkerAnnotationView,
                   let newMarkerView = newAnnotationView as? MKMarkerAnnotationView {
                    // Update marker-specific properties
                    markerView.markerTintColor = newMarkerView.markerTintColor
                    markerView.glyphImage = newMarkerView.glyphImage
                } else {
                    // For other annotation views, update the image
                    view.image = newAnnotationView.image
                }
                
                // Update or remove badge
                removeBadgeFromAnnotationView(view)
                if annotation.badgeSystemImageName != nil {
                    addBadgeToAnnotationView(view, annotation: annotation)
                }
            }
        }
    }

    private func getNextAnnotationZIndex() -> Double {
        let mapViewAnnotations = self.mapView.getMapViewAnnotations()
        if mapViewAnnotations.isEmpty {
            return 0;
        }
        return (mapViewAnnotations.last??.zIndex ?? 0) + 1
    }

    private func isAnnotationInFront(zIndex: Double) -> Bool {
        return (self.mapView.getMapViewAnnotations().last??.zIndex ?? 0) == zIndex
    }

    private func getPinAnnotationView(annotation: FlutterAnnotation, id: String) -> MKPinAnnotationView {
        var pinAnnotationView: MKPinAnnotationView
        if #available(iOS 11.0, *) {
            self.mapView.register(MKPinAnnotationView.self, forAnnotationViewWithReuseIdentifier: id)
            if let dequeuedView = self.mapView.dequeueReusableAnnotationView(withIdentifier: id, for: annotation) as? MKPinAnnotationView {
                pinAnnotationView = dequeuedView
            } else {
                pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: id)
            }
        } else {
            pinAnnotationView = MKPinAnnotationView.init(annotation: annotation, reuseIdentifier: id)
        }
        pinAnnotationView.layer.zPosition = annotation.zIndex

        if let hueColor: Double = annotation.icon.hueColor {
            let alpha = annotation.alpha ?? 1.0
            var tintColor = UIColor.init(hue: hueColor, saturation: 1, brightness: 1, alpha: alpha)
            
            // Apply desaturation if needed
            if annotation.desaturated {
                tintColor = desaturateColor(tintColor)
            }
            
            pinAnnotationView.pinTintColor = tintColor
        }
        
        // Add badge if present
        addBadgeToAnnotationView(pinAnnotationView, annotation: annotation)

        return pinAnnotationView
    }

    @available(iOS 11.0, *)
    private func getMarkerAnnotationView(annotation: FlutterAnnotation, id: String) -> FlutterMarkerAnnotationView {
        self.mapView.register(FlutterMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: id)
        let markerAnnotationView: FlutterMarkerAnnotationView
        if let dequeuedView = self.mapView.dequeueReusableAnnotationView(withIdentifier: id, for: annotation) as? FlutterMarkerAnnotationView {
            markerAnnotationView = dequeuedView
        } else {
            markerAnnotationView = FlutterMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
        }

        markerAnnotationView.stickyZPosition = annotation.zIndex
        markerAnnotationView.displayPriority = annotation.zIndex > 2 ? .required : .defaultHigh

        // Determine the tint color to use
        var tintColor: UIColor?
        if let hueColor: Double = annotation.icon.hueColor {
            let alpha = annotation.alpha ?? 1.0
            tintColor = UIColor.init(hue: hueColor, saturation: 1, brightness: 1, alpha: alpha)
            
            // Apply desaturation if needed
            if annotation.desaturated {
                tintColor = desaturateColor(tintColor!)
            }
        }

        if let systemImageName = annotation.systemImageName {
            var image = UIImage(systemName: systemImageName)
            let padding: CGFloat = 4.0

            // Apply tint color to the system image if available
            if let tintColor = tintColor {
                image = image?.withTintColor(tintColor, renderingMode: .alwaysOriginal)
            }

            let paddedImage = image?.withAlignmentRectInsets(UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding))
            markerAnnotationView.glyphImage = paddedImage
        }

        // Set the marker tint color (used for non-system icon markers)
        if let tintColor = tintColor {
            markerAnnotationView.markerTintColor = tintColor
        }
        
        // Add badge if present
        addBadgeToAnnotationView(markerAnnotationView, annotation: annotation)

        return markerAnnotationView
    }

    private func getCustomAnnotationView(annotation: FlutterAnnotation, id: String) -> FlutterAnnotationView {
        let annotationView: FlutterAnnotationView
        if #available(iOS 11.0, *) {
            self.mapView.register(FlutterAnnotationView.self, forAnnotationViewWithReuseIdentifier: id)
            if let dequeuedView = self.mapView.dequeueReusableAnnotationView(withIdentifier: id, for: annotation) as? FlutterAnnotationView {
                annotationView = dequeuedView
            } else {
                annotationView = FlutterAnnotationView(annotation: annotation, reuseIdentifier: id)
            }
        } else {
            annotationView = FlutterAnnotationView(annotation: annotation, reuseIdentifier: id)
        }
        
        // Apply desaturation to custom image if needed
        if annotation.desaturated {
            annotationView.image = desaturateImage(annotation.icon.image)
        } else {
            annotationView.image = annotation.icon.image
        }
        
        annotationView.stickyZPosition = annotation.zIndex
        
        // Add badge if present
        addBadgeToAnnotationView(annotationView, annotation: annotation)
        
        return annotationView
    }

    private func getInfoWindowXOffset(annotationView: MKAnnotationView, annotation: FlutterAnnotation) -> CGFloat {
        if annotation.icon.iconType == .PIN {
            return annotationView.frame.origin.x - (annotationView.frame.origin.x * CGFloat(annotation.calloutOffset.x))
        }
        return annotationView.frame.origin.x + (annotationView.frame.width * CGFloat(annotation.calloutOffset.x))
    }

    private func getInfoWindowYOffset(annotationView: MKAnnotationView, annotation: FlutterAnnotation) -> CGFloat {
        return annotationView.frame.height * CGFloat(annotation.calloutOffset.y)
    }

    private func moveToFront(annotation: FlutterAnnotation) {
        let id: String = annotation.id
        annotation.zIndex = self.getNextAnnotationZIndex()
        channel.invokeMethod("annotation#onZIndexChanged", arguments: ["annotationId": id, "zIndex": annotation.zIndex])
        self.addAnnotation(annotation: annotation)
        self.selectAnnotation(with: id)
    }

    // MARK: - Desaturation Helpers
    
    private func desaturateColor(_ color: UIColor) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Get HSB values
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        // Return grayscale version (saturation = 0)
        return UIColor(hue: hue, saturation: 0, brightness: brightness, alpha: alpha)
    }
    
    private func desaturateImage(_ image: UIImage?) -> UIImage? {
        guard let image = image, let ciImage = CIImage(image: image) else {
            return image
        }
        
        // Apply grayscale filter
        let filter = CIFilter(name: "CIPhotoEffectMono")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let outputImage = filter?.outputImage else {
            return image
        }
        
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    // MARK: - Badge Helpers
    
    private static let badgeViewTag = 99999
    
    private func removeBadgeFromAnnotationView(_ annotationView: MKAnnotationView) {
        if let badgeView = annotationView.viewWithTag(AppleMapController.badgeViewTag) {
            badgeView.removeFromSuperview()
        }
    }
    
    private func addBadgeToAnnotationView(_ annotationView: MKAnnotationView, annotation: FlutterAnnotation) {
        // Return early if no badge system image name is provided
        guard let systemImageName = annotation.badgeSystemImageName else {
            return
        }
        
        // Remove any existing badge first
        removeBadgeFromAnnotationView(annotationView)
        
        // Calculate badge size based on annotation view size and ratio
        let annotationSize = max(annotationView.frame.size.width, annotationView.frame.size.height)
        let badgeSize = annotationSize * CGFloat(annotation.badgeSizeRatio)
        
        // Create badge container view
        let badgeContainer = UIView(frame: CGRect(x: 0, y: 0, width: badgeSize, height: badgeSize))
        badgeContainer.tag = AppleMapController.badgeViewTag
        badgeContainer.isUserInteractionEnabled = false
        
        // Set background color (default to white if not specified)
        let backgroundColor = annotation.badgeBackgroundColor ?? .white
        badgeContainer.backgroundColor = backgroundColor
        
        // Set corner radius based on badge shape
        if annotation.badgeShape == "circle" {
            badgeContainer.layer.cornerRadius = badgeSize / 2
        } else {
            badgeContainer.layer.cornerRadius = badgeSize / 5
        }
        badgeContainer.clipsToBounds = true
        
        // Set alpha
        badgeContainer.alpha = CGFloat(annotation.badgeAlpha)
        
        // Create SF Symbol image
        if let systemImage = UIImage(systemName: systemImageName) {
            let imageView = UIImageView(image: systemImage)
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = .black
            
            // Size the icon to be about 60% of badge size for good visual balance
            let iconSize = badgeSize * 0.6
            let iconFrame = CGRect(
                x: (badgeSize - iconSize) / 2,
                y: (badgeSize - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )
            imageView.frame = iconFrame
            badgeContainer.addSubview(imageView)
        }
        
        // Position badge using offset
        // Offset is in normalized coordinates where (0,0) is top-left, (1,1) is bottom-right
        let xPosition = annotationView.bounds.width * CGFloat(annotation.badgeOffset.x) - (badgeSize / 2)
        let yPosition = annotationView.bounds.height * CGFloat(annotation.badgeOffset.y) - (badgeSize / 2)
        badgeContainer.frame.origin = CGPoint(x: xPosition, y: yPosition)
        
        // Add border for better visibility
        badgeContainer.layer.borderWidth = 1.0
        badgeContainer.layer.borderColor = UIColor.black.withAlphaComponent(0.2).cgColor
        
        // Add the badge to the annotation view
        annotationView.addSubview(badgeContainer)
    }
    
    private func getRegionForCluster(_ cluster: MKClusterAnnotation) -> MKCoordinateRegion {
        // Handle edge case of empty cluster
        guard !cluster.memberAnnotations.isEmpty else {
            // Return a default region centered on (0,0) with minimal span
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }

        var minLat = Double.infinity
        var maxLat = -Double.infinity
        var minLng = Double.infinity
        var maxLng = -Double.infinity
        var hasValidCoordinates = false

        // Find the bounding box for all annotations in the cluster
        for annotation in cluster.memberAnnotations {
            let coordinate = annotation.coordinate

            // Validate coordinates are not NaN or infinite
            guard coordinate.latitude.isFinite && coordinate.longitude.isFinite &&
                  coordinate.latitude >= -90 && coordinate.latitude <= 90 &&
                  coordinate.longitude >= -180 && coordinate.longitude <= 180 else {
                continue
            }

            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLng = min(minLng, coordinate.longitude)
            maxLng = max(maxLng, coordinate.longitude)
            hasValidCoordinates = true
        }

        // Handle case where no valid coordinates were found
        guard hasValidCoordinates else {
            // Return a default region centered on (0,0) with minimal span
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }

        // Handle case where all coordinates are the same (single point)
        if minLat == maxLat && minLng == maxLng {
            // Check current zoom level to force unclustering when zoomed in
            let currentZoom = self.mapView.calculatedZoomLevel
            
            // If already zoomed in significantly (>= 18), force maximum zoom to uncluster
            if currentZoom >= 18 {
                return MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: minLat, longitude: minLng),
                    span: MKCoordinateSpan(latitudeDelta: 0.0001, longitudeDelta: 0.0001)
                )
            }
            
            // Otherwise, zoom in progressively
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: minLat, longitude: minLng),
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
        }

        // Create a region that encompasses all points
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )

        // Add some padding to the region - reduced from 1.5 to 1.2 for better zoom
        let latDelta = (maxLat - minLat) * 1.2 // 20% padding
        let lngDelta = (maxLng - minLng) * 1.2 // 20% padding

        // If the cluster has only a few annotations, zoom in more aggressively
        let zoomFactor: Double
        if cluster.memberAnnotations.count <= 3 {
            zoomFactor = 0.5 // Zoom in more for small clusters
        } else if cluster.memberAnnotations.count <= 10 {
            zoomFactor = 0.7 // Medium zoom for medium clusters
        } else {
            zoomFactor = 1.0 // Standard zoom for large clusters
        }

        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: max(latDelta * zoomFactor, 0.005), // Reduced minimum zoom level for better detail
                longitudeDelta: max(lngDelta * zoomFactor, 0.005)
            )
        )
    }
}

class InfoWindowTapGestureRecognizer: UITapGestureRecognizer {
    var annotationView: UIView?
    var annotationId: String?
}
