import "package:flutter_riverpod/flutter_riverpod.dart";

/// Time left until [until], once a second; zero when it is null or past.
/// For a PIN block: the lock screen's and a session's.
final pinCountdownProvider = StreamProvider.autoDispose
    .family<Duration, DateTime?>((ref, until) async* {
      if (until == null) {
        yield Duration.zero;
        return;
      }
      while (true) {
        final remaining = until.difference(DateTime.now());
        if (remaining.inSeconds <= 0) {
          yield Duration.zero;
          return;
        }
        yield remaining;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    });
