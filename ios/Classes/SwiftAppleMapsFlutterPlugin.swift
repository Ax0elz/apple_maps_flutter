import Flutter
import UIKit

public class SwiftAppleMapsFlutterPlugin: NSObject, FlutterPlugin {
    var factory: AppleMapViewFactory
    public init(with registrar: FlutterPluginRegistrar) {
        print("SwiftAppleMapsFlutterPlugin: init called")
        factory = AppleMapViewFactory(withRegistrar: registrar)
        print("SwiftAppleMapsFlutterPlugin: AppleMapViewFactory created")
        registrar.register(factory, withId: "apple_maps_plugin.luisthein.de/apple_maps", gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyWaitUntilTouchesEnded)
        print("SwiftAppleMapsFlutterPlugin: factory registered with id: apple_maps_plugin.luisthein.de/apple_maps")
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        registrar.addApplicationDelegate(SwiftAppleMapsFlutterPlugin(with: registrar))
    }
}
