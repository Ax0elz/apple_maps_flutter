//
//  AppleMapsViewFactory.swift
//  apple_maps_flutter
//
//  Created by Luis Thein on 01.07.21.
//

import Foundation

public class AppleMapViewFactory: NSObject, FlutterPlatformViewFactory {
    
    var registrar: FlutterPluginRegistrar
    
    public init(withRegistrar registrar: FlutterPluginRegistrar){
        self.registrar = registrar
        super.init()
    }
    
    public func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        NSLog("🟢 AppleMapViewFactory: create called with frame: \(frame), viewId: \(viewId)")
        let argsDictionary =  args as! Dictionary<String, Any>
        NSLog("🟢 AppleMapViewFactory: argsDictionary: \(argsDictionary)")

        let controller = AppleMapController(withFrame: frame, withRegistrar: registrar, withargs: argsDictionary, withId: viewId)
        NSLog("🟢 AppleMapViewFactory: AppleMapController created")
        return controller
    }
    
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec(readerWriter: FlutterStandardReaderWriter())
    }
}
