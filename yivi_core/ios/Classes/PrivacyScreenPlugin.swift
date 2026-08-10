// Code originally from: https://github.com/jeroentrappers/flutter_privacy_screen

import Flutter
import UIKit

public class PrivacyScreenPlugin: NSObject, FlutterPlugin {

    static var enabled = true

    private static let blurViewTag = 55

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "privacy_screen", binaryMessenger: registrar.messenger())
        let instance = PrivacyScreenPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        // register events.
        //
        // We blur on didEnterBackground, not on willResignActive. Both fire when
        // the app loses focus, but willResignActive also fires for system UI shown
        // *in front of* a still-foregrounded app — the NFC reader sheet, the OS
        // biometric prompt, Control Centre, notification banners, incoming calls —
        // and the app stays resigned for as long as that UI is up. Blurring there
        // covers our own UI for the entire NFC scan or Face ID scan, which is what
        // made the NFC scanning screen look blurred. iOS captures the app-switcher
        // snapshot after applicationDidEnterBackground returns, so the later hook
        // still hides the app contents in the switcher — the only thing the privacy
        // screen is for on iOS.
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appResumed(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc static func appMovedToBackground(_ notification:Notification) {
        guard enabled,
              let application = notification.object as? UIApplication,
              let v = application.keyWindow?.rootViewController?.view else { return }
        // Never stack overlays: appResumed removes a single view with this tag, so
        // any unbalanced add would leave a blur behind on screen for good.
        guard v.viewWithTag(blurViewTag) == nil else { return }
        v.backgroundColor = .clear
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        //always fill the view
        blurEffectView.frame = v.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.tag = blurViewTag
        v.addSubview(blurEffectView)
    }

    @objc static func appResumed(_ notification:Notification) {
        // Deliberately not gated on `enabled`: disabling the privacy screen while
        // the overlay is up would otherwise strand it on screen.
        guard let application = notification.object as? UIApplication else { return }
        application.keyWindow?.rootViewController?.view?.viewWithTag(blurViewTag)?.removeFromSuperview()
    }


    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "enablePrivacyScreen":
            PrivacyScreenPlugin.enabled = true;
            result(true)
            break
        case "disablePrivacyScreen":
            PrivacyScreenPlugin.enabled = false;
            result(true)
            break
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
