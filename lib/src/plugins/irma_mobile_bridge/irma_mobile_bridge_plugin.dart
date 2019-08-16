import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:irmamobile/app.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/plugins/irma_mobile_bridge/events.dart';

class IrmaMobileBridgePlugin {
  static IrmaMobileBridgePlugin _instance;

  factory IrmaMobileBridgePlugin() {
    if (_instance == null) {
      final MethodChannel methodChannel = const MethodChannel('irma.app/irma_mobile_bridge');
      _instance = IrmaMobileBridgePlugin.initialize(methodChannel);
    }

    _instance.dispatch(AppReadyEvent());
    return _instance;
  }

  final MethodChannel _methodChannel;

  @visibleForTesting
  IrmaMobileBridgePlugin.initialize(this._methodChannel) {
    this._methodChannel.setMethodCallHandler(_onMethodCall);
  }

  void dispatch(BridgeEvent event) {
    String eventName = event.runtimeType.toString();
    String payload = jsonEncode(event);

    this._methodChannel.invokeMethod<void>(eventName, payload);
  }

  final Map<String, Function> _eventConverters = {
    'IrmaConfigurationEvent': (Map<String, dynamic> payload) => IrmaConfiguration.fromJson(payload),
    'CredentialsEvent': (Map<String, dynamic> payload) => CredentialsEvent.fromJson(payload),
  };

  Future<dynamic> _onMethodCall(MethodCall call) {
    // Decode event
    String eventName = call.method;
    if (!_eventConverters.containsKey(eventName)) {
      debugPrint('Unrecognized bridge event name received: ' + eventName);
      return Future<dynamic>.value(null);
    }

    // Dispatch
    try {
      var payload = jsonDecode(call.arguments);

      dynamic event = _eventConverters[eventName](payload);
      App.dispatch(event);
    } catch (e, stacktrace) {
      debugPrint("Error receiving or parsing method call from native: " + e.toString());
      debugPrint(stacktrace.toString());

      rethrow;
    }

    return Future<dynamic>.value(null);
  }
}
