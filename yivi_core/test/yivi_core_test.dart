import "package:flutter_test/flutter_test.dart";
import "package:plugin_platform_interface/plugin_platform_interface.dart";
import "package:yivi_core/yivi_core.dart";
import "package:yivi_core/yivi_core_method_channel.dart";
import "package:yivi_core/yivi_core_platform_interface.dart";

class MockYiviCorePlatform
    with MockPlatformInterfaceMixin
    implements YiviCorePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value("42");
}

void main() {
  final YiviCorePlatform initialPlatform = YiviCorePlatform.instance;

  test("$MethodChannelYiviCore is the default instance", () {
    expect(initialPlatform, isInstanceOf<MethodChannelYiviCore>());
  });

  test("getPlatformVersion", () async {
    YiviCore yiviCorePlugin = YiviCore();
    MockYiviCorePlatform fakePlatform = MockYiviCorePlatform();
    YiviCorePlatform.instance = fakePlatform;

    expect(await yiviCorePlugin.getPlatformVersion(), "42");
  });
}
