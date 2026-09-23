import Flutter
import UIKit

/// Holds the screen on for the duration of a flow, via `isIdleTimerDisabled`.
///
/// The Android counterpart is `ScreenAwakePlugin.java`, which explains why the
/// app wants this: a ZK age proof is seconds of CPU that the user spends
/// watching a progress indicator without touching the screen, and letting the
/// display time out costs both the flow and, on Android, the big cores.
///
/// Holds are counted rather than a flag, because sessions nest: a disclosure can
/// start an issuance session on top of itself, and the inner one ending must not
/// release the outer one's hold.
public class ScreenAwakePlugin: NSObject, FlutterPlugin {

    /// How many flows currently need the screen held on.
    private static var holdCount = 0

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "screen_awake", binaryMessenger: registrar.messenger())
        let instance = ScreenAwakePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "keepScreenOn":
            ScreenAwakePlugin.holdCount += 1
            ScreenAwakePlugin.applyIdleTimer()
            result(nil)
        case "allowScreenOff":
            ScreenAwakePlugin.holdCount = max(0, ScreenAwakePlugin.holdCount - 1)
            ScreenAwakePlugin.applyIdleTimer()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private static func applyIdleTimer() {
        // UIApplication is main-thread only; method calls arrive on it.
        UIApplication.shared.isIdleTimerDisabled = holdCount > 0
    }
}
