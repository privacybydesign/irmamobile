import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../models/schemaless/schemaless_events.dart";
import "../theme/theme.dart";
import "base64_image.dart";
import "bold_markers_text.dart";
import "credential_card/yivi_credential_card_header.dart";
import "irma_avatar.dart";
import "irma_card.dart";
import "irma_icon_indicator.dart";
import "requestor_verification_explanation_bottom_sheet.dart";
import "translated_text.dart";

IrmaAvatar _buildRequestorAvatar({
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

    if (isVerified != null) {
      final mainTextDefaultStyle = theme.themeData.textTheme.bodyMedium;
      String mainTextSuffixTranslationKey;

      // Set the subtitleTextWidget to a link
      subtitleTextWidget = Padding(
        padding: EdgeInsets.only(top: theme.defaultSpacing),
        child: GestureDetector(
          onTap: () => showVerificationSheet(context),
          child: TranslatedText(
            "disclosure_permission.overview.requestor_verification.explanation",
            style: theme.hyperlinkTextStyle.copyWith(
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      );

      if (isVerified!) {
        backgroundColorOverride = theme.successSurface;
        mainTextSuffixTranslationKey =
            "disclosure_permission.overview.requestor_verification.verified_suffix";
      } else {
        backgroundColorOverride = theme.errorSurface;
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

/// Header of the share screen: the requestor logo next to a share icon, above
/// the sentence "Share your data with X".
class ShareRequestorHeader extends StatelessWidget {
  final TrustedParty requestor;

  const ShareRequestorHeader({required this.requestor});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Column(
      crossAxisAlignment: .start,
      children: [
        Row(
          spacing: theme.smallSpacing,
          children: [
            _buildRequestorAvatar(
              title: requestor.name,
              image: requestor.image != null
                  ? Base64Image(
                      base64: requestor.image!.base64,
                      mimeType: requestor.image!.mimeType,
                    )
                  : null,
              imagePath: requestor.imagePath,
            ),
            ExcludeSemantics(
              child: Icon(Icons.share_outlined, color: theme.neutralDark),
            ),
          ],
        ),
        SizedBox(height: theme.defaultSpacing),
        Semantics(
          header: true,
          child: BoldMarkersText(
            "disclosure_permission.share_v2.title",
            translationParams: {"requestorName": requestor.name},
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
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

    return IrmaCard(
      color: backgroundColor,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.all(theme.defaultSpacing),
      child: Row(
        crossAxisAlignment: subtitleText != null
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(right: theme.tinySpacing),
            child: avatar,
          ),
          SizedBox(width: theme.smallSpacing),
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
