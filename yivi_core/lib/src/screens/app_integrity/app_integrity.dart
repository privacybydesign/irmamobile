import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:rxdart/rxdart.dart";

/// What the native side found out about the environment the app runs in.
class IntegrityReport {
  /// The app itself is a debug build, in which none of the signals below mean
  /// anything: a developer attaches a debugger and runs on an emulator.
  final bool debuggable;

  /// A debugger is attached to the app.
  final bool debugger;

  /// A dynamic instrumentation tool, such as Frida, is loaded into the app.
  final bool instrumentation;

  /// A framework that lets modules or tweaks change any app is present, such as
  /// Xposed or a tweak injector. A property of a modified device.
  final bool hookingFramework;

  /// The app runs on an emulator or simulator instead of a real device.
  final bool emulator;

  /// The app runs inside an app-cloning or virtualisation container.
  final bool virtualized;

  const IntegrityReport({
    this.debuggable = false,
    this.debugger = false,
    this.instrumentation = false,
    this.hookingFramework = false,
    this.emulator = false,
    this.virtualized = false,
  });

  static const clean = IntegrityReport();

  factory IntegrityReport.fromMap(Map<Object?, Object?> map) {
    bool flag(String key) => map[key] == true;
    return IntegrityReport(
      debuggable: flag("debuggable"),
      debugger: flag("debugger"),
      instrumentation: flag("instrumentation"),
      hookingFramework: flag("hookingFramework"),
      emulator: flag("emulator"),
      virtualized: flag("virtualized"),
    );
  }

  /// Someone is inspecting or changing the app while it runs. No ordinary user
  /// gets here, so the app refuses to work for as long as this lasts.
  bool get tampering => debugger || instrumentation;

  /// The app runs somewhere its protections cannot be relied on, without an
  /// attack being visible. The user is warned and may continue, like on a
  /// rooted or jailbroken device.
  bool get untrustedEnvironment => hookingFramework || emulator || virtualized;

  /// Whether the device itself is modified, as opposed to the app running in an
  /// emulator or a container. Decides which explanation the warning shows.
  bool get modifiedDevice => hookingFramework;
}

/// Looks at the environment the app runs in.
abstract class AppIntegrity {
  Future<IntegrityReport> check();
}

class RealAppIntegrity implements AppIntegrity {
  static const _channel = MethodChannel("yivi.app/app_integrity");

  @override
  Future<IntegrityReport> check() async {
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>("check");
      return map == null ? IntegrityReport.clean : IntegrityReport.fromMap(map);
    } on MissingPluginException {
      // A platform without the plugin cannot tell; do not lock the user out.
      return IntegrityReport.clean;
    } on PlatformException {
      return IntegrityReport.clean;
    }
  }
}

/// Watches the environment the app runs in and tells the app how to react.
///
/// The checks are local and can be bypassed by someone who controls the device.
/// They make analysing and manipulating the app harder; they do not replace
/// attestation of the app and the device by a backend.
///
/// Only enforced in release builds ([enforce]): developers run debug builds
/// under a debugger and on emulators, and the integration tests do too.
class AppIntegrityGuard {
  final AppIntegrity _integrity;
  final bool enforce;
  final _blocked = BehaviorSubject<bool>.seeded(false);
  final _firstReport = Completer<IntegrityReport>();
  AppLifecycleListener? _lifecycleListener;
  Timer? _timer;

  AppIntegrityGuard(
    this._integrity, {
    this.enforce = kReleaseMode,
    Duration recheckInterval = const Duration(seconds: 30),
  }) {
    if (!enforce) {
      _firstReport.complete(IntegrityReport.clean);
      return;
    }
    // A debugger or an instrumentation tool can attach at any moment, so look
    // again whenever the app comes back and at an interval while it is open.
    _lifecycleListener = AppLifecycleListener(onResume: _check);
    _timer = Timer.periodic(recheckInterval, (_) => _check());
    _check();
  }

  /// True from the moment tampering is seen. It stays true until the app is
  /// restarted: a tool that detached may have left changes behind.
  Stream<bool> get blocked => _blocked.stream.distinct();

  /// The report of the first check, with every signal off when the guard does
  /// not enforce or the app is a debug build.
  Future<IntegrityReport> get firstReport => _firstReport.future;

  Future<void> _check() async {
    var report = await _integrity.check();
    if (report.debuggable) report = IntegrityReport.clean;
    if (!_firstReport.isCompleted) _firstReport.complete(report);
    if (report.tampering && !_blocked.isClosed) _blocked.add(true);
  }

  void dispose() {
    _lifecycleListener?.dispose();
    _timer?.cancel();
    _blocked.close();
  }
}
