// Code originally from: https://github.com/jeroentrappers/flutter_privacy_screen

import Flutter
import UIKit

public class PrivacyScreenPlugin: NSObject, FlutterPlugin {

    static var enabled = true

    /// The overlay currently on screen, if there is one. Kept instead of looked
    /// up again on removal: `keyWindow` is deprecated and resolves to whichever
    /// window happens to be key across all connected scenes, so adding to one
    /// view hierarchy and searching another would strand the blur on screen for
    /// the rest of the process. Weak, so it drops to nil by itself once the view
    /// is removed or its hierarchy is torn down.
    private static weak var blurView: UIVisualEffectView?

    /// How many in-app flows currently need the blur held back, see
    /// `suspendPrivacyScreen`. A count rather than a flag, so overlapping flows
    /// cannot un-suspend each other.
    private static var suspendCount = 0

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "privacy_screen", binaryMessenger: registrar.messenger())
        let instance = PrivacyScreenPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        // register events.
        //
        // The blur goes up on willResignActive, the last moment the app is
        // reliably still on screen: swiping up and holding to open the App
        // Switcher keeps the app foreground-inactive and composites its live
        // layer tree into the card, and a UIVisualEffectView added once the app
        // is already in the background is not guaranteed to render its effect.
        //
        // willResignActive also fires for system UI drawn in front of a still
        // foregrounded app — the NFC reader sheet, the OS biometric prompt — and
        // the app stays resigned for as long as that UI is up, so blurring there
        // covers our own UI for the whole scan. Those two flows suspend the
        // privacy screen for their duration instead. didEnterBackground is
        // observed as well, so leaving the app during such a flow is still
        // caught: suspension holds back the resign-active blur, never the one
        // that hides the app in the switcher.
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appWillResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appResumed(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc static func appWillResignActive(_ notification:Notification) {
        // Accepted gap: the App Switcher gesture also only resigns the app active,
        // so during a suspended flow the switcher card shows the live screen. That
        // screen is the NFC scanning animation, or whatever the biometric prompt
        // was raised over: the lock screen, but also Settings, or the unlocked
        // wallet behind the post-unlock opt-in dialog. For the prompt that is no
        // worse than before, when authenticate switched the privacy screen off
        // outright; for the read the card used to be blurred and now is not.
        // There is no way to tell the two causes of resigning apart from here.
        guard suspendCount == 0 else { return }
        addBlur(notification)
    }

    @objc static func appDidEnterBackground(_ notification:Notification) {
        // The blur that hides the app in the switcher is added here regardless of
        // the suspension count, so a suspension never costs it. The count itself
        // is left alone: system UI can outlive the app leaving the foreground.
        // local_auth saves its sticky state on the systemCancel iOS sends when we
        // background, and re-presents the prompt on didBecomeActive with the Dart
        // call still pending, so zeroing it here would blur that second prompt.
        addBlur(notification)
    }

    private static func addBlur(_ notification:Notification) {
        // Never stack overlays: appResumed removes a single view, so any
        // unbalanced add would leave a blur behind on screen for good.
        //
        // The original set `v.backgroundColor = .clear` here and never put it
        // back. Dropped rather than kept: it was a permanent mutation of the root
        // view for a temporary overlay, and FlutterView covers that view, so it
        // has nothing to show either way. Not something to restore.
        guard enabled, blurView == nil,
              let application = notification.object as? UIApplication,
              let v = application.keyWindow?.rootViewController?.view else { return }
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        //always fill the view
        blurEffectView.frame = v.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        v.addSubview(blurEffectView)
        blurView = blurEffectView
    }

    @objc static func appResumed(_ notification:Notification) {
        // Deliberately not gated on `enabled`: disabling the privacy screen while
        // the overlay is up would otherwise strand it on screen.
        blurView?.removeFromSuperview()
        blurView = nil
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
        // Hold back the blur for a flow that shows system UI on top of the app,
        // which resigns the app active without backgrounding it. Balanced by
        // resumePrivacyScreen; leaves the user's screenshot preference alone.
        case "suspendPrivacyScreen":
            PrivacyScreenPlugin.suspendCount += 1
            result(true)
            break
        case "resumePrivacyScreen":
            PrivacyScreenPlugin.suspendCount = max(0, PrivacyScreenPlugin.suspendCount - 1)
            result(true)
            break
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
