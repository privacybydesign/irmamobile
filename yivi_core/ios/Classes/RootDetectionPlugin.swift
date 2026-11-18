// Jailbreak detection, vendored from https://github.com/w3connext/jailbreak_root_detection
// (MIT, Copyright (c) 2023 w3connext), whose iOS check in turn came from
// https://github.com/developerinsider/IsJailBroken (MIT, Copyright (c) 2020 Developer Insider).
//
// Only the jailbreak check the app actually shows a warning for. Left out: the
// IOSSecuritySuite checks upstream ORs in on top of these, including amIProxied(),
// which flags any user on a VPN.

import Flutter
import UIKit

public class RootDetectionPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "yivi.app/root_detection", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(RootDetectionPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isDeviceRooted":
      result(RootDetectionPlugin.isJailBroken())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  static func isJailBroken() -> Bool {
    #if targetEnvironment(simulator)
      // A simulator can read and write outside the sandbox, so every check below fires.
      return false
    #else
      return hasCydiaInstalled() || suspiciousPathExists() || canEditSystemFiles()
    #endif
  }

  private static func hasCydiaInstalled() -> Bool {
    guard let cydia = URL(string: "cydia://") else { return false }
    return UIApplication.shared.canOpenURL(cydia)
  }

  private static func suspiciousPathExists() -> Bool {
    return suspiciousPaths.contains { FileManager.default.fileExists(atPath: $0) }
  }

  /// Writing outside the app sandbox only succeeds on a jailbroken device.
  private static func canEditSystemFiles() -> Bool {
    let path = "/private/\(UUID().uuidString)"
    do {
      try "".write(toFile: path, atomically: true, encoding: .utf8)
      try? FileManager.default.removeItem(atPath: path)
      return true
    } catch {
      return false
    }
  }

  private static let suspiciousPaths = [
    "/Applications/Cydia.app",
    "/Applications/Sileo.app",
    "/Applications/Zebra.app",
    "/Applications/blackra1n.app",
    "/Applications/FakeCarrier.app",
    "/Applications/Icy.app",
    "/Applications/IntelliScreen.app",
    "/Applications/MxTube.app",
    "/Applications/RockApp.app",
    "/Applications/SBSettings.app",
    "/Applications/WinterBoard.app",
    "/Applications/Snoop-itConfig.app",
    "/Applications/checkra1n.app",
    "/Library/MobileSubstrate/MobileSubstrate.dylib",
    "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
    "/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
    "/Library/Frameworks/CydiaSubstrate.framework",
    "/Library/PreferenceBundles",
    "/Library/PreferenceLoader/Preferences",
    "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
    "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
    "/bin/bash",
    "/bin/sh",
    "/bin/su",
    "/etc/apt",
    "/etc/apt/sources.list.d/cydia.list",
    "/etc/ssh/sshd_config",
    "/private/etc/apt",
    "/private/etc/dpkg/origins/debian",
    "/private/etc/ssh/sshd_config",
    "/private/var/lib/apt",
    "/private/var/lib/cydia",
    "/private/var/lib/dpkg/info",
    "/private/var/root/Media/Cydia",
    "/private/var/stash",
    "/private/var/tmp/cydia.log",
    "/usr/bin/checkra1n",
    "/usr/bin/cycript",
    "/usr/bin/ssh",
    "/usr/bin/sshd",
    "/usr/lib/libcycript.dylib",
    "/usr/libexec/cydia",
    "/usr/libexec/sftp-server",
    "/usr/libexec/ssh-keysign",
    "/usr/local/bin/cycript",
    "/usr/sbin/frida-server",
    "/usr/sbin/sshd",
    "/var/binpack",
    "/var/cache/apt",
    "/var/checkra1n.dmg",
    "/var/lib/cydia",
    "/var/lib/dpkg/info/checkra1n.list",
  ]
}
