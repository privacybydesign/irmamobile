import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
  ) -> Bool {
    // Ignore SIGINT signals that might emerge from irmago, c.f. irmago/internal/disable_sigpipe/disable_sigpipe.go
    signal(SIGINT, SIG_IGN)

    GeneratedPluginRegistrant.register(with: self)
    IrmaMobileBridgePlugin.register(
        with: self.registrar(forPlugin: "IrmaMobileBridgePlugin")
    )
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
