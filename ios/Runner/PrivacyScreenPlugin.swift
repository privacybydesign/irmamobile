// Code originally from: https://github.com/jeroentrappers/flutter_privacy_screen

import Flutter
import UIKit

public class PrivacyScreenPlugin: NSObject, FlutterPlugin {

    static var enabled = true

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "privacy_screen", binaryMessenger: registrar.messenger())
        let instance = PrivacyScreenPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        // register events.
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appResumed(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc static func appMovedToBackground(_ notification:Notification) {
        if( enabled ){
        let application : UIApplication = notification.object! as! UIApplication;
        let v : UIView! = application.keyWindow?.rootViewController?.view
        v.backgroundColor = .clear
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        //always fill the view
        blurEffectView.frame = v.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.tag = 55
        v?.addSubview(blurEffectView)
        }
    }

    @objc static func appResumed(_ notification:Notification) {
        if( enabled ){
        let application : UIApplication = notification.object! as! UIApplication;
        application.keyWindow?.rootViewController?.view?.viewWithTag(55)?.removeFromSuperview()
        }
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
