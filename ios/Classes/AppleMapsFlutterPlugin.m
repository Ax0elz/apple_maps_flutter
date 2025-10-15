#import "AppleMapsFlutterPlugin.h"
#import <apple_maps_flutter/apple_maps_flutter-Swift.h>

@implementation AppleMapsFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  NSLog(@"🔌 AppleMapsFlutterPlugin: Objective-C registerWithRegistrar called");
  [SwiftAppleMapsFlutterPlugin registerWithRegistrar:registrar];
  NSLog(@"🔌 AppleMapsFlutterPlugin: SwiftAppleMapsFlutterPlugin registerWithRegistrar completed");
}
@end
