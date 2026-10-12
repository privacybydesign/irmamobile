import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../providers/external_issuer_provider.dart";
import "../../../theme/theme.dart";
import "../../../widgets/credential_summary.dart";
import "../../../widgets/dashed_border.dart";
import "../../../widgets/translated_text.dart";

const _rowRadius = 10.0;
const _borderWidth = 2.0;
const _rowPaddingVertical = 14.0;
const _logoSize = 40.0;
const _buttonHeight = 40.0;
const _buttonPaddingHorizontal = 12.0;
const _buttonRadius = 8.0;
const _buttonIconSize = 14.0;
const _buttonIconGap = 6.0;
const _outlineWidth = 1.0;
const _fontSize = 14.0;

const _dashColor = Color(0xFFA3AEB9);
const _rowFill = Color(0xFFF7FAFC);

// The start colour of the primary button background, assets/ui/btn-bg.svg.
const _primaryButtonColor = Color(0xFFE12747);

/// The row of a credential the user has to get on the issuer's website, in the
/// missing data checklist: where the data comes from and a button that leads
/// to the heads-up screen, or the waiting state once the user opened the
/// website and came back without finishing.
///
/// Builds [fallback] when the credential is not issued on a website, or the
/// external issuer flow is off.
class ExternalIssuerChecklistRow extends ConsumerWidget {
  final CredentialDescriptor credential;
  final VoidCallback onObtain;
  final Widget fallback;

  const ExternalIssuerChecklistRow({
    super.key,
    required this.credential,
    required this.onObtain,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      externalIssuerStatusProvider((
        credentialId: credential.credentialId,
        issueUrl: credential.issueURL,
      )),
    );
    if (status == ExternalIssuerStatus.notExternal) return fallback;

    final theme = IrmaTheme.of(context);
    final waiting = status == ExternalIssuerStatus.waiting;

    return Padding(
      padding: EdgeInsets.only(bottom: theme.smallSpacing),
      child: DashedBorder(
        color: _dashColor,
        width: _borderWidth,
        radius: _rowRadius,
        child: Container(
          key: Key("missing_data_row_${credential.credentialId}"),
          padding: EdgeInsets.symmetric(
            horizontal: theme.defaultSpacing,
            vertical: _rowPaddingVertical,
          ),
          decoration: BoxDecoration(
            color: _rowFill,
            borderRadius: BorderRadius.circular(_rowRadius),
          ),
          child: waiting
              ? _WaitingRow(credential: credential, onReopen: onObtain)
              : _ReadyRow(credential: credential, onObtain: onObtain),
        ),
      ),
    );
  }
}

class _ReadyRow extends StatelessWidget {
  final CredentialDescriptor credential;
  final VoidCallback onObtain;

  const _ReadyRow({required this.credential, required this.onObtain});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Row(
      spacing: theme.smallSpacing + theme.tinySpacing,
      children: [
        Expanded(
          child: CredentialSummary(
            name: credential.name,
            nameWeight: FontWeight.w600,
            image: credential.image,
            logoSize: _logoSize,
            subtitle: TranslatedText(
              "external_issuer.source",
              translationParams: {"issuer": credential.issuer.name},
              style: credentialSubtitleStyle(theme),
            ),
          ),
        ),
        _SmallButton(
          label: "missing_data.obtain",
          semanticsLabel: FlutterI18n.translate(
            context,
            "external_issuer.obtain_named",
            translationParams: {"credential": credential.name},
          ),
          style: _ButtonStyle.primary,
          onPressed: onObtain,
        ),
      ],
    );
  }
}

class _WaitingRow extends StatelessWidget {
  final CredentialDescriptor credential;
  final VoidCallback onReopen;

  const _WaitingRow({required this.credential, required this.onReopen});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.smallSpacing + theme.tinySpacing,
      children: [
        CredentialSummary(
          name: credential.name,
          nameWeight: FontWeight.w600,
          image: credential.image,
          logoSize: _logoSize,
          subtitle: const ExternalIssuerWaitingStatus(),
        ),
        TranslatedText(
          "external_issuer.waiting.body",
          translationParams: {"issuer": credential.issuer.name},
          style: credentialSubtitleStyle(theme),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: _SmallButton(
            label: "external_issuer.waiting.reopen",
            style: _ButtonStyle.outlined,
            onPressed: onReopen,
          ),
        ),
      ],
    );
  }
}

enum _ButtonStyle { primary, outlined }

/// A button that leaves Yivi: its label, then an external-link icon.
class _SmallButton extends StatelessWidget {
  final String label;
  final String? semanticsLabel;
  final _ButtonStyle style;
  final VoidCallback onPressed;

  const _SmallButton({
    required this.label,
    this.semanticsLabel,
    required this.style,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final primary = style == _ButtonStyle.primary;
    final foreground = primary ? theme.light : theme.neutralExtraDark;

    return Semantics(
      button: true,
      excludeSemantics: semanticsLabel != null,
      label: semanticsLabel,
      onTap: onPressed,
      child: Material(
        color: primary ? _primaryButtonColor : theme.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonRadius),
          side: primary
              ? BorderSide.none
              : BorderSide(color: theme.neutralExtraDark, width: _outlineWidth),
        ),
        child: InkWell(
          onTap: onPressed,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          child: SizedBox(
            height: _buttonHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _buttonPaddingHorizontal,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: _buttonIconGap,
                children: [
                  Flexible(
                    child: TranslatedText(
                      label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge!.copyWith(
                        fontSize: _fontSize,
                        color: foreground,
                      ),
                    ),
                  ),
                  ExcludeSemantics(
                    child: Icon(
                      Icons.open_in_new,
                      size: _buttonIconSize,
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
