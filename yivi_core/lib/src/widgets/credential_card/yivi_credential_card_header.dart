import "package:flutter/material.dart";

import "../../models/attribute.dart";
import "../../models/irma_configuration.dart";
import "../../theme/theme.dart";
import "../translated_text.dart";
import "credential_card_image.dart";

class YiviCredentialCardHeader extends StatelessWidget {
  final bool compact;
  final String credentialName;
  final CredentialType? credentialType;
  final List<Attribute>? attributes;
  final String? issuerName;
  final Widget? trailing;
  final bool isExpired;
  final bool isExpiringSoon;
  final bool isRevoked;

  const YiviCredentialCardHeader({
    required this.credentialName,
    required this.compact,
    this.credentialType,
    this.attributes,
    this.issuerName,
    this.trailing,
    this.isExpiringSoon = false,
    this.isExpired = false,
    this.isRevoked = false,
  });

  Widget? statusText(IrmaThemeData theme) {
    if (isRevoked) {
      return TranslatedText(
        "credential.revoked",
        style: theme.themeData.textTheme.headlineMedium!.copyWith(
          color: theme.error,
        ),
      );
    }
    if (isExpired) {
      return TranslatedText(
        "credential.expired",
        style: theme.themeData.textTheme.headlineMedium!.copyWith(
          color: theme.error,
        ),
      );
    }
    if (isExpiringSoon) {
      return TranslatedText(
        "credential.about_to_expire",
        style: theme.themeData.textTheme.headlineMedium!.copyWith(
          color: theme.warning,
        ),
      );
    }
    return null;
  }

  static const _compactCardHeight = 72.0;
  static const _expandedCardHeight = 150.0;

  Widget _buildCredentialCard(double height, {VoidCallback? onTap}) {
    if (credentialType != null) {
      return CredentialCardImageCompact(
        credentialType: credentialType!,
        attributes: attributes,
        height: height,
        onTap: onTap,
      );
    }
    // Fallback to empty container if no credential type provided
    return SizedBox(
      width: height * (340 / 215),
      height: height,
    );
  }

  void _showFullScreenCard(BuildContext context) {
    if (credentialType == null) return;

    showDialog(
      context: context,
      builder: (context) => _FullScreenCardDialog(
        credentialType: credentialType!,
        attributes: attributes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final status = statusText(theme);

    if (compact) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [status ?? Container(), if (trailing != null) trailing!],
          ),
          if (trailing != null || status != null)
            SizedBox(height: theme.smallSpacing),
          Stack(
            children: [
              Center(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ExcludeSemantics(
                      child: _buildCredentialCard(_compactCardHeight),
                    ),
                    SizedBox(width: theme.defaultSpacing),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            credentialName,
                            style: theme.themeData.textTheme.headlineMedium!
                                .copyWith(color: theme.dark, fontSize: 16),
                            softWrap: true,
                          ),
                          if (issuerName != null)
                            TranslatedText(
                              "credential.issued_by",
                              style: theme.themeData.textTheme.bodyMedium
                                  ?.copyWith(fontSize: 14),
                              translationParams: {"issuer": issuerName!},
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Stack(
      children: [
        Align(alignment: Alignment.topLeft, child: statusText(theme)),
        Align(alignment: Alignment.topRight, child: trailing),
        Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (trailing != null)
                SizedBox(height: theme.mediumSpacing)
              else
                SizedBox(height: theme.smallSpacing),
              ExcludeSemantics(
                child: _buildCredentialCard(
                  _expandedCardHeight,
                  onTap: () => _showFullScreenCard(context),
                ),
              ),
              SizedBox(height: theme.mediumSpacing),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    credentialName,
                    style: theme.themeData.textTheme.headlineMedium!.copyWith(
                      color: theme.dark,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (issuerName != null)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: theme.tinySpacing,
                      ),
                      child: TranslatedText(
                        "credential.issued_by",
                        style: theme.themeData.textTheme.bodyMedium,
                        translationParams: {"issuer": issuerName!},
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FullScreenCardDialog extends StatelessWidget {
  final CredentialType credentialType;
  final List<Attribute>? attributes;

  const _FullScreenCardDialog({
    required this.credentialType,
    this.attributes,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = 24.0;
    final cardWidth = screenWidth - (padding * 2);
    // Maintain credit card aspect ratio (340:215)
    final cardHeight = cardWidth * (215 / 340);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(padding),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent tap from closing when tapping on card
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CredentialCardImage(
                  credentialType: credentialType,
                  attributes: attributes,
                  width: cardWidth,
                  height: cardHeight,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
