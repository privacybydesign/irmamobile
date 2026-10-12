import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../theme/theme.dart";
import "../../../widgets/base64_image.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_avatar.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/linking_heading.dart";

const _logoSize = 44.0;
const _logoGap = 12.0;
const _bodyTopPadding = 12.0;

/// Asks permission to add the e-mail address to the app, as the first step of
/// linking it (`FeatureFlag.emailLinking`). Shown instead of
/// [IssuancePermission] for the issuance session of the linking flow.
class EmailLinkPermission extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback onGivePermission;
  final List<schemaless.Credential> issuedCredentials;

  const EmailLinkPermission({
    super.key,
    required this.onDismiss,
    required this.onGivePermission,
    required this.issuedCredentials,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(
        titleTranslationKey: "email_linking.confirm.title",
        hasBorder: false,
        leading: null,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: theme.defaultSpacing,
          vertical: theme.mediumSpacing,
        ),
        children: [
          const LinkingHeading("email_linking.confirm.header"),
          for (final credential in issuedCredentials) ...[
            SizedBox(height: theme.defaultSpacing),
            _CredentialCard(credential),
          ],
        ],
      ),
      bottomNavigationBar: IrmaBottomBar(
        style: IrmaBottomBarStyle.flat,
        primaryButtonLabel: "email_linking.confirm.add",
        onPrimaryPressed: onGivePermission,
        secondaryButtonLabel: "email_linking.confirm.cancel",
        onSecondaryPressed: onDismiss,
      ),
    );
  }
}

class _CredentialCard extends StatelessWidget {
  final schemaless.Credential credential;

  const _CredentialCard(this.credential);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final logo = credential.image;

    return Container(
      decoration: BoxDecoration(
        color: theme.surfacePrimary,
        borderRadius: theme.borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(0.0, 1.0),
            blurRadius: 6.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(theme.defaultSpacing),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.neutralExtraLight),
              ),
            ),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: IrmaAvatar(
                    size: _logoSize,
                    logoImage: logo == null
                        ? null
                        : Base64Image(
                            base64: logo.base64,
                            mimeType: logo.mimeType,
                          ),
                    initials: logo == null ? credential.name[0] : null,
                  ),
                ),
                const SizedBox(width: _logoGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        credential.name,
                        style: theme.textTheme.bodyLarge!.copyWith(
                          height: 22 / 16,
                        ),
                      ),
                      Text(
                        credential.issuer.name,
                        style: theme.textTheme.bodyMedium!.copyWith(
                          fontSize: 14,
                          height: 20 / 14,
                          color: theme.neutralExtraDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              theme.defaultSpacing,
              _bodyTopPadding,
              theme.defaultSpacing,
              theme.defaultSpacing,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final attribute in credential.attributes)
                  if (attribute.value != null) _Attribute(attribute),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Attribute extends StatelessWidget {
  final schemaless.Attribute attribute;

  const _Attribute(this.attribute);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final value = attribute.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          attribute.effectiveDisplayName,
          style: theme.textTheme.bodyMedium!.copyWith(
            fontSize: 14,
            height: 20 / 14,
            color: theme.neutralExtraDark,
          ),
        ),
        Text(
          value?.string ?? "",
          style: theme.textTheme.bodyLarge!.copyWith(height: 22 / 16),
        ),
      ],
    );
  }
}
