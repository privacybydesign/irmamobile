import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../models/schemaless/schemaless_events.dart";
import "../theme/theme.dart";
import "../theme/yivi_palette.dart";
import "base64_image.dart";
import "credential_card/yivi_credential_card_header.dart";
import "irma_avatar.dart";
import "requestor_verification_explanation_bottom_sheet.dart";
import "translated_text.dart";
import "yivi_bottom_sheet.dart";

IrmaAvatar _buildRequestorAvatar({
  required String? title,
  Widget? image,
  String? imagePath,
}) {
  return IrmaAvatar(
    size: 52,
    logoImage: image,
    logoPath: imagePath,
    logoSemanticsLabel: title,
    initials: title != "" ? title![0] : null,
  );
}

class RequestorHeader extends StatelessWidget {
  final TrustedParty? requestor;
  final bool? isVerified;

  const RequestorHeader({this.requestor, this.isVerified});

  Future<void> _showCredentialOptionsBottomSheet(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return showYiviBottomSheet(
      context: context,
      titleKey:
          "disclosure_permission.overview.requestor_verification.bottom_sheet.title",
      titleStyle: credentialNameStyle(
        theme,
        18,
      ).copyWith(fontWeight: FontWeight.w500),
      child: RequestorVerificationExplanationBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    Widget mainTextWidget;
    Widget? subtitleTextWidget;
    Color? backgroundColorOverride;

    final localizedRequestorName = requestor != null
        ? requestor!.name
        : FlutterI18n.translate(context, "ui.unknown");

    Widget requestorAvatar = _buildRequestorAvatar(
      title: localizedRequestorName,
      image: requestor?.image != null
          ? Base64Image(
              base64: requestor!.image!.base64,
              mimeType: requestor!.image!.mimeType,
            )
          : null,
      imagePath: requestor?.imagePath,
    );

    final palette = YiviPalette.of(context);
    if (isVerified != null) {
      final mainTextDefaultStyle = palette
          .body(15)
          .copyWith(height: 22 / 15, color: palette.text);
      String mainTextSuffixTranslationKey;

      // Set the subtitleTextWidget to a link
      subtitleTextWidget = Padding(
        padding: const EdgeInsets.only(top: 4),
        child: GestureDetector(
          onTap: () => _showCredentialOptionsBottomSheet(context),
          child: TranslatedText(
            "disclosure_permission.overview.requestor_verification.explanation",
            style: palette
                .body(14, weight: FontWeight.w700)
                .copyWith(
                  color: palette.link,
                  decoration: TextDecoration.underline,
                  decorationColor: palette.link,
                ),
          ),
        ),
      );

      if (isVerified!) {
        backgroundColorOverride = palette.successSurface;
        mainTextSuffixTranslationKey =
            "disclosure_permission.overview.requestor_verification.verified_suffix";
      } else {
        backgroundColorOverride = palette.errorSurface;
        mainTextSuffixTranslationKey =
            "disclosure_permission.overview.requestor_verification.unverified_suffix";
      }

      // Wrap the avatar in a Stack and position the verification status indicator
      requestorAvatar = Stack(
        clipBehavior: Clip.none,
        children: [
          requestorAvatar,
          Positioned(
            top: -2,
            right: -2,
            child: _StatusBadge(
              success: isVerified!,
              ring: backgroundColorOverride,
            ),
          ),
        ],
      );

      String translatedMainTextSuffix = FlutterI18n.translate(
        context,
        mainTextSuffixTranslationKey,
      );

      mainTextWidget = RichText(
        key: const Key("requestor_header_main_text"),
        text: TextSpan(
          children: [
            TextSpan(
              text: "$localizedRequestorName ",
              style: palette
                  .display(15, weight: FontWeight.w700)
                  .copyWith(height: 22 / 15, color: palette.text),
            ),
            TextSpan(
              text: translatedMainTextSuffix,
              style: mainTextDefaultStyle,
            ),
          ],
        ),
      );
    } else {
      mainTextWidget = Text(
        localizedRequestorName,
        style: credentialNameStyle(
          theme,
          16,
        ).copyWith(fontWeight: FontWeight.w500),
      );
    }

    return _RequestorHeaderBase(
      avatar: requestorAvatar,
      mainText: mainTextWidget,
      subtitleText: subtitleTextWidget,
      backgroundColor: backgroundColorOverride,
    );
  }
}

class IssueWizardRequestorHeader extends StatelessWidget {
  final String? title;
  final Widget? image;
  final Color? backgroundColor;
  final Color? textColor;

  const IssueWizardRequestorHeader({
    this.title,
    this.image,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return _RequestorHeaderBase(
      textColor: textColor,
      backgroundColor: backgroundColor,
      avatar: _buildRequestorAvatar(title: title, image: image),
      mainText: Text(
        title ?? "",
        style: IrmaTheme.of(context).themeData.textTheme.headlineMedium,
      ),
    );
  }
}

// Contains the shared default styling and behavior for the header of the issue wizard and the disclosure session
class _RequestorHeaderBase extends StatelessWidget {
  final Widget avatar;
  final Widget mainText;
  final Widget? subtitleText;
  final Color? backgroundColor;
  final Color? textColor;

  const _RequestorHeaderBase({
    required this.avatar,
    required this.mainText,
    this.subtitleText,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final palette = YiviPalette.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: theme.smallSpacing),
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: backgroundColor ?? palette.surface,
        shape: RoundedSuperellipseBorder(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          // The known-party box has a green edge, as in the design.
          side: backgroundColor == palette.successSurface
              ? BorderSide(color: palette.successOutline)
              : BorderSide.none,
        ),
      ),
      child: Row(
        crossAxisAlignment: subtitleText != null
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          avatar,
          const SizedBox(width: 16),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [mainText, ?subtitleText],
            ),
          ),
        ],
      ),
    );
  }
}

/// The green tick (or red cross) on the requestor's logo, ringed in the
/// box colour.
class _StatusBadge extends StatelessWidget {
  final bool success;
  final Color? ring;

  const _StatusBadge({required this.success, this.ring});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: success ? const Color(0xFF00973A) : palette.danger,
        shape: BoxShape.circle,
        border: Border.all(color: ring ?? palette.surface, width: 2),
      ),
      child: Icon(
        success ? Icons.check_rounded : Icons.close_rounded,
        size: 12,
        color: Colors.white,
      ),
    );
  }
}
