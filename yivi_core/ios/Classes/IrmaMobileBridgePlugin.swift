import Flutter
import Foundation
import Irmagobridge


/// Flutter plugin that implements irmagobridge's IrmaMobileBridge interface for iOS. This plugin forms the bridge between Flutter/Dart and Go.
public class IrmaMobileBridgePlugin: NSObject, IrmagobridgeIrmaMobileBridgeProtocol, FlutterPlugin {
    private var channel: FlutterMethodChannel

    private var initialURL: String?
    private var nativeError: String?
    private var appReady: Bool
    private var started = false

    /// Private constructor. This constructor is called indirectly via register (see below).
    /// - Parameters:
    ///   - channel: Channel to send messages to the Flutter side
    public init(channel: FlutterMethodChannel) {
        self.channel = channel
        appReady = false

        super.init()
    }

    /// Calls the Start method of irmagobridge. locale is the effective app
    /// language (a bare language code such as "nl") supplied by the Dart side
    /// in the AppReadyEvent payload; irmago resolves text and logos against it.
    private func start(locale: String) {
        let bundlePath = Bundle(for: type(of: self)).bundlePath
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

        IrmagobridgeStart(self, libraryPath, bundlePath, TEE(), aesKey, locale)
        started = true
    }

    /// Calls the Stop method of irmagobridge. Idempotent: teardown arrives over
    /// whichever life cycle the host uses, and a second call would stop a bridge that
    /// is no longer running.
    private func stop() {
        guard started else { return }
        started = false
        debugLog("Stopping irmago")
        IrmagobridgeStop()
    }

    /// Records a URL the app was opened with, or hands it to Dart if Dart is already
    /// listening. Shared by the UIApplication and UIScene life cycle callbacks below.
    /// - Parameter url: the URL the app was asked to open
    /// - Returns: always true; the URL is ours to deal with either way
    @discardableResult
    private func handle(url: URL) -> Bool {
        let urlStr = url.absoluteString
        if appReady {
            channel.invokeMethod("HandleURLEvent", arguments: "{\"url\": \"\(urlStr)\"}")
        } else {
            // Picked up by the AppReadyEvent handler, which tags it isInitialURL.
            initialURL = urlStr
        }
        return true
    }

    /// The URL of the first web-browsing activity in `activities`, if there is one.
    /// Universal links arrive as an NSUserActivity rather than as a URL context.
    private func webpageURL(in activities: Set<NSUserActivity>) -> URL? {
        return activities.first { $0.activityType == NSUserActivityTypeBrowsingWeb }?.webpageURL
    }

    /// Implements the register method of the FlutterPlugin interface. This method is called by Flutter to bootstrap the plugin.
    /// - Parameter registrar: Registration context of the Flutter plugin
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "irma.app/irma_mobile_bridge", binaryMessenger: registrar.messenger())

        let instance = IrmaMobileBridgePlugin(channel: channel)

        registrar.addMethodCallDelegate(instance, channel: channel)
        // Both are registered because which one Flutter forwards depends on the host
        // app: a host whose Info.plist declares a UIApplicationSceneManifest (yivi_app
        // does, as iOS 27 refuses to launch without one) gets the UIScene callbacks and
        // never the UIApplication ones, and a host still on the application life cycle
        // gets the reverse. UIKit picks one regime for the whole process, so a URL is
        // never delivered down both paths.
        registrar.addApplicationDelegate(instance)
        registrar.addSceneDelegate(instance)
    }

    /// Implements the handle method of the FlutterPlugin interface. This method is called when invokeMethod is called on the plugin's method channel in Flutter/Dart.
    /// - Parameters:
    ///   - call: Object that specifies the method that should be handled and the corresponding arguments
    ///   - result: Result callback
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        NSLog("handling \(call.method)")

        if nativeError != nil {
            channel.invokeMethod("ErrorEvent", arguments: nativeError)
            return
        }

        if call.method == "AppReadyEvent" {
            // The effective app language rides in the AppReadyEvent payload so
            // the Go client is constructed with the right locale from the start.
            var locale = ""
            if let payload = call.arguments as? String,
                let data = payload.data(using: .utf8),
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let l = json["locale"] as? String {
                locale = l
            }
            self.start(locale: locale)
            appReady = true
            if let initialURL = initialURL {
                channel.invokeMethod(
                    "HandleURLEvent", arguments: "{\"isInitialURL\": true, \"url\": \"\(initialURL)\"}")
            }
            // Acknowledge the launch handshake AFTER any initial URL, so the UI
            // knows the launch URL (if any) has been delivered. Channel messages
            // are FIFO, so the HandleURLEvent above is always processed first;
            // the lock screen relies on this to hold off biometric until it
            // knows whether the app was opened with a session.
            channel.invokeMethod("AppReadyAckEvent", arguments: "{}")
        }

        IrmagobridgeDispatchFromNative(call.method, call.arguments as? String)
        result(nil)
    }

    /// Implements the DebugLog method of the IrmaMobileBridge interface.
    /// - Parameter message: Message to be logged
    public func debugLog(_ message: String?) {
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
    public func dispatch(fromGo name: String?, payload: String?) {
        let eventName = name ?? "UnknownEvent"
        channel.invokeMethod(eventName, arguments: payload)
    }
}

/// Extension that enables the IrmaMobileBridgePlugin to monitor Flutter for life cycle
/// changes, on a host app still using the UIApplication life cycle. On a host that has
/// adopted UIScene these are never called; see the UIScene extension below.
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
        return handle(url: url)
    }

    public func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([Any]) -> Void
    ) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let url = userActivity.webpageURL
        else { return false }
        return handle(url: url)
    }

    public func applicationWillTerminate(_ application: UIApplication) {
        stop()
    }
}

/// Extension that enables the IrmaMobileBridgePlugin to monitor Flutter for life cycle
/// changes on a host app that has adopted the UIScene life cycle, which iOS 27 requires.
/// UIKit routes URL opens and user activities to the scene delegate there, so without
/// these the UIApplication callbacks above would simply never fire and every deep link
/// into the app would be dropped without an error.
extension IrmaMobileBridgePlugin: FlutterSceneLifeCycleDelegate {
    /// Cold start: a URL the app was launched with rides in on the scene connection
    /// rather than through openURLContexts, which only covers an app that is already
    /// running. `connectionOptions` is nil once another plugin has taken the connection.
    public func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions?
    ) -> Bool {
        guard let connectionOptions = connectionOptions else { return false }
        if let url = connectionOptions.urlContexts.first?.url {
            return handle(url: url)
        }
        if let url = webpageURL(in: connectionOptions.userActivities) {
            return handle(url: url)
        }
        return false
    }

    /// Warm start over a custom scheme: irma:, openid4vp:, openid-credential-offer:,
    /// app.yivi.open:. The UIApplication equivalent is application(_:open:options:).
    public func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
        guard let url = URLContexts.first?.url else { return false }
        return handle(url: url)
    }

    /// Warm start over a universal link.
    public func scene(_ scene: UIScene, continue userActivity: NSUserActivity) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let url = userActivity.webpageURL
        else { return false }
        return handle(url: url)
    }

    /// The scene life cycle's stand-in for applicationWillTerminate: UIKit does not call
    /// that on a scene-based app. The app declares UIApplicationSupportsMultipleScenes
    /// false, so losing the one scene means the Flutter engine driving this bridge is
    /// going away with it.
    public func sceneDidDisconnect(_ scene: UIScene) {
        stop()
    }
}
