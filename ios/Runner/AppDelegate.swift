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

    var flutter_native_splash = 1
    UIApplication.shared.isStatusBarHidden = false

    GeneratedPluginRegistrant.register(with: self)
    IrmaMobileBridgePlugin.register(
        with: self.registrar(forPlugin: "IrmaMobileBridgePlugin")
    )
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidEnterBackground(_ application: UIApplication) {
    super.applicationDidEnterBackground(application)

    let blankViewController = UIViewController()
    blankViewController.view.backgroundColor = UIColor.black

    // Pass NO for the animated parameter. Any animation will not complete
    // before the snapshot is taken.
    window.rootViewController?.present(blankViewController, animated: false)
  }

  override func applicationWillEnterForeground(_ application: UIApplication) {
    window.rootViewController?.dismiss(animated: false)

    super.applicationWillEnterForeground(application)
  }
}
