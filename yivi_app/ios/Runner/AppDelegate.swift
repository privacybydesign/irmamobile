import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Ignore SIGINT signals that might emerge from irmago, c.f. irmago/internal/disable_sigpipe/disable_sigpipe.go
        signal(SIGINT, SIG_IGN)

        var flutter_native_splash = 1
        UIApplication.shared.isStatusBarHidden = false

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Under the UIScene lifecycle the implicit engine is created by the scene, after
    // didFinishLaunchingWithOptions has already returned, so plugins are registered here
    // against that engine's registry instead of against the app delegate.
    func didInitializeImplicitFlutterEngine(_ engineBridge: any FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    }
}
