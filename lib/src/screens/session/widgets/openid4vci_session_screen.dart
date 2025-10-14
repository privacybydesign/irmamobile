import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/native_events.dart';
import '../../../models/session.dart';
import '../../../models/session_events.dart';
import '../../../models/session_state.dart';
import '../../../providers/irma_repository_provider.dart';
import '../../../providers/session_state_provider.dart';
import '../../../util/navigation.dart';
import '../../error/session_error_screen.dart';
import 'arrow_back_screen.dart';
import 'session_scaffold.dart';

class OpenID4VciSessionScreen extends ConsumerStatefulWidget {
  const OpenID4VciSessionScreen({super.key, required this.params});

  final SessionRouteParams params;

  @override
  ConsumerState<OpenID4VciSessionScreen> createState() => _OpenID4VciSessionScreenState();
}

class _OpenID4VciSessionScreenState extends ConsumerState<OpenID4VciSessionScreen> {
  final ValueNotifier<bool> _displayArrowBack = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionStateProvider(widget.params.sessionID));

    return switch (sessionState) {
      AsyncError(:final error) => _buildErrorScreen(SessionError(errorType: '', info: error.toString()), false),
      AsyncData(:final value) => _buildSessionScreen(context, value as OpenID4VciSessionState),
      _ => _buildLoading(),
    };
  }

  Widget _buildErrorScreen(SessionError error, bool continueOnSecondDevice) {
    return ValueListenableBuilder(
      valueListenable: _displayArrowBack,
      builder: (BuildContext context, bool displayArrowBack, Widget? child) {
        if (displayArrowBack) {
          return const ArrowBack(
            type: ArrowBackType.error,
          );
        }
        return child ?? Container();
      },
      child: SessionErrorScreen(
        error: error,
        onTapClose: () async {
          if (continueOnSecondDevice) {
            context.goHomeScreen();
          } else {
            if (Platform.isIOS) {
              _displayArrowBack.value = true;
            } else {
              ref.read(irmaRepositoryProvider).bridgedDispatch(AndroidSendToBackgroundEvent());
              context.goHomeScreen();
            }
          }
        },
      ),
    );
  }

  Widget _buildLoading() {
    return CircularProgressIndicator();
  }

  Widget _buildSessionScreen(BuildContext context, OpenID4VciSessionState state) {
    if (state.error != null) {
      return _buildErrorScreen(state.error!, state.continueOnSecondDevice);
    }

    return SessionScaffold(
      appBarTitle: 'issuance.title',
      body: Center(child: Text('OpenID4VCI session')),
      onDismiss: _dismissSession,
    );
  }

  void _dismissSession() {
    ref.read(irmaRepositoryProvider).bridgedDispatch(DismissSessionEvent(sessionID: widget.params.sessionID));
  }
}
