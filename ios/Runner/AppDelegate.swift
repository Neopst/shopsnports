import Flutter
import UIKit
import Flutter
import UIKit

private var initialLink: String? = nil

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Capture any URL used to launch the app
    if let url = launchOptions?[.url] as? URL {
      initialLink = url.absoluteString
    }

    // Expose a MethodChannel for Dart to request the initial link
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "shopsnports/deeplink", binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { (call, result) in
        if call.method == "getInitialLink" {
          result(initialLink)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Capture incoming URLs while the app is running or when opened via URL
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    initialLink = url.absoluteString
    return super.application(app, open: url, options: options)
  }
}
