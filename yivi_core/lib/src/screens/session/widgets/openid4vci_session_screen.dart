import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../models/native_events.dart";
import "../../../models/session.dart";
import "../../../models/session_events.dart";
import "../../../models/session_state.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../providers/session_state_provider.dart";
import "../../../sentry/sentry.dart";
import "../../../theme/theme.dart";
import "../../../util/navigation.dart";
import "../../../widgets/credential_card/yivi_credential_type_info_card.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/irma_quote.dart";
import "../../error/session_error_screen.dart";
import "arrow_back_screen.dart";
import "provide_transactioncode_dialog.dart";
import "session_scaffold.dart";

class OpenID4VciSessionScreen extends ConsumerStatefulWidget {
  const OpenID4VciSessionScreen({super.key, required this.params});

  final SessionRouteParams params;

  @override
  ConsumerState<OpenID4VciSessionScreen> createState() =>
      _OpenID4VciSessionScreenState();
}

class _OpenID4VciSessionScreenState
    extends ConsumerState<OpenID4VciSessionScreen> {
  final ValueNotifier<bool> _displayArrowBack = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(
      sessionStateProvider(widget.params.sessionID),
    );

    return switch (sessionState) {
      AsyncError(:final error) => _buildErrorScreen(
        SessionError(errorType: "", info: error.toString()),
        false,
      ),
      AsyncData(:final value) => _buildSessionScreen(
        context,
        value as OpenID4VciSessionState,
      ),
      _ => _buildLoading(),
    };
  }

  Widget _buildErrorScreen(SessionError error, bool continueOnSecondDevice) {
    return ValueListenableBuilder(
      valueListenable: _displayArrowBack,
      builder: (BuildContext context, bool displayArrowBack, Widget? child) {
        if (displayArrowBack) {
          return const ArrowBack(type: ArrowBackType.error);
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
              ref
                  .read(irmaRepositoryProvider)
                  .bridgedDispatch(AndroidSendToBackgroundEvent());
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

  Widget _buildSessionScreen(
    BuildContext context,
    OpenID4VciSessionState state,
  ) {
    if (state.error != null) {
      return _buildErrorScreen(state.error!, state.continueOnSecondDevice);
    }
    final theme = IrmaTheme.of(context);

    final credentialDetails =
        state.credentialInfoList?.map(
          (cred) => Padding(
            padding: EdgeInsets.only(bottom: theme.smallSpacing),
            child: SizedBox(
              width: double.infinity,
              child: CredentialTypeInfoCard(info: cred),
            ),
          ),
        ) ??
        [];

    return SessionScaffold(
      appBarTitle: "issuance.title",
      body: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: theme.defaultSpacing,
            vertical: theme.smallSpacing,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Padding(
              //   padding: EdgeInsets.symmetric(vertical: theme.smallSpacing),
              //   child: RequestorHeader(
              //     requestorInfo: state.serverName,
              //     isVerified: !(state.serverName?.unverified ?? true),
              //   ),
              // ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: theme.smallSpacing),
                child: IrmaQuote(
                  quote: FlutterI18n.translate(context, "issuance.description"),
                ),
              ),
              ...credentialDetails,
            ],
          ),
        ),
      ),
      onDismiss: _dismissSession,
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: FlutterI18n.translate(context, "issuance.add"),
        onPrimaryPressed: () => _handlePermissionGranted(state),
        secondaryButtonLabel: FlutterI18n.translate(context, "issuance.cancel"),
        onSecondaryPressed: _dismissSession,
      ),
    );
  }

  Future<void> _handlePermissionGranted(OpenID4VciSessionState state) async {
    if (state.grantType! == "authorization_code") {
      await _signInWithAutoCodeFlow(state);
    } else if (state.grantType! == "pre-authorized_code") {
      await _signInWithPreAuthorizedCode(state);
    } else {
      reportError("Unknown grant type: ${state.grantType}", StackTrace.current);
    }
  }

  Future<void> _signInWithAutoCodeFlow(OpenID4VciSessionState state) async {
    final s = state.generateSessionState();
    final url = Uri.parse(state.authorizationCodeRequestParameters!.authorizationRequestUrl);
    final urlWithState = url.replace(queryParameters: {
      ...url.queryParameters,
      "state": s,
    }).toString();

    ref.read(irmaRepositoryProvider).openURLinAppBrowser(urlWithState);

//    ref.read(irmaRepositoryProvider).openURLExternally(urlWithState);
  }

  Future<void> _signInWithPreAuthorizedCode(
    OpenID4VciSessionState state,
  ) async {
    // If a transaction code is required, request it from the user
    String? transactionCode;
    if (state.transactionCodeParameters != null) {
      transactionCode = await showDialog<String>(
        context: context,
        builder: (context) => ProvideTransactionCodeDialog(
          transactionCodeParameters: state.transactionCodeParameters!,
        ),
      );

      // User cancelled the dialog, so we stop here and show the session screen again
      if (transactionCode == null) {
        return;
      }
    }

    // Handle the permission
    ref
        .read(irmaRepositoryProvider)
        .bridgedDispatch(
          RespondPreAuthorizedCodeFlowPermissionEvent(
            sessionID: state.sessionID,
            proceed: true,
            transactionCode: transactionCode,
          ),
        );
  }

  void _dismissSession() {
    // TODO: call appAuth.endSession(request) ?
    ref
        .read(irmaRepositoryProvider)
        .bridgedDispatch(
          DismissSessionEvent(sessionID: widget.params.sessionID),
        );
  }
}
