import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MindCareOnboardingStore")
    let channel = FlutterMethodChannel(
      name: "mindcare/onboarding",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      let defaults = UserDefaults.standard
      switch call.method {
      case "hasCompleted":
        result(defaults.bool(forKey: "mindcare.onboarding.completed"))
      case "markCompleted":
        defaults.set(true, forKey: "mindcare.onboarding.completed")
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
