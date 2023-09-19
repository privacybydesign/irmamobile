import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../models/session.dart';
import '../theme/theme.dart';
import 'irma_avatar.dart';
import 'irma_card.dart';
import 'irma_icon_indicator.dart';
import 'requestor_verification_explanation_bottom_sheet.dart';
import 'translated_text.dart';

_buildRequestorAvatar({
  required String? title,
  Image? image,
  String? imagePath,
}) =>
    IrmaAvatar(
      size: 52,
      logoImage: image,
      logoPath: imagePath,
      logoSemanticsLabel: title,
      initials: title != '' ? title![0] : null,
    );

class RequestorHeader extends StatelessWidget {
  final RequestorInfo? requestorInfo;
  final bool? isVerified;

  const RequestorHeader({
    this.requestorInfo,
    this.isVerified,
  });

  _showCredentialOptionsBottomSheet(BuildContext context) async => showModalBottomSheet<void>(
        context: context,
        builder: (context) => RequestorVerificationExplanationBottomSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final theme = IrmaTheme.of(context);

    Widget mainTextWidget;
    Widget? subtitleTextWidget;
    Color? backgroundColorOverride;

    final localizedRequestorName = requestorInfo != null
        ? requestorInfo!.name.translate(lang)
        : FlutterI18n.translate(
            context,
            'ui.unknown',
          );

    Widget requestorAvatar = _buildRequestorAvatar(
      title: localizedRequestorName,
      imagePath: requestorInfo?.logoPath,
    );

    if (isVerified != null) {
      final mainTextDefaultStyle = theme.themeData.textTheme.bodyMedium;
      String mainTextSuffixTranslationKey;
      const double opacity = 0.15;

      // Set the subtitleTextWidget to a link
      subtitleTextWidget = GestureDetector(
        onTap: () => _showCredentialOptionsBottomSheet(context),
        child: TranslatedText(
          'disclosure_permission.overview.requestor_verification.explanation',
          style: theme.hyperlinkTextStyle,
        ),
      );

      if (isVerified!) {
        backgroundColorOverride = theme.success.withOpacity(opacity);
        mainTextSuffixTranslationKey = 'disclosure_permission.overview.requestor_verification.verified_suffix';
      } else {
        backgroundColorOverride = theme.error.withOpacity(opacity);
        mainTextSuffixTranslationKey = 'disclosure_permission.overview.requestor_verification.unverified_suffix';
      }

      // Wrap the avatar in a Stack and position the verification status indicator
      requestorAvatar = Stack(
        children: [
          requestorAvatar,
          Positioned(
            top: 0,
            right: 0,
            child: IrmaStatusIndicator(
              success: isVerified!,
            ),
          ),
        ],
      );

      String translatedMainTextSuffix = FlutterI18n.translate(
        context,
        mainTextSuffixTranslationKey,
      );

      mainTextWidget = RichText(
        key: const Key('requestor_header_main_text'),
        text: TextSpan(
          children: [
            TextSpan(
              text: localizedRequestorName + ' ',
              style: mainTextDefaultStyle!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: translatedMainTextSuffix,
              style: mainTextDefaultStyle,
            )
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

class IssueWizardRequestorHeader extends StatelessWidget {
  final String? title;
  final Image? image;
  final Color? backgroundColor;
  final Color? textColor;

  const IssueWizardRequestorHeader({
    this.title,
    this.image,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) => _RequestorHeaderBase(
        textColor: textColor,
        backgroundColor: backgroundColor,
        avatar: _buildRequestorAvatar(
          title: title,
          image: image,
        ),
        mainText: Text(
          title ?? '',
          style: IrmaTheme.of(context).themeData.textTheme.headlineMedium,
        ),
      );
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
      margin: EdgeInsets.all(
        theme.smallSpacing,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          avatar,
          SizedBox(
            width: theme.smallSpacing,
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                mainText,
                if (subtitleText != null) subtitleText!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
