//
//  AnnotationIcon.swift
//  apple_maps_flutter
//
//  Created by Luis Thein on 07.03.20.
//

import Foundation

enum IconType {
    case PIN, MARKER, CUSTOM_FROM_ASSET, CUSTOM_FROM_BYTES
}

class AnnotationIcon: Equatable {
    
    var iconType: IconType
    var id: String
    var image: UIImage?
    var hueColor: Double?
    var desaturated: Bool = false
    
    public init(id: String, iconType: IconType) {
        self.iconType = iconType
        self.id = id
    }
    
    public init(id: String, iconType: IconType, hueColor: Double) {
        self.iconType = iconType
        self.id = id
        self.hueColor = hueColor
    }
    
    public init(withAsset name: String, id: String, iconScale: CGFloat? = 1.0, desaturated: Bool = false) {
        self.iconType = .CUSTOM_FROM_ASSET
        self.id = id
        self.desaturated = desaturated
        if let uiImage: UIImage =  UIImage.init(named: name) {
            let scaledImage = self.scaleImage(image: uiImage, scale: iconScale!)
            self.image = desaturated ? self.desaturateImage(scaledImage) : scaledImage
        }
    }
    
    public init(fromBytes bytes: FlutterStandardTypedData, id: String, desaturated: Bool = false) {
        // Initialize all stored properties first
        self.iconType = .CUSTOM_FROM_BYTES
        self.id = id
        self.desaturated = desaturated
        
        // Now we can call instance methods on self
        let screenScale = UIScreen.main.scale
        let image = UIImage.init(data: bytes.data, scale: screenScale)
        self.image = desaturated ? self.desaturateImage(image) : image
    }
    
    public convenience init() {
        self.init(id: "", iconType: .PIN)
    }
    
    private func scaleImage(image: UIImage, scale: CGFloat) -> UIImage {
        guard let cgImage = image.cgImage else {
            return image
        }
        // Only scale if the scale factor is significantly different from 1.0
        guard abs(scale - 1.0) > 0.01 else {
            return image
        }
        return UIImage.init(cgImage: cgImage, scale: 4.0, orientation: image.imageOrientation)
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
    
    static func == (lhs: AnnotationIcon, rhs: AnnotationIcon) -> Bool {
        return lhs.iconType == rhs.iconType && lhs.id == rhs.id && lhs.image == rhs.image
    }
    
    static func != (lhs: AnnotationIcon, rhs: AnnotationIcon) -> Bool {
        return !(lhs == rhs)
    }
}
