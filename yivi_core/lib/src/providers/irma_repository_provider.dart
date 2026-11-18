import "package:cupertino_ui/cupertino_ui.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../data/activity_log_client.dart";
import "../data/app_lock.dart";
import "../data/irma_client_bridge.dart";
import "../data/irma_repository.dart";
import "../data/pending_pointer_queue.dart";
import "../data/session_repository.dart";
import "preferences_provider.dart";

/// The repository, for code that has a context but no `ref`: callbacks in
/// plain widgets and free functions that take a [BuildContext].
IrmaRepository repositoryOf(BuildContext context) => ProviderScope.containerOf(
  context,
  listen: false,
).read(irmaRepositoryProvider);

final irmaRepositoryProvider = Provider<IrmaRepository>((ref) {
  final preferences = ref.watch(preferencesProvider);
  return IrmaRepository(
    client: IrmaClientBridge(debugLogging: kDebugMode),
    preferences: preferences,
  );
});

/// The sessions: their states, and what the user does in them.
final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => ref.watch(irmaRepositoryProvider).sessions,
);

/// Questions to irmago about the activity log.
final activityLogClientProvider = Provider<ActivityLogClient>(
  (ref) => ref.watch(irmaRepositoryProvider).activityLog,
);

/// Whether the lock screen shows, and the PIN that unlocks it.
final appLockProvider = Provider<AppLock>(
  (ref) => ref.watch(irmaRepositoryProvider).appLock,
);

/// The session or e-mail link waiting to be started.
final pendingPointerQueueProvider = Provider<PendingPointerQueue>(
  (ref) => ref.watch(irmaRepositoryProvider).pendingPointers,
);
