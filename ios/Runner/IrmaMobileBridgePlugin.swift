import Flutter
import Foundation


/// Flutter plugin that implements irmagobridge's IrmaMobileBridge interface for iOS. This plugin forms the bridge between Flutter/Dart and Go.
class IrmaMobileBridgePlugin: NSObject, IrmagobridgeIrmaMobileBridgeProtocol, FlutterPlugin {
    private var channel: FlutterMethodChannel

    private var initialURL: String?
    private var nativeError: String?
    private var appReady: Bool

    /// Private constructor. This constructor is called indirectly via register (see below).
    /// - Parameters:
    ///   - channel: Channel to send messages to the Flutter side
    private init(channel: FlutterMethodChannel) {
        self.channel = channel
        appReady = false

        super.init()
    }

    /// Calls the Start method of irmagobridge.
    private func start() {
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
            nativeError = "{\"Exception\":\"\(msg)\",\"Stack\":\"\(error.localizedDescription)\",\"Fatal\":true}"
            return
        }

        debugLog("Starting irmago, lib=\(libraryPath), bundle=\(bundlePath)")

        var aesKey: Data
        do {
            aesKey = try AESKey().getKey()
        } catch {
            let msg = "Error retrieving storage key"
            NSLog("%s: %s", msg, error.localizedDescription)
            nativeError = "{\"Exception\":\"\(msg)\",\"Stack\":\"\(error.localizedDescription)\",\"Fatal\":true}"
            return
        }

        IrmagobridgeStart(self, libraryPath, bundlePath, TEE(), aesKey)
    }

    /// Calls the Stop method of irmagobridge.
    private func stop() {
        debugLog("Stopping irmago")
        IrmagobridgeStop()
    }

    /// Implements the register method of the FlutterPlugin interface. This method is called by Flutter to bootstrap the plugin.
    /// - Parameter registrar: Registration context of the Flutter plugin
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "irma.app/irma_mobile_bridge", binaryMessenger: registrar.messenger())

        let instance = IrmaMobileBridgePlugin(channel: channel)

        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }

    /// Implements the handle method of the FlutterPlugin interface. This method is called when invokeMethod is called on the plugin's method channel in Flutter/Dart.
    /// - Parameters:
    ///   - call: Object that specifies the method that should be handled and the corresponding arguments
    ///   - result: Result callback
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        NSLog("handling \(call.method)")

        if nativeError != nil {
            channel.invokeMethod("ErrorEvent", arguments: nativeError)
            return
        }

        if call.method == "AppReadyEvent" {
            self.start()
            appReady = true
            if let initialURL = initialURL {
                channel.invokeMethod(
                    "HandleURLEvent", arguments: "{\"isInitialURL\": true, \"url\": \"\(initialURL)\"}")
            }
        }

        IrmagobridgeDispatchFromNative(call.method, call.arguments as? String)
        result(nil)
    }

    /// Implements the DebugLog method of the IrmaMobileBridge interface.
    /// - Parameter message: Message to be logged
    func debugLog(_ message: String?) {
        channel.invokeMethod("GoLog", arguments: message)
#if DEBUG
        if message != nil {
            NSLog("[IrmaMobileBridgePlugin] \(message!)")
        }
#endif
    }

    /// Implements the DispatchFromGo method of the IrmaMobileBridge interface.
    /// - Parameters:
    ///   - name: name of the method being invoked
    ///   - payload: payload that contains the arguments for the requested method
    func dispatch(fromGo name: String?, payload: String?) {
        let eventName = name ?? "UnknownEvent"
        if eventName != "IrmaConfigurationEvent" {
          debugLog("dispatching \(eventName)(\(payload ?? ""))")
        }
        channel.invokeMethod(eventName, arguments: payload)
    }
}

/// Extension that enables the IrmaMobileBridgePlugin to monitor Flutter for life cycle changes.
extension IrmaMobileBridgePlugin: FlutterApplicationLifeCycleDelegate {
    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        if let url = launchOptions?[.url] as? URL {
            initialURL = url.absoluteString
        }
        return true
    }

    public func application(
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

    public func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([Any]) -> Void
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

    public func applicationWillTerminate(_ application: UIApplication) {
        stop()
    }
}
