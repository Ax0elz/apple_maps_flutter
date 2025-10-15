import Flutter
import UIKit

public class SwiftAppleMapsFlutterPlugin: NSObject, FlutterPlugin {
    var factory: AppleMapViewFactory
    public init(with registrar: FlutterPluginRegistrar) {
        NSLog("🔵 SwiftAppleMapsFlutterPlugin: init called")
        factory = AppleMapViewFactory(withRegistrar: registrar)
        NSLog("🔵 SwiftAppleMapsFlutterPlugin: AppleMapViewFactory created")
        registrar.register(factory, withId: "apple_maps_plugin.luisthein.de/apple_maps", gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyWaitUntilTouchesEnded)
        NSLog("🔵 SwiftAppleMapsFlutterPlugin: factory registered with id: apple_maps_plugin.luisthein.de/apple_maps")
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        NSLog("🔵 SwiftAppleMapsFlutterPlugin: register() static method called")
        registrar.addApplicationDelegate(SwiftAppleMapsFlutterPlugin(with: registrar))
        NSLog("🔵 SwiftAppleMapsFlutterPlugin: addApplicationDelegate completed")
    }
}
