import Darwin
import Flutter
import MachO
import UIKit

/// Reports signals about the environment the app runs in: an attached debugger, a
/// dynamic instrumentation tool, a tweak-injection framework, or the simulator. The
/// plugin only reports; the Dart side decides how to react, and only does so in
/// release builds.
///
/// These are local, best-effort checks. Someone who controls the device can bypass
/// them, so they raise the bar without replacing attestation by a backend.
public class AppIntegrityPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "yivi.app/app_integrity", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(AppIntegrityPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "check":
      result(AppIntegrityPlugin.check())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  static func check() -> [String: Bool] {
    let images = loadedImageNames()
    var debuggable = false
    #if DEBUG
      debuggable = true
    #endif
    var simulator = false
    #if targetEnvironment(simulator)
      simulator = true
    #endif
    return [
      "debuggable": debuggable,
      "debugger": isDebuggerAttached(),
      "instrumentation": containsAny(images, instrumentationImages),
      "hookingFramework": containsAny(images, hookingFrameworkImages),
      "emulator": simulator,
      // iOS has no app-cloning containers like Android's.
      "virtualized": false,
    ]
  }

  /// Whether a debugger traces this process: the kernel sets P_TRACED on it.
  static func isDebuggerAttached() -> Bool {
    var info = kinfo_proc()
    var size = MemoryLayout<kinfo_proc>.stride
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    guard sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0) == 0 else { return false }
    return (info.kp_proc.p_flag & P_TRACED) != 0
  }

  /// The lowercased paths of every image (the executable, frameworks and injected
  /// libraries) loaded into the process.
  static func loadedImageNames() -> [String] {
    var names: [String] = []
    for index in 0..<_dyld_image_count() {
      if let name = _dyld_get_image_name(index) {
        names.append(String(cString: name).lowercased())
      }
    }
    return names
  }

  static func containsAny(_ images: [String], _ needles: [String]) -> Bool {
    return images.contains { image in needles.contains { image.contains($0) } }
  }

  /// Loaded by Frida and tools built on it (objection), by Cycript, and by tools that
  /// switch off TLS checks or inspect the UI of a running app.
  static let instrumentationImages = [
    "frida", "cynject", "libcycript", "sslkillswitch", "libobjection", "flexloader",
  ]

  /// Frameworks that let tweaks change any app on a jailbroken device. Unlike the
  /// tools above they are a property of the device, not an attack in progress.
  static let hookingFrameworkImages = [
    "mobilesubstrate", "substrateloader", "substrateinserter", "libsubstitute", "substitute-loader",
    "libhooker", "ellekit", "tweakinject",
  ]
}
