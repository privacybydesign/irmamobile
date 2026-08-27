import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../models/schemaless/schemaless_events.dart";
import "../models/schemaless/session_state.dart";
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
  return IrmaAvatar(
    size: 48,
    logoImage: image,
    logoPath: imagePath,
    logoSemanticsLabel: title,
    initials: title != "" ? title![0] : null,
  );
}

/// The three states a [RequestorHeader] can be in.
///
/// `vouched` and `warning` are the two visual states; `levelless` is the plain
/// card shown for a party whose trust level was never evaluated — no colour and
/// no indicator, because absent evidence is not a verdict.
enum HeaderState { vouched, warning, levelless }

/// Whether [party]'s trust level clears the bar for a session of [sessionType],
/// which is the only thing that decides which header the user sees.
///
/// The bar is not the same for both directions: an issuer is vouched for at
/// medium — somebody attested its identity, even if not Yivi — while a verifier
/// needs high, because Yivi itself must vouch before data leaves the wallet. A
/// signature session takes the verifier's bar; it releases attributes too.
///
/// A null [sessionType] asks for no verdict at all (the activity log's
/// disclosure detail), and a party with no rung cannot be given one.
HeaderState requestorHeaderState(
  TrustedParty? party,
  SessionType? sessionType,
) {
  final level = party?.trustLevel;
  if (sessionType == null || level == null) return HeaderState.levelless;

  final isVerified = switch (sessionType) {
    SessionType.issuance =>
      level == TrustLevel.high || level == TrustLevel.medium,
    SessionType.disclosure || SessionType.signature => level == TrustLevel.high,
  };
  return isVerified ? HeaderState.vouched : HeaderState.warning;
}

/// The translation keys for the sentence after the party's name. Keyed by
/// session type, because the two directions read differently: a verifier is
/// asking for data, an issuer is offering it.
///
/// The issuance keys deliberately avoid claiming Yivi vouches: that state spans
/// medium and high, and at medium it is an external CA that attested the
/// identity. The disclosure keys can make the stronger claim, since their
/// vouched state only ever occurs at high.
({String vouched, String warning}) _suffixKeys(
  SessionType sessionType,
) => switch (sessionType) {
  SessionType.issuance => (
    vouched: "issuance.requestor_verification.vouched_suffix",
    warning: "issuance.requestor_verification.warning_suffix",
  ),
  SessionType.disclosure || SessionType.signature => (
    vouched:
        "disclosure_permission.overview.requestor_verification.verified_suffix",
    warning:
        "disclosure_permission.overview.requestor_verification.unverified_suffix",
  ),
};

class RequestorHeader extends StatelessWidget {
  final TrustedParty? requestor;

  /// What the session is doing, which sets both the trust bar and the copy.
  /// Null renders the levelless card — used by the activity log, which shows
  /// who a party was without re-judging them.
  final SessionType? sessionType;

  const RequestorHeader({super.key, this.requestor, this.sessionType});

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

    final state = requestorHeaderState(requestor, sessionType);

    if (state != HeaderState.levelless) {
      final isVerified = state == HeaderState.vouched;
      final mainTextDefaultStyle = theme.themeData.textTheme.bodyMedium;
      final suffixKeys = _suffixKeys(sessionType!);

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

      backgroundColorOverride = isVerified
          ? theme.successSurface
          : theme.errorSurface;

      // Wrap the avatar in a Stack and position the verification status indicator
      requestorAvatar = Stack(
        children: [
          requestorAvatar,
          Positioned(
            top: 0,
            right: 0,
            child: IrmaStatusIndicator(success: isVerified),
          ),
        ],
      );

      String translatedMainTextSuffix = FlutterI18n.translate(
        context,
        isVerified ? suffixKeys.vouched : suffixKeys.warning,
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
