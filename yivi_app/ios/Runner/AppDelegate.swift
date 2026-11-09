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

    // Refuse custom keyboard extensions, so that no third-party keyboard sees what the
    // user types: the MRZ fields (from which the passport chip's access keys are
    // derived), e-mail addresses, phone numbers and codes. The system keyboard is used
    // instead. The PIN is entered on an in-app keypad and was never typed on a keyboard.
    func application(
        _ application: UIApplication,
        shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier
    ) -> Bool {
        return extensionPointIdentifier != .keyboard
    }

    // Under the UIScene lifecycle the implicit engine is created by the scene, after
    // didFinishLaunchingWithOptions has already returned, so plugins are registered here
    // against that engine's registry instead of against the app delegate.
    func didInitializeImplicitFlutterEngine(_ engineBridge: any FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    }
}
