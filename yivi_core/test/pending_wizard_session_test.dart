import "dart:async";

import "package:flutter_test/flutter_test.dart";

import "package:yivi_core/src/screens/issue_wizard/pending_wizard_session.dart";

void main() {
  group("PendingWizardSession", () {
    test(
      "resolve returns null and does not hang when nothing is tracked",
      () async {
        final session = PendingWizardSession();
        expect(session.isTracking, isFalse);
        // Must complete immediately with null rather than hanging waiting for a
        // session that will never start.
        expect(await session.resolve(), isNull);
      },
    );

    test(
      "resolve waits for the id even when the visibility read happens first (issue #623)",
      () async {
        final session = PendingWizardSession();
        final completer = Completer<int>();

        // Simulate _onButtonPress: the id is not known yet, but we synchronously
        // start tracking the pending future.
        session.track(completer.future);
        expect(session.isTracking, isTrue);

        // Simulate an early visibility change: the reader starts before Go has
        // emitted the session id. With the old fire-and-forget field this saw
        // null and bailed out, dropping the session.
        final resolved = session.resolve();

        // Go emits the id only now, after the read is already in flight.
        completer.complete(42);

        expect(await resolved, 42);
      },
    );

    test("resolve returns the id when it is already available", () async {
      final session = PendingWizardSession();
      session.track(Future.value(7));
      expect(await session.resolve(), 7);
    });

    test("clear stops tracking so the session is not handled again", () async {
      final session = PendingWizardSession();
      session.track(Future.value(1));
      expect(session.isTracking, isTrue);

      session.clear();
      expect(session.isTracking, isFalse);
      expect(await session.resolve(), isNull);
    });

    test(
      "a resolve already in flight is unaffected by a later clear",
      () async {
        final session = PendingWizardSession();
        final completer = Completer<int>();
        session.track(completer.future);

        final resolved = session.resolve();
        // Tracking is cleared while the resolve is still awaiting the id.
        session.clear();
        completer.complete(99);

        // The in-flight read captured the future before it was cleared, so it
        // still yields the id rather than null.
        expect(await resolved, 99);
      },
    );

    test("track replaces a previously tracked session", () async {
      final session = PendingWizardSession();
      session.track(Future.value(1));
      session.track(Future.value(2));
      expect(await session.resolve(), 2);
    });
  });
}
