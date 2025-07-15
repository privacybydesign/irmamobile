import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Ignore SIGINT signals that might emerge from irmago, c.f. irmago/internal/disable_sigpipe/disable_sigpipe.go
        signal(SIGINT, SIG_IGN)

        var flutter_native_splash = 1
        UIApplication.shared.isStatusBarHidden = false

        GeneratedPluginRegistrant.register(with: self)
        IrmaMobileBridgePlugin.register(
            with: self.registrar(forPlugin: "IrmaMobileBridgePlugin")!
        )
        PrivacyScreenPlugin.register(with: self.registrar(forPlugin: "PrivacyScreenPlugin")!)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
