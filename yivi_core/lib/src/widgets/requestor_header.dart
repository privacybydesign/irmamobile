import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../models/schemaless/schemaless_events.dart";
import "../theme/theme.dart";
import "base64_image.dart";
import "irma_avatar.dart";
import "irma_card.dart";
import "irma_icon_indicator.dart";
import "requestor_verification_explanation_bottom_sheet.dart";
import "translated_text.dart";
import "yivi_bottom_sheet.dart";

_buildRequestorAvatar({
  required String? title,
  Widget? image,
  String? imagePath,
}) {
  return IrmaAvatar(
    size: 48,
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

  _showCredentialOptionsBottomSheet(BuildContext context) {
    return showYiviBottomSheet(
      context: context,
      titleKey:
          "disclosure_permission.overview.requestor_verification.bottom_sheet.title",
      // One-off lighter weight (w500 instead of titleLarge's w600) for this
      // sheet — kept inline rather than promoted to a TextTheme slot since
      // no other caller uses this specific tuple.
      titleStyle: context.text.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      child: RequestorVerificationExplanationBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    Widget mainTextWidget;
    Widget? subtitleTextWidget;
    Color? backgroundColorOverride;

    final localizedRequestorName = requestor != null
        ? requestor!.name.translate(lang)
        : FlutterI18n.translate(context, "ui.unknown");

    Widget requestorAvatar = _buildRequestorAvatar(
      title: localizedRequestorName,
      image: requestor?.image != null
          ? Base64Image(base64: requestor!.image!.base64)
          : null,
      imagePath: requestor?.imagePath,
    );

    if (isVerified != null) {
      final mainTextDefaultStyle = context.text.bodyMedium;
      String mainTextSuffixTranslationKey;

      // Set the subtitleTextWidget to a link
      subtitleTextWidget = Padding(
        padding: EdgeInsets.only(top: context.yivi.defaultSpacing),
        child: GestureDetector(
          onTap: () => _showCredentialOptionsBottomSheet(context),
          child: TranslatedText(
            "disclosure_permission.overview.requestor_verification.explanation",
            style: context.text.bodyMedium?.copyWith(
              color: context.yivi.brand.link,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      );

      if (isVerified!) {
        backgroundColorOverride = context.yivi.brand.successSurface;
        mainTextSuffixTranslationKey =
            "disclosure_permission.overview.requestor_verification.verified_suffix";
      } else {
        backgroundColorOverride = context.colors.errorContainer;
        mainTextSuffixTranslationKey =
            "disclosure_permission.overview.requestor_verification.unverified_suffix";
      }

      // Wrap the avatar in a Stack and position the verification status indicator
      requestorAvatar = Stack(
        children: [
          requestorAvatar,
          Positioned(
            top: 0,
            right: 0,
            child: IrmaStatusIndicator(success: isVerified!),
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
              style: mainTextDefaultStyle!.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
        style: context.text.titleSmall,
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
      mainText: Text(title ?? "", style: context.text.titleMedium),
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
    return IrmaCard(
      color: backgroundColor,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.all(context.yivi.defaultSpacing),
      child: Row(
        crossAxisAlignment: subtitleText != null
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(right: context.yivi.tinySpacing),
            child: avatar,
          ),
          SizedBox(width: context.yivi.smallSpacing),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [mainText, if (subtitleText != null) subtitleText!],
            ),
          ),
        ],
      ),
    );
  }
}
