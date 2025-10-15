import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    print("📱 AppDelegate: didFinishLaunchingWithOptions called")
    GeneratedPluginRegistrant.register(with: self)
    print("📱 AppDelegate: GeneratedPluginRegistrant.register completed")
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    print("📱 AppDelegate: super.application returned: \(result)")
    return result
  }
  
  // MARK: - UISceneSession Lifecycle
  
  override func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }
  
  override func application(
    _ application: UIApplication,
    didDiscardSceneSessions sceneSessions: Set<UISceneSession>
  ) {
    // Called when the user discards a scene session.
  }
}
