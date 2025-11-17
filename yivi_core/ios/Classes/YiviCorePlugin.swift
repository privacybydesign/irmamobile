import Flutter
import UIKit

public class YiviCorePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    PrivacyScreenPlugin.register(with: registrar)
    IrmaMobileBridgePlugin.register(with: registrar)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {}
}
