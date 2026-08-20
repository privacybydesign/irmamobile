import "../../data/irma_preferences.dart";
import "rooted_device_detector.dart";

abstract class DetectRootedDeviceRepository {
  Stream<bool> hasAcceptedRootedDeviceRisk();
  Future<void> setHasAcceptedRootedDeviceRisk();
  Future<bool> isDeviceRooted();
}

class DetectRootedDeviceIrmaPrefsRepository
    implements DetectRootedDeviceRepository {
  final IrmaPreferences _preferences;
  final RootedDeviceDetector _detector;

  DetectRootedDeviceIrmaPrefsRepository({
    required IrmaPreferences preferences,
    required RootedDeviceDetector detector,
  }) : _preferences = preferences,
       _detector = detector;

  @override
  Stream<bool> hasAcceptedRootedDeviceRisk() {
    return _preferences.getAcceptedRootedRisk();
  }

  @override
  Future<void> setHasAcceptedRootedDeviceRisk() async {
    _preferences.setAcceptedRootedRisk(true);
  }

  @override
  Future<bool> isDeviceRooted() => _detector.isDeviceRooted();
}
