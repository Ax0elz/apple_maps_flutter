# Apple Maps Flutter Debug Guide

## Debug Prints Added

I've added comprehensive debug print statements throughout both Flutter and iOS native code to help diagnose why the map isn't showing up.

## Expected Print Sequence

If everything is working correctly, you should see this sequence in your logs:

### 1. App Launch (iOS Side)
```
📱 AppDelegate: didFinishLaunchingWithOptions called
📱 AppDelegate: GeneratedPluginRegistrant.register completed
🔌 AppleMapsFlutterPlugin: Objective-C registerWithRegistrar called
SwiftAppleMapsFlutterPlugin: init called
SwiftAppleMapsFlutterPlugin: AppleMapViewFactory created
SwiftAppleMapsFlutterPlugin: factory registered with id: apple_maps_plugin.luisthein.de/apple_maps
🔌 AppleMapsFlutterPlugin: SwiftAppleMapsFlutterPlugin registerWithRegistrar completed
📱 AppDelegate: super.application returned: true
🚀 Starting Apple Maps Flutter Example App
```

### 2. Map Page Navigation (Flutter Side)
```
🎯 MapUiBodyState: initState() called
🎯 MapUiBodyState: build() called
🗺️ AppleMap: initState() called
🗺️ AppleMap: initState() completed - annotations: 0, polylines: 0
🗺️ AppleMap: build() called - platform: TargetPlatform.iOS
🗺️ AppleMap: creationParams: {...}
🗺️ AppleMap: Creating UiKitView for iOS
```

### 3. Native Platform View Creation (iOS Side - **CRITICAL MISSING PART**)
```
AppleMapViewFactory: create called with frame: ..., viewId: ...
AppleMapViewFactory: argsDictionary: {...}
AppleMapController: init called with frame: ...
AppleMapController: options parsed: {...}
AppleMapController: initialCameraPosition: {...}
AppleMapController: FlutterMethodChannel created with id: ...
FlutterMapView: convenience init called with options: ..., initialCameraPosition: ...
FlutterMapView: MKMapView init completed with frame: ...
FlutterMapView: convenience init completed
AppleMapController: FlutterMapView created
AppleMapController: contentView set to mapView
AppleMapController: super.init() completed
AppleMapController: delegate set
AppleMapController: method call handlers set
AppleMapViewFactory: AppleMapController created
AppleMapController: view() called, returning contentView: ...
```

### 4. Map Layout and Display (iOS Side)
```
FlutterMapView: didMoveToSuperview called, superview: ..., initialCameraPosition: ...
FlutterMapView: applying initial camera position: {...}
FlutterMapView: initial camera position applied
FlutterMapView: initialCameraPosition cleared
FlutterMapView: layoutSubviews called, bounds: ..., oldBounds: ...
FlutterMapView: bounds changed, applying options and camera
FlutterMapView: options interpreted
FlutterMapView: first layout, setting camera position
FlutterMapView: camera set with altitude
FlutterMapView: mapContainerView found: true
```

### 5. Map Ready (Flutter Side)
```
🗺️ AppleMap: onPlatformViewCreated() called with id: ...
🎮 AppleMapController: init() called with id: ...
🎮 AppleMapController: Initial camera position: ...
🎮 AppleMapController: MethodChannel created: ...
🎮 AppleMapController: Controller created successfully
🗺️ AppleMap: Controller initialized successfully
✅ MapUiBodyState: onMapCreated() callback received - map is ready!
```

## Current Issue Analysis

Based on your logs, you're seeing:
- ✅ Flutter side creating UiKitView
- ❌ **MISSING**: All iOS native side prints starting from `AppleMapViewFactory: create called`

This means the platform view factory's `create` method is **never being called**, which indicates:

### Possible Causes:

1. **Plugin Not Registered Properly**
   - Check if you see the plugin registration prints at app launch
   - Look for: `🔌 AppleMapsFlutterPlugin: Objective-C registerWithRegistrar called`

2. **View Type Mismatch**
   - Flutter is requesting: `'apple_maps_plugin.luisthein.de/apple_maps'`
   - iOS is registering with the same ID
   - Verify these match exactly

3. **Scene Delegate Issues**
   - The app uses UISceneSession lifecycle
   - Scene-based apps can have different initialization order

4. **Build/Pod Issues**
   - Clean build folders
   - Run `pod install` again
   - Check Xcode for compilation errors

## Diagnostic Steps

### Step 1: Check Plugin Registration
Look for these prints at app launch:
```
📱 AppDelegate: didFinishLaunchingWithOptions called
🔌 AppleMapsFlutterPlugin: Objective-C registerWithRegistrar called
SwiftAppleMapsFlutterPlugin: init called
```

If you **DON'T** see these, the plugin isn't being registered at all.

### Step 2: Check for iOS Errors
In Xcode, look at the native console (not just Flutter logs) for:
- Swift compilation errors
- Runtime exceptions
- Missing framework errors

### Step 3: Verify App is Running on iOS
Make sure you see:
```
🗺️ AppleMap: build() called - platform: TargetPlatform.iOS
```
If it says a different platform, that's the issue.

### Step 4: Check for Platform View Creation Errors
Look for any errors between:
- Flutter: `🗺️ AppleMap: Creating UiKitView for iOS`
- iOS: `AppleMapViewFactory: create called`

## What To Do Next

1. **Run the app again** and capture the complete logs from app launch
2. **Check Xcode console** for native iOS logs (separate from Flutter logs)
3. **Look for these specific missing prints**:
   - Plugin registration (at app launch)
   - Factory create call (when navigating to map page)
4. **Share the complete log** including:
   - App launch sequence
   - Navigation to map page
   - Any error messages

## How to See iOS Native Logs

If you're running from Flutter CLI:
- iOS native `print()` statements should appear as `flutter: ...`
- iOS `NSLog()` statements appear without the `flutter:` prefix

If you're running from Xcode:
- Open the app in Xcode
- View → Debug Area → Activate Console
- You'll see both Flutter and native iOS logs

## Quick Fixes to Try

1. **Clean and rebuild**:
   ```bash
   cd example
   flutter clean
   cd ios
   pod install
   cd ..
   flutter build ios
   ```

2. **Check Info.plist** for required keys:
   - `NSLocationWhenInUseUsageDescription` (required for myLocationEnabled)

3. **Verify minimum iOS version** in `ios/Podfile`:
   - Should be iOS 9.0 or higher

4. **Check for SceneDelegate** conflicts:
   - The app uses UISceneSession
   - Make sure it's properly configured

