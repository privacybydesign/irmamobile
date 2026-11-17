import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/stream_mirror.dart";
import "package:yivi_core/src/util/serial_queue.dart";

import "support/onboarding_v2_harness.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("StreamMirror", () {
    late IrmaRepository repo;
    late StreamController<int> source;
    var listening = false;

    setUp(() async {
      repo = IrmaRepository(
        client: RecordingBridge(),
        preferences: await freshPreferences(),
      );
      source = StreamController<int>.broadcast(
        onListen: () => listening = true,
        onCancel: () => listening = false,
      );
    });
    tearDown(() async {
      await source.close();
      await repo.close();
    });

    ProviderContainer container() {
      final c = ProviderContainer(
        overrides: [irmaRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      return c;
    }

    final mirror = mirrorProvider<int>((_) => source.stream, first: (_) => 7);

    test("has its first value on the first read", () {
      expect(container().read(mirror), 7);
    });

    test("follows the stream", () async {
      final c = container();
      final sub = c.listen(mirror, (_, _) {});
      source.add(1);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(mirror), 1);
      source.add(2);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(mirror), 2);
      sub.close();
    });

    test("stops listening when disposed", () async {
      final c = container();
      c.listen(mirror, (_, _) {});
      expect(listening, isTrue);
      c.dispose();
      expect(listening, isFalse);
    });
  });

  group("SerialQueue", () {
    test("runs jobs one at a time, in order", () async {
      final queue = SerialQueue();
      final log = <String>[];
      final first = Completer<void>();
      final a = queue.add(() async {
        log.add("a start");
        await first.future;
        log.add("a end");
      });
      final b = queue.add(() async => log.add("b"));
      await Future<void>.delayed(Duration.zero);
      expect(log, ["a start"]);
      first.complete();
      await Future.wait([a, b]);
      expect(log, ["a start", "a end", "b"]);
    });

    test("a failing job does not stop the next", () async {
      final queue = SerialQueue();
      final failed = queue.add(() async => throw StateError("no"));
      await expectLater(failed, throwsStateError);
      var ran = false;
      await queue.add(() async => ran = true);
      expect(ran, isTrue);
    });
  });
}
