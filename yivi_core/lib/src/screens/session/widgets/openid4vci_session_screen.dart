import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_appauth/flutter_appauth.dart";
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
  final FlutterAppAuth _appAuth = const FlutterAppAuth();

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
          return const ArrowBack(type: .error);
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

  Widget _buildDismissed() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Navigator.of(context).pop(),
    );
    return _buildLoading();
  }

  Widget _buildFinished(OpenID4VciSessionState session) {
    // In case of issuance during disclosure, another session is open in a screen lower in the stack.
    // Ignore clientReturnUrl in this case (issuance) and pop immediately.
    if (session.isIssuanceSession && widget.params.hasUnderlyingSession) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.popToUnderlyingSession(),
      );
      return _buildLoading();
    }

    // if (session.continueOnSecondDevice ||
    //     session.didIssuePreviouslyLaunchedCredential &&
    //         // Check to rule out the combined issuance and disclosure sessions
    //         (session.disclosuresCandidates == null ||
    //             session.disclosuresCandidates!.isEmpty)) {
    //   return _buildFinishedContinueSecondDevice(session);
    // }

    // final issuedWizardCred =
    //     widget.params.wizardActive &&
    //     widget.params.wizardCred != null &&
    //     (session.issuedCredentials
    //             ?.map((c) => c.credentialType.fullId)
    //             .contains(widget.params.wizardCred) ??
    //         false);

    // It concerns a mobile session.
    // if (session.clientReturnURL != null && !issuedWizardCred) {
    //   // If there is a return URL, navigate to it when we're done.
    //   WidgetsBinding.instance.addPostFrameCallback((_) async {
    //     // When being in a disclosure, we can continue to underlying sessions in this case;
    //     // hasUnderlyingSession during issuance is handled at the beginning of _buildFinished, so
    //     // we don't have to explicitly exclude issuance here.
    //     if (session.clientReturnURL!.isInApp) {
    //       _popToUnderlyingOrHome();
    //       await _openClientReturnUrl(session.clientReturnURL!);
    //     } else {
    //       final hasOpened = await _openClientReturnUrl(
    //         session.clientReturnURL!,
    //       );
    //       if (!hasOpened || !mounted) return;
    //       _popToUnderlyingOrHome();
    //     }
    //   });
    // } else if (widget.params.wizardActive ||
    //     session.didIssuePreviouslyLaunchedCredential) {
    //   // If the wizard is active or this concerns a combined session, pop accordingly.
    //   WidgetsBinding.instance.addPostFrameCallback(
    //     (_) => widget.params.wizardActive
    //         ? context.popToWizardScreen()
    //         : Navigator.of(context).pop(),
    //   );
    // } else if (widget.params.hasUnderlyingSession) {
    //   // In case of a disclosure having an underlying session we only continue to underlying session
    //   // if it is a mobile session and there was no clientReturnUrl.
    //   WidgetsBinding.instance.addPostFrameCallback(
    //     (_) => Navigator.of(context).pop(),
    //   );
    if (Platform.isIOS) {
      // On iOS, show a screen to press the return arrow in the top-left corner.
      return ArrowBack(type: session.status != .success ? .error : .issuance);
    } else {
      // On Android just background the app to let the user return to the previous activity
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(irmaRepositoryProvider)
            .bridgedDispatch(AndroidSendToBackgroundEvent());
        context.goHomeScreen();
      });
    }
    return _buildLoading();
  }

  Widget _buildSessionScreen(
    BuildContext context,
    OpenID4VciSessionState state,
  ) {
    if (state.error != null) {
      return _buildErrorScreen(state.error!, state.continueOnSecondDevice);
    }

    if (state.dismissed) return _buildDismissed();
    if (state.status == .success) return _buildFinished(state);

    final theme = IrmaTheme.of(context);

    final credentialDetails =
        state.credentialInfoList?.map(
          (cred) => Padding(
            padding: .only(bottom: theme.smallSpacing),
            child: SizedBox(
              width: .infinity,
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
          padding: .symmetric(
            horizontal: theme.defaultSpacing,
            vertical: theme.smallSpacing,
          ),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              // Padding(
              //   padding: EdgeInsets.symmetric(vertical: theme.smallSpacing),
              //   child: RequestorHeader(
              //     requestorInfo: state.serverName,
              //     isVerified: !(state.serverName?.unverified ?? true),
              //   ),
              // ),
              Padding(
                padding: .symmetric(vertical: theme.smallSpacing),
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
      await _signInWithAutoCodeExchange(state);
    } else if (state.grantType! == "pre-authorized_code") {
      await _signInWithPreAuthorizedCode(state);
    } else {
      reportError("Unknown grant type: ${state.grantType}", StackTrace.current);
    }
  }

  Future<void> _signInWithAutoCodeExchange(OpenID4VciSessionState state) async {
    final additionalParameters = <String, String>{
      "resource": state.authorizationCodeRequestParameters!.resource,
    };

    if (state.authorizationCodeRequestParameters!.issuerState != null) {
      additionalParameters["issuer_state"] =
          state.authorizationCodeRequestParameters!.issuerState!;
    }

    final request = AuthorizationTokenRequest(
      // TODO: the client_id should be provided by the Wallet Attestation using Attestation Based Client Auth: https://openid.net/specs/openid-4-verifiable-credential-issuance-1_0.html#I-D.ietf-oauth-attestation-based-client-auth
      // For now, we hard-code a clientId we can use
      //state.authorizationRequestParameters!.clientId,
      // Entra: '65d1d280-0f23-4763-bf41-ea4c17cde792'
      // Auth0: 'FiEH7ZmdnrDphzAjvdk9scynlm0A1XV9',

      // Keycloak
      "eudiw",

      "yivi-app://callback",
      discoveryUrl:
          state.authorizationCodeRequestParameters!.issuerDiscoveryUrl,
      scopes: state.authorizationCodeRequestParameters!.scopes,
      additionalParameters: additionalParameters,
    );

    try {
      final AuthorizationTokenResponse result = await _appAuth
          .authorizeAndExchangeCode(request);
      // Handle the result (e.g., store tokens, proceed with issuance, etc.)
      ref
          .read(irmaRepositoryProvider)
          .bridgedDispatch(
            RespondAuthorizationCodeAndExchangeForTokenEvent(
              sessionID: state.sessionID,
              proceed: true,
              accessToken: result.accessToken!,
              refreshToken: result.refreshToken,
            ),
          );
    } on FlutterAppAuthUserCancelledException catch (e) {
      // The user can try again after closing the in-app browser, so we don't dismiss the session here
      debugPrint("User cancelled by closing in-app browser: $e");
    } catch (e) {
      reportError(e, StackTrace.current);
    }

    // final uri = Uri.parse(state.authorizationServer!);
    // final request = Uri(
    //   host: uri.host,
    //   scheme: uri.scheme,
    //   queryParameters: {
    //     'state': state.sessionID.toString(),
    //     'response_type': 'code',
    //     'redirect_uri': 'https://open.yivi.app/-/callback'
    //   },
    // );

    // ref.read(irmaRepositoryProvider).openURLExternally(request.toString());
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
