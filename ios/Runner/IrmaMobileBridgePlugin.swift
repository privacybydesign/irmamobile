import Flutter
import Foundation

class IrmaMobileBridgePlugin: NSObject, FlutterPlugin {
  var registrar: FlutterPluginRegistrar?
  var channel: FlutterMethodChannel?
  var initialURL: String?
  var nativeError: String?
  var appReady = false

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "irma.app/irma_mobile_bridge", binaryMessenger: registrar.messenger())
    let instance = IrmaMobileBridgePlugin()
    instance.registrar = registrar
    instance.channel = channel

    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addApplicationDelegate(instance)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    NSLog("Hi from handle function")

    NSLog("handling \(call.method)")

    debugLog("handling \(call.method)")

    if nativeError != nil {
      channel?.invokeMethod("ErrorEvent", arguments: nativeError)
      return
    }

    if call.method == "AppReadyEvent" {
      appReady = true
      if let initialURL = initialURL {
        channel?.invokeMethod(
          "HandleURLEvent", arguments: "{\"isInitialURL\": true, \"url\": \"\(initialURL)\"}")
      }
    }

    IrmagobridgeDispatchFromNative(call.method, call.arguments as? String)
    result(nil)
  }

  func debugLog(_ message: String) {
    #if DEBUG
      NSLog("[IrmaMobileBridgePlugin] \(message)")
    #endif
  }

  func dispatchFromGo(_ name: String, payload: String) {

    NSLog("DISPATCH FROM GO ")

    debugLog("dispatching \(name)(\(payload))")
    channel?.invokeMethod(name, arguments: payload)
  }
}

extension IrmaMobileBridgePlugin: FlutterApplicationLifeCycleDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let url = launchOptions?[.url] as? URL {
      initialURL = url.absoluteString
    }
    return true
  }

  func application(
    _ application: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    let urlStr = url.absoluteString
    if appReady {
      channel?.invokeMethod("HandleURLEvent", arguments: "{\"url\": \"\(urlStr)\"}")
    } else {
      initialURL = urlStr
    }
    return true
  }

  func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([Any]?) -> Void
  ) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL
    {
      let urlStr = url.absoluteString
      if appReady {
        channel?.invokeMethod("HandleURLEvent", arguments: "{\"url\": \"\(urlStr)\"}")
      } else {
        initialURL = urlStr
      }
      return true
    }
    return false
  }
}
