import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class DetectRootedDeviceRepository {
  Future<bool> hasAcceptedRootedDeviceRisk();
  Future<void> setHasAcceptedRootedDeviceRisk();
  Future<bool> isDeviceRooted();
}

class DetectRootedDeviceRepositoryImpl implements DetectRootedDeviceRepository {
  static String acceptedRootedRiskPreferenceKey = 'accepted_rooted_risk';

  @override
  Future<bool> hasAcceptedRootedDeviceRisk() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final hasAccepted = sharedPreferences.getBool(acceptedRootedRiskPreferenceKey);
    if (hasAccepted == null) {
      return false;
    }

    return hasAccepted;
  }

  @override
  Future<void> setHasAcceptedRootedDeviceRisk() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setBool(acceptedRootedRiskPreferenceKey, true);
  }

  @override
  Future<bool> isDeviceRooted() {
    return FlutterJailbreakDetection.jailbroken;
  }
}
