import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../theme/yivi_palette.dart";
import "../../../util/date_formatter.dart";
import "../../../util/nfc_credentials.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/translated_text.dart";
import "document_issuance_permission.dart";
import "session_columns.dart";
import "session_scaffold.dart";

class IssuancePermission extends ConsumerWidget {
  final VoidCallback? onDismiss;
  final VoidCallback? onGivePermission;
  final List<schemaless.Credential> issuedCredentials;

  /// Name of the issuer whose website the user just came back from, if any.
  final String? returnedFromIssuer;

  const IssuancePermission({
    super.key,
    this.onDismiss,
    this.onGivePermission,
    this.returnedFromIssuer,
    required this.issuedCredentials,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDocument =
        issuedCredentials.isNotEmpty &&
        issuedCredentials.every((c) => credentialRequiresNfc(c.credentialId));
    if (isDocument) {
      return DocumentIssuancePermission(
        issuedCredentials: issuedCredentials,
        returnedFromIssuer: returnedFromIssuer,
        onDismiss: onDismiss,
        onGivePermission: onGivePermission,
      );
    }

    // Tablets: the card on the left, what you receive and the buttons on
    // the right.
    if (useSessionColumns(context)) {
      return SessionScaffold(
        appBarTitle: "issuance.title",
        wide: true,
        scrollsUnderBars: true,
        onDismiss: onDismiss,
        body: SessionColumns(
          start: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._heading(context, large: true),
              for (final credential in issuedCredentials) ...[
                const SizedBox(height: 32),
                ..._card(context, credential, 460),
              ],
            ],
          ),
          end: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, credential) in issuedCredentials.indexed)
                  ..._receives(context, credential, first: i == 0),
              ],
            ),
          ),
          actions: _buildNavigationBar(context),
        ),
      );
    }

    return SessionScaffold(
      appBarTitle: "issuance.title",
      bottomNavigationBar: _buildNavigationBar(context),
      scrollsUnderBars: true,
      body: _buildBody(context),
      onDismiss: onDismiss,
    );
  }

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

  Widget _buildBody(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 32).clamp(0.0, 460.0);
        return ListView(
          padding: BarInsets.of(
            context,
            const EdgeInsets.fromLTRB(16, 8, 16, 24),
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ..._heading(context),
                    for (final credential in issuedCredentials) ...[
                      const SizedBox(height: 24),
                      ..._card(context, credential, width),
                      ..._receives(context, credential),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// "Back from {issuer}" and the question.
  List<Widget> _heading(BuildContext context, {bool large = false}) {
    final palette = YiviPalette.of(context);
    return [
      if (returnedFromIssuer != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: TranslatedText(
            "external_issuer.returned",
            translationParams: {"issuer": returnedFromIssuer!},
            style: palette.display(18),
          ),
        ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Semantics(
          header: true,
          child: Text(
            FlutterI18n.translate(context, "issuance.description"),
            style: large
                ? palette
                      .display(30, weight: FontWeight.w700)
                      .copyWith(height: 38 / 30, color: palette.heading)
                : palette.display(22),
          ),
        ),
      ),
    ];
  }

  /// The card with its issuer, validity and design chips.
  List<Widget> _card(
    BuildContext context,
    schemaless.Credential credential,
    double width,
  ) {
    final lang = FlutterI18n.currentLocale(context)?.languageCode ?? "en";
    return [
      Center(
        child: CredentialCardArt(credential: credential, width: width),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Chip(
            FlutterI18n.translate(
              context,
              "credential.issued_by",
              translationParams: {"issuer": credential.issuer.name},
            ),
          ),
          if ((credential.expiryDate ?? 0) > 0)
            _Chip(
              FlutterI18n.translate(
                context,
                "wallet.detail.valid_until",
                translationParams: {
                  "date": printableDate(
                    DateTime.fromMillisecondsSinceEpoch(
                      credential.expiryDate! * 1000,
                    ),
                    lang,
                  ),
                },
              ),
            ),
          if (credential.display?.svgTemplates.isNotEmpty ?? false)
            _Chip(
              FlutterI18n.translate(
                context,
                "credential_card.source.issuer_design",
              ),
              highlighted: true,
            ),
        ],
      ),
    ];
  }

  /// "You will receive" and the attributes of [credential].
  List<Widget> _receives(
    BuildContext context,
    schemaless.Credential credential, {
    bool first = false,
  }) {
    final palette = YiviPalette.of(context);
    return [
      Padding(
        padding: EdgeInsets.fromLTRB(4, first ? 0 : 24, 4, 8),
        child: Semantics(
          header: true,
          child: Text(
            FlutterI18n.translate(context, "issuance.you_will_receive"),
            style: palette.display(16),
          ),
        ),
      ),
      DecoratedBox(
        decoration: ShapeDecoration(
          color: palette.surface,
          shape: const RoundedSuperellipseBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x17000000),
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: YiviCredentialCardAttributeList(
            credential.attributes,
            credentialId: credential.credentialId,
            showDividers: true,
          ),
        ),
      ),
    ];
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool highlighted;

  const _Chip(this.label, {this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: ShapeDecoration(
        color: highlighted ? palette.tint : palette.surface,
        shape: StadiumBorder(side: BorderSide(color: palette.outline)),
      ),
      child: Text(
        label,
        style: palette
            .body(12, weight: FontWeight.w600)
            .copyWith(color: highlighted ? palette.link : palette.heading),
      ),
    );
  }
}
