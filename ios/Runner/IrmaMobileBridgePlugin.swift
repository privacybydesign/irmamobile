import Flutter
import Foundation

class IrmaMobileBridgePlugin: NSObject, IrmagobridgeIrmaMobileBridgeProtocol, FlutterPlugin {
    var registrar: FlutterPluginRegistrar
    var channel: FlutterMethodChannel
    
    var initialURL: String?
    var nativeError: String?
    var appReady: Bool
    
    init(registrar: FlutterPluginRegistrar, channel: FlutterMethodChannel) {
        self.registrar = registrar
        self.channel = channel
        appReady = false
        
        super.init()
    }
    
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "irma.app/irma_mobile_bridge", binaryMessenger: registrar.messenger())
        let instance = IrmaMobileBridgePlugin(registrar: registrar, channel: channel)
        
        let bundlePath = Bundle.main.bundlePath
        let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
        
        // Mark librarypath as non-backup
        var url = URL(fileURLWithPath: libraryPath)
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        do {
            try url.setResourceValues(resourceValues)
        } catch {
            let msg = "Error excluding \(url.lastPathComponent) from backup"
            NSLog("%s: %s", msg, error.localizedDescription)
            instance.nativeError = "{\"Exception\":\"\(msg)\",\"Stack\":\"\(error.localizedDescription)\",\"Fatal\":true}"
            return
        }
        
        instance.debugLog("Starting irmago, lib=\(libraryPath), bundle=\(bundlePath)")
        
        var aesKey: Data
        do {
            aesKey = try AESKey().getKey()
        } catch {
            let msg = "Error retrieving storage key"
            NSLog("%s: %s", msg, error.localizedDescription)
            instance.nativeError = "{\"Exception\":\"\(msg)\",\"Stack\":\"\(error.localizedDescription)\",\"Fatal\":true}"
            return
        }
        
        IrmagobridgeStart(instance, libraryPath, bundlePath, TEE(), aesKey)
        
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        NSLog("handling \(call.method)")
        
        if nativeError != nil {
            channel.invokeMethod("ErrorEvent", arguments: nativeError)
            return
        }
        
        if call.method == "AppReadyEvent" {
            appReady = true
            if let initialURL = initialURL {
                channel.invokeMethod(
                    "HandleURLEvent", arguments: "{\"isInitialURL\": true, \"url\": \"\(initialURL)\"}")
            }
        }
        
        IrmagobridgeDispatchFromNative(call.method, call.arguments as? String)
        result(nil)
    }
    
    func debugLog(_ message: String?) {
#if DEBUG
        if message != nil {
            NSLog("[IrmaMobileBridgePlugin] \(message)")
        }
#endif
    }
    
    func dispatch(fromGo name: String?, payload: String?) {
        let eventName = name ?? "UnknownEvent"
        debugLog("dispatching \(eventName)(\(payload ?? ""))")
        channel.invokeMethod(eventName, arguments: payload)
    }
}

extension IrmaMobileBridgePlugin: FlutterApplicationLifeCycleDelegate {
    private func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        if let url = launchOptions?[.url] as? URL {
            initialURL = url.absoluteString
        }
        return true
    }
    
    func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        let urlStr = url.absoluteString
        if appReady {
            channel.invokeMethod("HandleURLEvent", arguments: "{\"url\": \"\(urlStr)\"}")
        } else {
            initialURL = urlStr
        }
        return true
    }
    
    private func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([Any]?) -> Void
    ) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL
        {
            let urlStr = url.absoluteString
            if appReady {
                channel.invokeMethod("HandleURLEvent", arguments: "{\"url\": \"\(urlStr)\"}")
            } else {
                initialURL = urlStr
            }
            return true
        }
        return false
    }
}
