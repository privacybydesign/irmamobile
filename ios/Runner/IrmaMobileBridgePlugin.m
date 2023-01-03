#import "IrmaMobileBridgePlugin.h"
#import "Runner-Swift.h"

@interface IrmaMobileBridgePlugin ()
@end

@implementation IrmaMobileBridgePlugin {
  NSObject<FlutterPluginRegistrar>* registrar;
  FlutterMethodChannel* channel;
  NSString* initialURL;
  NSString* nativeError;
  BOOL appReady;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:@"irma.app/irma_mobile_bridge"
                                                              binaryMessenger:[registrar messenger]];
  IrmaMobileBridgePlugin* instance = [[IrmaMobileBridgePlugin alloc] initWithRegistrar:registrar channel:channel];

  [registrar addMethodCallDelegate:instance channel:channel];
  [registrar addApplicationDelegate:instance];
}

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar>*)r channel:(FlutterMethodChannel*)c {
  if (self = [super init]) {
    registrar = r;
    channel = c;
    appReady = false;
  }

  NSString* bundlePath = NSBundle.mainBundle.bundlePath;
  NSString* libraryPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];

  // Mark librarypath as non-backup
  NSURL* URL = [NSURL fileURLWithPath: libraryPath];
  NSError* error = nil;
  BOOL success = [URL setResourceValue:[NSNumber numberWithBool: YES]
                                forKey:NSURLIsExcludedFromBackupKey error:&error];
  if (!success) {
    NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
  }

  [self debugLog:[NSString stringWithFormat:@"Starting irmago, lib=%@, bundle=%@", libraryPath, bundlePath]];

  NSError* storageError = nil;
  NSData * aesKey = [[[AESKey alloc] init] getKeyAndReturnError:&storageError];
  if (storageError != nil) {
    NSLog(@"Error retrieving storage key %@", storageError);
    nativeError = [NSString stringWithFormat:@"{\"Exception\":\"%@\",\"Stack\":\"%@\",\"Fatal\":true}", storageError.localizedFailureReason, storageError.localizedDescription];
    return self;
  }

  IrmagobridgeStart(self, libraryPath, bundlePath, [[TEE alloc] init], aesKey);
  return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  [self debugLog:[NSString stringWithFormat:@"handling %@", call.method]];

  if (nativeError != nil) {
    [channel invokeMethod:@"ErrorEvent" arguments:nativeError];
    return;
  }

  if([call.method isEqualToString:@"AppReadyEvent"]) {
    appReady = true;
    if (initialURL != nil) {
      [channel invokeMethod:@"HandleURLEvent" arguments:[NSString stringWithFormat:@"{\"isInitialURL\": true, \"url\": \"%@\"}", initialURL]];
    }
  }

  IrmagobridgeDispatchFromNative(call.method, (NSString*)call.arguments);
  result(nil);
}

- (void)debugLog:(NSString*)message {
#if DEBUG
  NSLog(@"[IrmaMobileBridgePlugin] %@", message);
#endif
}

- (void)dispatchFromGo:(NSString*)name payload:(NSString*)payload {
  [self debugLog:[NSString stringWithFormat:@"dispatching %@(%@)", name, payload]];
  [channel invokeMethod:name arguments:payload];
}

// Activity handling
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  NSURL *url = (NSURL *)launchOptions[UIApplicationLaunchOptionsURLKey];
  if (url != nil) {
    initialURL = [url absoluteString];
  }
  return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
  NSString *urlStr = [url absoluteString];
  if (appReady) {
    [channel invokeMethod:@"HandleURLEvent" arguments:[NSString stringWithFormat:@"{\"url\": \"%@\"}", urlStr]];
  } else {
    initialURL = urlStr;
  }
  return YES;
}

- (BOOL)application:(UIApplication *)application
    continueUserActivity:(NSUserActivity *)userActivity
      restorationHandler:(void (^)(NSArray *_Nullable))restorationHandler {
  if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb] && userActivity.webpageURL != nil) {
    NSString *url = [userActivity.webpageURL absoluteString];
    if (appReady) {
      [channel invokeMethod:@"HandleURLEvent" arguments:[NSString stringWithFormat:@"{\"url\": \"%@\"}", url]];
    } else {
      initialURL = url;
    }
    return YES;
  }
  return NO;
}

@end
