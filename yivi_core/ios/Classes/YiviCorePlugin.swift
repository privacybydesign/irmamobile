import Flutter
import UIKit

public class YiviCorePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    registerIrmaClient(with: registrar)

    PrivacyScreenPlugin.register(with: registrar)
  }

  static func registerIrmaClient(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "irma.app/irma_mobile_bridge", binaryMessenger: registrar.messenger())
    let irmaclient = IrmaMobileBridgePlugin(channel: channel)

    registrar.addMethodCallDelegate(irmaclient, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
  }
}
