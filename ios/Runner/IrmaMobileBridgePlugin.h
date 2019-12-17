#ifndef IrmaMobileBridgePlugin_h
#define IrmaMobileBridgePlugin_h

#import <Flutter/Flutter.h>
#import <Irmagobridge/Irmagobridge.h>

@interface IrmaMobileBridgePlugin : NSObject <FlutterPlugin, IrmagobridgeIrmaMobileBridge>
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar;
@end

#endif /* IrmaMobileBridgePlugin_h */
