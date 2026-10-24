import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/schemaless_events.dart";
import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/base64_image.dart";
import "../../../widgets/credential_card/yivi_credential_card.dart";
import "../../../widgets/icon_square.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_avatar.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "session_scaffold.dart";

class OpenID4VCIAuthCodePendingScreen extends StatefulWidget {
  final TrustedParty requestor;
  final List<CredentialDescriptor> offeredCredentialTypes;
  final Future<void> Function() onOpenBrowser;
  final VoidCallback onDismiss;

  const OpenID4VCIAuthCodePendingScreen({
    super.key,
    required this.requestor,
    required this.offeredCredentialTypes,
    required this.onOpenBrowser,
    required this.onDismiss,
  });

  @override
  State<OpenID4VCIAuthCodePendingScreen> createState() =>
      _OpenID4VCIAuthCodePendingScreenState();
}

class _OpenID4VCIAuthCodePendingScreenState
    extends State<OpenID4VCIAuthCodePendingScreen> {
  bool _launching = false;

  Future<void> _handleOpenBrowser() async {
    if (_launching) return;
    setState(() => _launching = true);
    try {
      await widget.onOpenBrowser();
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final issuerName = widget.requestor.name;
    final buttonLabel = FlutterI18n.translate(
      context,
      "issuance.authorization_code.pending.open_browser",
    );

    final content = <Widget>[
      Center(child: _BrowserHandOff(requestor: widget.requestor)),
      const SizedBox(height: 32),
      Semantics(
        header: true,
        child: Text(
          FlutterI18n.translate(
            context,
            "issuance.authorization_code.pending.header",
          ),
          textAlign: TextAlign.center,
          style: palette
              .display(24, weight: FontWeight.w700)
              .copyWith(height: 32 / 24, color: palette.heading),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        FlutterI18n.translate(
          context,
          "issuance.authorization_code.pending.body",
          translationParams: {"issuer": issuerName, "button": buttonLabel},
        ),
        textAlign: TextAlign.center,
        style: palette.body(16).copyWith(height: 24 / 16),
      ),
      const SizedBox(height: 32),
      // What the issuer is going to give, as on the permission screen.
      ...widget.offeredCredentialTypes.map(
        (descriptor) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: YiviCredentialCard.fromDescriptor(
            descriptor: descriptor,
            hideNotObtainable: true,
          ),
        ),
      ),
    ];

    return SessionScaffold(
      appBarTitle: "issuance.authorization_code.pending.title",
      onDismiss: widget.onDismiss,
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: buttonLabel,
        onPrimaryPressed: _launching ? null : _handleOpenBrowser,
        secondaryButtonLabel: FlutterI18n.translate(
          context,
          "issuance.authorization_code.pending.cancel",
        ),
        onSecondaryPressed: widget.onDismiss,
      ),
      scrollsUnderBars: true,
      body: BarInsetsBuilder(
        builder: (context, insets) => ListView(
          padding: insets + const EdgeInsets.fromLTRB(32, 24, 32, 32),
          children: content,
        ),
      ),
    );
  }
}

/// The issuer's logo (or first letter) and a globe, with a red arrow from
/// one to the other: the user goes from Yivi to the issuer's website.
class _BrowserHandOff extends StatelessWidget {
  final TrustedParty requestor;

  const _BrowserHandOff({required this.requestor});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final logo = requestor.image;

    Widget tile(Widget child) => IconSquare(
      fill: palette.surface,
      size: 100,
      radius: YiviCorners.iconTile,
      shadows: [
        BoxShadow(
          color: palette.glassShadow,
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
      ],
      child: child,
    );

    return ExcludeSemantics(
      child: SizedBox(
        width: 200,
        height: 140,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 0,
              child: tile(
                IrmaAvatar(
                  size: 64,
                  initials: requestor.name.isEmpty
                      ? "?"
                      : requestor.name.characters.first,
                  logoImage: logo == null
                      ? null
                      : Base64Image(
                          base64: logo.base64,
                          mimeType: logo.mimeType,
                        ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              child: tile(
                Icon(Icons.language_rounded, size: 56, color: palette.link),
              ),
            ),
            Icon(Icons.arrow_forward_rounded, size: 36, color: palette.primary),
          ],
        ),
      ),
    );
  }
}
