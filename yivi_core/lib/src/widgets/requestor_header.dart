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

void _showRequestorVerificationBottomSheet(BuildContext context) {
  showYiviBottomSheet(
    context: context,
    titleKey:
        "disclosure_permission.overview.requestor_verification.bottom_sheet.title",
    child: RequestorVerificationExplanationBottomSheet(),
  );
}

class RequestorHeader extends StatelessWidget {
  final TrustedParty? requestor;
  final bool? isVerified;
  final String verifiedSuffixKey;
  final String unverifiedSuffixKey;

  const RequestorHeader({
    this.requestor,
    this.isVerified,
    required this.verifiedSuffixKey,
    required this.unverifiedSuffixKey,
  });

  @override
  Widget build(BuildContext context) {
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final theme = IrmaTheme.of(context);

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
      final mainTextDefaultStyle = theme.themeData.textTheme.bodyMedium;
      String mainTextSuffixTranslationKey;
      const int opacity = 40;

      // Set the subtitleTextWidget to a link
      subtitleTextWidget = Padding(
        padding: EdgeInsets.only(top: theme.defaultSpacing),
        child: GestureDetector(
          onTap: () => _showRequestorVerificationBottomSheet(context),
          child: TranslatedText(
            "disclosure_permission.overview.requestor_verification.explanation",
            style: theme.hyperlinkTextStyle.copyWith(
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      );

      if (isVerified!) {
        backgroundColorOverride = theme.success.withAlpha(opacity);
        mainTextSuffixTranslationKey = verifiedSuffixKey;
      } else {
        backgroundColorOverride = theme.error.withAlpha(opacity);
        mainTextSuffixTranslationKey = unverifiedSuffixKey;
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
        style: theme.themeData.textTheme.headlineMedium,
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

/// Header for issuance-context screens. Picks between a single
/// [RequestorHeader] when every issuer in [issuers] shares the same id, and a
/// [MultiIssuerBanner] when more than one distinct issuer is offering
/// credentials. Multiple distinct issuers can only occur in IRMA sessions —
/// OpenID4VCI sessions are always single-issuer.
class IssuersHeader extends StatelessWidget {
  final List<TrustedParty> issuers;

  const IssuersHeader({super.key, required this.issuers})
    : assert(issuers.length > 0, "IssuersHeader requires at least one issuer");

  @override
  Widget build(BuildContext context) {
    final allSameId = issuers.map((i) => i.id).toSet().length == 1;
    if (allSameId) {
      final issuer = issuers.first;
      return RequestorHeader(
        requestor: issuer,
        isVerified: issuer.verified,
        verifiedSuffixKey: "issuance.requestor_verification.verified_suffix",
        unverifiedSuffixKey:
            "issuance.requestor_verification.unverified_suffix",
      );
    }
    return MultiIssuerBanner(
      isAllVerified: issuers.every((i) => i.verified),
    );
  }
}

/// Card shown when several distinct issuers are offering credentials in a
/// single IRMA issuance session. Mirrors [RequestorHeader]'s card/color style
/// but uses a collective icon instead of a single avatar, since there is no
/// single party to attribute the request to.
class MultiIssuerBanner extends StatelessWidget {
  final bool isAllVerified;

  const MultiIssuerBanner({super.key, required this.isAllVerified});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final mainTextDefaultStyle = theme.themeData.textTheme.bodyMedium!;
    const int opacity = 40;

    final boldKey = isAllVerified
        ? "issuance.requestor_verification.multi_issuer_verified_bold"
        : "issuance.requestor_verification.multi_issuer_unverified_bold";
    final suffixKey = isAllVerified
        ? "issuance.requestor_verification.multi_issuer_verified_suffix"
        : "issuance.requestor_verification.multi_issuer_unverified_suffix";

    final backgroundColor = (isAllVerified ? theme.success : theme.error)
        .withAlpha(opacity);

    return _RequestorHeaderBase(
      backgroundColor: backgroundColor,
      avatar: Icon(Icons.groups, size: 48, color: theme.neutralExtraDark),
      mainText: RichText(
        key: const Key("multi_issuer_banner_main_text"),
        text: TextSpan(
          children: [
            TextSpan(
              text: FlutterI18n.translate(context, boldKey),
              style: mainTextDefaultStyle.copyWith(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: FlutterI18n.translate(context, suffixKey),
              style: mainTextDefaultStyle,
            ),
          ],
        ),
      ),
      subtitleText: Padding(
        padding: EdgeInsets.only(top: theme.defaultSpacing),
        child: GestureDetector(
          onTap: () => _showRequestorVerificationBottomSheet(context),
          child: TranslatedText(
            "disclosure_permission.overview.requestor_verification.explanation",
            style: theme.hyperlinkTextStyle.copyWith(
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ),
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
      hasShadow: false,
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
              children: [mainText, if (subtitleText != null) subtitleText!],
            ),
          ),
        ],
      ),
    );
  }
}
