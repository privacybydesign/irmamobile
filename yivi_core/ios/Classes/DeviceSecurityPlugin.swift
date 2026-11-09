import Flutter
import LocalAuthentication
import UIKit

/// Tells the app whether the device has a passcode set (which Face ID and Touch ID
/// also require). iOS has no public link to the passcode settings, so unlike on
/// Android there is no openSecuritySettings.
public class DeviceSecurityPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "yivi.app/device_security", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(DeviceSecurityPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isDeviceSecure":
      result(DeviceSecurityPlugin.isDeviceSecure())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  static func isDeviceSecure() -> Bool {
    #if targetEnvironment(simulator)
      // A simulator cannot have a passcode.
      return true
    #else
      // deviceOwnerAuthentication succeeds with biometrics or the passcode, so it is
      // available exactly when a passcode is set (LAError.passcodeNotSet otherwise).
      var error: NSError?
      return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    #endif
  }
}
