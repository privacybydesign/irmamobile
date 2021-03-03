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

    // Make sure no presentedViewController (like the SafariViewController) is covering the FlutterViewController.
    if (window.rootViewController?.presentedViewController == nil) {
        let blankViewController = PrivacyCoverViewController()
        
        // Pass NO for the animated parameter. Any animation will not complete
        // before the snapshot is taken.
        window.rootViewController?.present(blankViewController, animated: false)
    }
  }

  override func applicationWillEnterForeground(_ application: UIApplication) {
    if (window.rootViewController?.presentedViewController is PrivacyCoverViewController) {
        window.rootViewController?.dismiss(animated: false)
    }

    super.applicationWillEnterForeground(application)
  }
}

class PrivacyCoverViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
    }
}
