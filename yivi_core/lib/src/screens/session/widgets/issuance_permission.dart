import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../providers/face_credential_content_provider.dart";
import "../../../theme/theme.dart";
import "../../../widgets/credential_card/yivi_credential_card.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/irma_quote.dart";
import "session_scaffold.dart";

class IssuancePermission extends ConsumerWidget {
  final VoidCallback? onDismiss;
  final VoidCallback? onGivePermission;
  final List<schemaless.Credential> issuedCredentials;

  const IssuancePermission({
    super.key,
    this.onDismiss,
    this.onGivePermission,
    required this.issuedCredentials,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => SessionScaffold(
    appBarTitle: "issuance.title",
    bottomNavigationBar: _buildNavigationBar(context),
    body: _buildBody(context, ref),
    onDismiss: onDismiss,
  );

  Widget _buildNavigationBar(BuildContext context) {
    return onGivePermission != null
        ? IrmaBottomBar(
            primaryButtonLabel: FlutterI18n.translate(context, "issuance.add"),
            onPrimaryPressed: () => onGivePermission?.call(),
            secondaryButtonLabel: FlutterI18n.translate(
              context,
              "issuance.cancel",
            ),
            onSecondaryPressed: () => onDismiss?.call(),
          )
        : IrmaBottomBar(
            primaryButtonLabel: FlutterI18n.translate(
              context,
              "session.navigation_bar.back",
            ),
            onPrimaryPressed: () => onDismiss?.call(),
          );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);
    // F-Droid injects this to show the face-verification assurance on the card;
    // it is null in every other build. Showing it here mirrors what appears on
    // the stored credential after adding, so the preview matches the result.
    final faceContent = ref.watch(faceCredentialContentProvider);

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: theme.defaultSpacing),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: theme.smallSpacing),
          child: IrmaQuote(
            quote: FlutterI18n.translate(context, "issuance.description"),
          ),
        ),
        ...issuedCredentials.map(
          (credential) => Padding(
            padding: EdgeInsets.only(bottom: theme.defaultSpacing),
            child: YiviCredentialCard.fromCredential(
              credential: credential,
              compact: false,
              lowInstanceCountThreshold: 0,
              faceContentBuilder: faceContent == null
                  ? null
                  : (ctx) =>
                        faceContent(ctx, credential) ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}
