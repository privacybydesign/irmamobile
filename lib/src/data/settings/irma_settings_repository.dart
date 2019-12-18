


import 'package:flutter/widgets.dart';

import 'irma_app_settings.dart';

class IrmaSettingsRepository {
  static IrmaSettingsRepository _instance;
  final IrmaAppSettings settings;

  factory IrmaSettingsRepository({@required IrmaAppSettings settings}) {
    return _instance = IrmaSettingsRepository._internal(settings: settings);
  }

  // _internal is a named constructor only used by the factory
  IrmaSettingsRepository._internal({
    @required this.settings,
  }) : assert(settings != null);

  static IrmaAppSettings get() {
    if (_instance == null) {
      throw Exception('IrmaSettingsRepository has not been initialized');
    }
    return _instance.settings;
  }
}