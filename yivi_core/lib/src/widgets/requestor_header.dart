import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../models/schemaless/schemaless_events.dart";
import "../theme/theme.dart";
import "base64_image.dart";
import "credential_card/yivi_credential_card_header.dart";
import "irma_avatar.dart";
import "irma_card.dart";
import "irma_icon_indicator.dart";
import "requestor_verification_explanation_bottom_sheet.dart";
import "translated_text.dart";
import "yivi_bottom_sheet.dart";

IrmaAvatar _buildRequestorAvatar({
  required String? title,
  Widget? image,
  String? imagePath,
}) {
  // IrmaAvatar asserts that it has something to draw, so decide what that is
  // before calling it rather than discovering it inside.
  //
  // The previous expression was `title != "" ? title![0] : null`, with a hole at
  // each end: an EMPTY title yielded neither initials nor image and tripped the
  // assertion, while a NULL title took the true branch — null is not "" — and
  // died on the null check. Both are reachable from a requestor with no name,
  // which is what a request delivered over the Digital Credentials API is.
  final hasLogo = image != null || imagePath != null;
  final initial = (title != null && title.isNotEmpty) ? title[0] : null;

  return IrmaAvatar(
    size: 48,
    // A neutral glyph is the honest rendering for a party with no name and no
    // logo: it says an address is asking, which is what is actually known. A
    // letter taken from the origin would read as a name nobody supplied.
    logoImage: hasLogo || initial != null
        ? image
        : const Icon(Icons.language, size: 24),
    logoPath: imagePath,
    logoSemanticsLabel: title,
    initials: hasLogo ? null : initial,
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

    // An anonymous requestor has an empty name on purpose: nothing identified
    // itself, and the origin the platform authenticated is the only thing known
    // about it. Showing that is honest; showing "unknown" would hide the one
    // fact the user has to judge, and inventing a name from the origin would
    // dress an address up as an identity.
    final isAnonymous = requestor?.anonymous ?? false;
    final localizedRequestorName = requestor == null
        ? FlutterI18n.translate(context, "ui.unknown")
        : (isAnonymous
              ? (requestor!.origin ??
                    FlutterI18n.translate(context, "ui.unknown"))
              : requestor!.name);

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
          onTap: () => _showCredentialOptionsBottomSheet(context),
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
