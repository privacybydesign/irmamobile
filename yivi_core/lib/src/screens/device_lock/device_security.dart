import "dart:async";
import "dart:io";

import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:rxdart/rxdart.dart";

/// Whether the device has a secure screen lock: a PIN, pattern, password or
/// passcode, which fingerprint and face unlock also require.
abstract class DeviceSecurity {
  Future<bool> isDeviceSecure();

  /// Opens the screen lock settings. Only Android has a public way to get
  /// there; on iOS this does nothing.
  Future<void> openSecuritySettings();
}

class RealDeviceSecurity implements DeviceSecurity {
  static const _channel = MethodChannel("yivi.app/device_security");

  @override
  Future<bool> isDeviceSecure() async {
    try {
      return await _channel.invokeMethod<bool>("isDeviceSecure") ?? true;
    } on MissingPluginException {
      // A platform without the plugin cannot tell; do not lock the user out.
      return true;
    }
  }

  @override
  Future<void> openSecuritySettings() async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod<void>("openSecuritySettings");
    }
  }
}

/// Requires a secure screen lock before the wallet can be used: Yivi's local
/// data is protected with keys in the device's keystore, and without a screen
/// lock anyone holding the unlocked phone gets past that protection.
///
/// [lockRequired] is true while the device has no screen lock. It is checked
/// at start and again every time the app resumes, so a user who sets a screen
/// lock in the settings and comes back can continue right away.
class DeviceLockRequirement {
  final DeviceSecurity _security;
  final _lockRequired = BehaviorSubject<bool>();
  late final AppLifecycleListener _lifecycleListener;
  bool _skipped = false;

  DeviceLockRequirement(this._security) {
    _lifecycleListener = AppLifecycleListener(onResume: _check);
    _check();
  }

  Stream<bool> get lockRequired => _lockRequired.stream.distinct();

  Future<void> openSecuritySettings() => _security.openSecuritySettings();

  /// Checks again, for platforms where the settings cannot be opened from the
  /// app (iOS); resuming the app also checks.
  Future<void> recheck() => _check();

  /// Debug builds only: lets a developer on an emulator without a screen lock
  /// continue. Stays skipped until the app restarts.
  void skipForDebugging() {
    assert(() {
      _skipped = true;
      _lockRequired.add(false);
      return true;
    }());
  }

  Future<void> _check() async {
    if (_skipped) return;
    final secure = await _security.isDeviceSecure();
    if (!_lockRequired.isClosed) _lockRequired.add(!secure);
  }

  void dispose() {
    _lifecycleListener.dispose();
    _lockRequired.close();
  }
}
