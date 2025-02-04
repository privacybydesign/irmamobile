import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/session.dart';
import '../../../util/handle_pointer.dart';
import '../../../widgets/irma_repository_provider.dart';

class PendingPointerListener extends StatefulWidget {
  final Widget child;
  const PendingPointerListener({
    super.key,
    required this.child,
  });

  @override
  State<PendingPointerListener> createState() => _PendingPointerListenerState();
}

class _PendingPointerListenerState extends State<PendingPointerListener> {
  StreamSubscription<Pointer?>? _pointerSubscription;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = IrmaRepositoryProvider.of(context);
      _pointerSubscription = repo.getPendingPointer().listen((Pointer? pointer) {
        if (pointer != null && mounted) {
          handlePointer(Navigator.of(context), pointer);
        }
      });
    });
  }

  @override
  void dispose() {
    _pointerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
