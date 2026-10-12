import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart";
import "../../../theme/theme.dart";
import "../../../widgets/base64_image.dart";
import "../../../widgets/irma_avatar.dart";
import "../../../widgets/missing_data_icon.dart";
import "../../../widgets/missing_data_style.dart";

enum MissingDataPhase { collecting, ready }

const _toReadyDuration = Duration(milliseconds: 600);
const _sidePadding = 20.0;
const _collectingVerticalPadding = 20.0;
const _readyVerticalPadding = 28.0;
const _collectingLogoSize = 52.0;
const _readyLogoSize = 64.0;
const _logoRingWidth = 3.0;
const _logoGap = 14.0;
const _closeButtonSize = 48.0;
const _closeButtonOffset = 4.0;
const _closeIconSize = 22.0;
const _titleEndPadding = 36.0;
const _maxInitials = 2;
const _halfway = 0.5;

// The status bar sits on top of the header, which turns from white to blue.
SystemUiOverlayStyle _darkIcons(IrmaThemeData theme) =>
    theme.themeData.appBarTheme.systemOverlayStyle!;

SystemUiOverlayStyle _lightIcons(IrmaThemeData theme) =>
    _darkIcons(theme).copyWith(
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    );

/// Header of the missing data checklist. While [MissingDataPhase.collecting]
/// it is a white block with the requestor; in [MissingDataPhase.ready] it fades
/// to blue and puts the requestor up front, because the same screen is where
/// the user shares.
class MissingDataHeader extends StatelessWidget {
  final TrustedParty requestor;
  final MissingDataPhase phase;
  final int total;
  final VoidCallback onDismiss;

  const MissingDataHeader({
    super.key,
    required this.requestor,
    required this.phase,
    required this.total,
    required this.onDismiss,
  });

  String _plural(BuildContext context, String key) {
    return FlutterI18n.translate(
      context,
      total == 1 ? "$key.one" : "$key.other",
      translationParams: {"requestor": requestor.name, "n": "$total"},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final ready = phase == MissingDataPhase.ready;
    final inset = MediaQuery.paddingOf(context).top;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _toReadyDuration;
    final verticalPadding = ready
        ? _readyVerticalPadding
        : _collectingVerticalPadding;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: ready ? 1 : 0),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, t, _) {
        final background = Color.lerp(theme.light, theme.link, t)!;
        final foreground = Color.lerp(theme.neutralExtraDark, theme.light, t)!;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: t < _halfway ? _darkIcons(theme) : _lightIcons(theme),
          child: Container(
            key: const Key("missing_data_header"),
            width: double.infinity,
            decoration: BoxDecoration(
              color: background,
              border: Border(
                bottom: BorderSide(
                  color: Color.lerp(theme.neutralExtraLight, theme.link, t)!,
                ),
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    _sidePadding,
                    inset + verticalPadding,
                    _sidePadding,
                    verticalPadding,
                  ),
                  child: ready
                      ? _buildReady(context, foreground)
                      : _buildCollecting(context, foreground),
                ),
                Positioned(
                  top: inset + _closeButtonOffset,
                  right: _closeButtonOffset,
                  child: _CloseButton(
                    color: Color.lerp(theme.dark, missingDataCloseOnBlue, t)!,
                    onTap: onDismiss,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollecting(BuildContext context, Color foreground) {
    final theme = IrmaTheme.of(context);
    final verified = requestor.verified;
    final partyKey = verified
        ? "missing_data.known_party"
        : "missing_data.unknown_party";

    return Row(
      children: [
        _RequestorLogo(
          requestor: requestor,
          size: _collectingLogoSize,
          phase: MissingDataPhase.collecting,
        ),
        const SizedBox(width: _logoGap),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: _titleEndPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    _plural(context, "missing_data.header"),
                    style: missingDataHeadingStyle(
                      theme,
                    ).copyWith(color: foreground),
                  ),
                ),
                Text(
                  FlutterI18n.translate(context, partyKey),
                  style: theme.textTheme.labelSmall!.copyWith(
                    fontSize: 13,
                    height: 18 / 13,
                    color: verified
                        ? missingDataSuccessText
                        : theme.neutralExtraDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReady(BuildContext context, Color foreground) {
    final theme = IrmaTheme.of(context);

    return Column(
      spacing: 10,
      children: [
        _RequestorLogo(
          requestor: requestor,
          size: _readyLogoSize,
          phase: MissingDataPhase.ready,
        ),
        Semantics(
          header: true,
          child: Text(
            FlutterI18n.translate(context, "missing_data.ready_title"),
            textAlign: TextAlign.center,
            style: theme.textTheme.displayMedium!.copyWith(
              height: 32 / 24,
              color: foreground,
            ),
          ),
        ),
        Text(
          _plural(context, "missing_data.share_question"),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium!.copyWith(color: foreground),
        ),
      ],
    );
  }
}

String _initials(String name) {
  final words = name.split(RegExp(r"\s+")).where((w) => w.isNotEmpty);
  final initials = words
      .take(_maxInitials)
      .map((w) => w.characters.first)
      .join();

  return initials.isEmpty ? "?" : initials.toUpperCase();
}

/// The logo of the requestor, or its initials in a blue circle (white while
/// [MissingDataPhase.ready], with a ring) when it has none.
class _RequestorLogo extends StatelessWidget {
  final TrustedParty requestor;
  final double size;
  final MissingDataPhase phase;

  const _RequestorLogo({
    required this.requestor,
    required this.size,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final ready = phase == MissingDataPhase.ready;
    final image = requestor.image;

    final Widget logo;
    if (image != null || requestor.imagePath != null) {
      logo = IrmaAvatar(
        size: size,
        logoImage: image != null
            ? Base64Image(base64: image.base64, mimeType: image.mimeType)
            : null,
        logoPath: requestor.imagePath,
        logoSemanticsLabel: requestor.name,
        initials: _initials(requestor.name),
      );
    } else {
      logo = ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ready ? theme.light : theme.link,
          ),
          child: Text(
            _initials(requestor.name),
            style: theme.textTheme.labelLarge!.copyWith(
              fontSize: ready ? 22 : 18,
              height: 1,
              color: ready ? theme.link : theme.light,
            ),
          ),
        ),
      );
    }
    if (!ready) return logo;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: theme.tertiary, spreadRadius: _logoRingWidth),
        ],
      ),
      child: logo,
    );
  }
}

class _CloseButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _CloseButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: FlutterI18n.translate(context, "accessibility.close"),
      excludeSemantics: true,
      onTap: onTap,
      child: SizedBox.square(
        dimension: _closeButtonSize,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: MissingDataIcon(
              size: _closeIconSize,
              lines: const [
                [Offset(6, 6), Offset(18, 18)],
                [Offset(18, 6), Offset(6, 18)],
              ],
              strokeWidth: 2,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
