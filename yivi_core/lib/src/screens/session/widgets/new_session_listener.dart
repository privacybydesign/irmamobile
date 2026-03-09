import "dart:async";

import "package:flutter/material.dart";

import "../../../providers/irma_repository_provider.dart";
import "../../../util/navigation.dart";

/// Listens for new schemaless session IDs from [IrmaRepository] and automatically
/// pushes a [SessionScreen] onto the navigator stack for each new session.
///
/// Place this widget high in the widget tree (e.g. wrapping the home screen)
/// so it has access to a navigator that can push session screens.
class NewSessionListener extends StatefulWidget {
  final Widget child;

  const NewSessionListener({super.key, required this.child});

  @override
  State<NewSessionListener> createState() => _NewSessionListenerState();
}

class _NewSessionListenerState extends State<NewSessionListener> {
  StreamSubscription<int>? _subscription;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = IrmaRepositoryProvider.of(context);
      _subscription = repo.getNewSessionIds().listen((sessionID) async {
        if (!mounted) return;
        final hasUnderlying = await repo.hasActiveSessions(excludeSessionId: sessionID);
        if (!mounted) return;
        context.pushSessionScreen(
          SessionRouteParams(
            sessionId: sessionID,
            hasUnderlyingSession: hasUnderlying,
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
