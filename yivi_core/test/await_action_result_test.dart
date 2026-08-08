import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/enrollment_events.dart";
import "package:yivi_core/src/models/error_event.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/screens/debug/util/await_action_result.dart";

class _RecordingBridge extends IrmaBridge {
  final dispatched = <Event>[];

  @override
  void dispatch(Event event) => dispatched.add(event);
}

Future<IrmaRepository> _buildRepo() async {
  SharedPreferences.setMockInitialValues({});
  return IrmaRepository(
    client: _RecordingBridge(),
    preferences: await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    ),
  );
}

EnrollmentStatusEvent _successEvent() => EnrollmentStatusEvent(
  enrolledSchemeManagerIds: const [],
  unenrolledSchemeManagerIds: const [],
);

ErrorEvent _errorEvent() => ErrorEvent(
  exception: "cbor: cannot unmarshal negative integer into ...",
  stack: "",
  fatal: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    "subscribes synchronously so a success event dispatched in the same turn is not missed",
    () async {
      final repo = await _buildRepo();
      addTearDown(repo.close);

      // Start listening, then dispatch in the same synchronous turn.
      final result = awaitActionResult<EnrollmentStatusEvent>(
        repo,
        timeout: const Duration(seconds: 5),
      );
      repo.dispatch(_successEvent());

      expect(await result, isNull, reason: "success resolves to null");
    },
  );

  test("returns the ErrorEvent when a failure arrives first", () async {
    final repo = await _buildRepo();
    addTearDown(repo.close);

    final error = _errorEvent();
    final result = awaitActionResult<EnrollmentStatusEvent>(
      repo,
      timeout: const Duration(seconds: 5),
    );
    repo.dispatch(error);

    expect(await result, same(error));
  });

  test("throws TimeoutException when neither event arrives in time", () async {
    final repo = await _buildRepo();
    addTearDown(repo.close);

    await expectLater(
      awaitActionResult<EnrollmentStatusEvent>(
        repo,
        timeout: const Duration(milliseconds: 50),
      ),
      throwsA(isA<TimeoutException>()),
    );
  });

  test(
    "a late failure after timeout does not surface as an uncaught async error",
    () async {
      final repo = await _buildRepo();
      addTearDown(repo.close);

      // Let the call time out, then emit a failure that nobody is waiting for.
      await expectLater(
        awaitActionResult<EnrollmentStatusEvent>(
          repo,
          timeout: const Duration(milliseconds: 50),
        ),
        throwsA(isA<TimeoutException>()),
      );

      // If the timed-out call left its subscription alive this would drive it;
      // the helper cancels in a finally, so this is simply unobserved.
      repo.dispatch(_errorEvent());
      await Future<void>.delayed(const Duration(milliseconds: 10));
    },
  );

  test(
    "completes with StateError when the event stream closes first",
    () async {
      final repo = await _buildRepo();

      final result = awaitActionResult<EnrollmentStatusEvent>(
        repo,
        timeout: const Duration(seconds: 5),
      );
      // Attach the matcher before closing so the error future always has a
      // listener the moment it completes.
      final expectation = expectLater(result, throwsA(isA<StateError>()));
      await repo.close();
      await expectation;
    },
  );
}
