import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/delete_keyshare_tokens_event.dart";
import "package:yivi_core/src/models/event.dart";

class _RecordingBridge extends IrmaBridge {
  final dispatched = <Event>[];

  @override
  void dispatch(Event event) => dispatched.add(event);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("lock() drops the keyshare token so sessions require the PIN", () async {
    SharedPreferences.setMockInitialValues({});
    final bridge = _RecordingBridge();
    final repo = IrmaRepository(
      client: bridge,
      preferences: await IrmaPreferences.fromInstance(
        mostRecentTermsUrlNl: "",
        mostRecentTermsUrlEn: "",
      ),
    );
    addTearDown(repo.close);

    repo.lock();

    expect(
      bridge.dispatched.whereType<DeleteKeyshareTokensEvent>(),
      isNotEmpty,
      reason: "lock() must tell irmago to delete the keyshare tokens",
    );
  });
}
