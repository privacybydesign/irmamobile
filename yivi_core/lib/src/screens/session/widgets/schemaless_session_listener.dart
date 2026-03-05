import "dart:async";

import "package:flutter/material.dart";

import "../../../providers/irma_repository_provider.dart";
import "../../../util/navigation.dart";

/// Listens for new schemaless session IDs from [IrmaRepository] and automatically
/// pushes a [SessionScreen] onto the navigator stack for each new session.
///
/// Place this widget high in the widget tree (e.g. wrapping the home screen)
/// so it has access to a navigator that can push session screens.
class SchemalessSessionListener extends StatefulWidget {
  final Widget child;

  const SchemalessSessionListener({super.key, required this.child});

  @override
  State<SchemalessSessionListener> createState() =>
      _SchemalessSessionListenerState();
}

class _SchemalessSessionListenerState extends State<SchemalessSessionListener> {
  StreamSubscription<int>? _subscription;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = IrmaRepositoryProvider.of(context);
      _subscription = repo.getNewSessionIds().listen((sessionID) {
        if (mounted) {
          context.pushSessionScreen(SessionRouteParams(sessionId: sessionID));
        }
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
