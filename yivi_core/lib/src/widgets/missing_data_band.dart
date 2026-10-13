import "dart:math";

import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../models/missing_data_checklist.dart";
import "../models/schemaless/credential_store.dart";
import "../providers/missing_data_flow_provider.dart";
import "../theme/theme.dart";
import "base64_image.dart";
import "irma_avatar.dart";
import "missing_data_check.dart";
import "missing_data_style.dart";

const _iconSize = 32.0;
const _ringWidth = 2.0;
const _iconGap = 6.0;
const _dimmedOpacity = 0.4;
const _progressBarHeight = 6.0;
const _labelBarGap = 6.0;
const _labelLineHeight = 18.0;
const _maxLabelLines = 2;
const _borderWidth = 1.0;
const _sidePadding = 16.0;
const _iconsEndPadding = 12.0;
const _iconsGap = 8.0;
const _labelVerticalPadding = 4.0;
const _bandVerticalPadding = 6.0;
const _badgeOffset = -3.0;

// The ring is drawn outside the icon, so the box that scrolls the icons has
// room for it on every side.
const _ringRoom = 2 * _ringWidth;
const _iconBoxSize = _iconSize + 2 * _ringRoom;

// Where the icons run out of room, they scroll.
const _maxIconsShare = 0.5;

String _label(BuildContext context, MissingDataBandState band) {
  return FlutterI18n.translate(
    context,
    "missing_data.band",
    translationParams: {
      "requestor": band.requestorName,
      "x": "${band.checklist.presentCount}",
      "n": "${band.checklist.total}",
    },
  );
}

double _iconsWidth(double screenWidth, int count) {
  if (count == 0) return 0;

  final needed = count * _iconSize + (count - 1) * _iconGap + 2 * _ringRoom;
  final room = screenWidth - _sidePadding - _iconsEndPadding - _iconsGap;

  return min(needed, room * _maxIconsShare);
}

/// Shows which request the user is collecting data for, and how far along
/// they are, as the bottom of the app bar of an issuance screen: the
/// progress on the left and the requested credentials as icons on the right.
/// Blank unless the user came from the missing data checklist.
///
/// An app bar needs to know the height of its bottom up front, so the band
/// has a fixed [height]. Get one with [MissingDataFlowNavigation.missingDataBand]
/// rather than building it.
class MissingDataBand extends ConsumerWidget implements PreferredSizeWidget {
  final double height;

  const MissingDataBand({super.key, required this.height});

  /// The height of the band for [band] with the current theme, text scale and
  /// screen width: the label wraps onto a second line when the icons leave it
  /// too little room.
  static double heightFor(BuildContext context, MissingDataBandState? band) {
    final theme = IrmaTheme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final count = band?.checklist.total ?? 0;

    var labelHeight = _labelLineHeight * 2;
    if (band != null) {
      final labelWidth =
          width -
          _sidePadding -
          _iconsEndPadding -
          _iconsGap -
          _iconsWidth(width, count);
      final painter = TextPainter(
        text: TextSpan(
          text: _label(context, band),
          style: missingDataLabelStyle(theme),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: _maxLabelLines,
      )..layout(maxWidth: labelWidth);
      labelHeight = painter.height;
      painter.dispose();
    }

    final text =
        labelHeight +
        _labelBarGap +
        _progressBarHeight +
        2 * _labelVerticalPadding;

    return 2 * _borderWidth +
        2 * _bandVerticalPadding +
        max(text, _iconBoxSize);
  }

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final band = ref.watch(missingDataBandProvider);
    if (band == null) return SizedBox(height: height);

    final theme = IrmaTheme.of(context);
    final checklist = band.checklist;
    final iconsWidth = _iconsWidth(
      MediaQuery.sizeOf(context).width,
      checklist.total,
    );

    final semanticsLabel = FlutterI18n.translate(
      context,
      "missing_data.band_semantics",
      translationParams: {
        "requestor": band.requestorName,
        "x": "${checklist.presentCount}",
        "n": "${checklist.total}",
        "credential": band.currentName,
      },
    );

    return Semantics(
      container: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Container(
        key: const Key("missing_data_band"),
        height: height,
        padding: const EdgeInsets.fromLTRB(
          _sidePadding,
          _bandVerticalPadding,
          _iconsEndPadding,
          _bandVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: theme.light,
          border: Border.symmetric(
            horizontal: BorderSide(
              color: theme.neutralExtraLight,
              width: _borderWidth,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: _labelVerticalPadding,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: _labelBarGap,
                  children: [
                    Text(
                      _label(context, band),
                      maxLines: _maxLabelLines,
                      overflow: TextOverflow.ellipsis,
                      style: missingDataLabelStyle(theme),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        _progressBarHeight / 2,
                      ),
                      child: Container(
                        height: _progressBarHeight,
                        color: theme.neutralLight,
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: checklist.presentCount / checklist.total,
                          heightFactor: 1,
                          child: ColoredBox(color: theme.success),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: _iconsGap),
            ExcludeSemantics(
              child: SizedBox(
                width: iconsWidth,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(_ringRoom),
                  child: Row(
                    spacing: _iconGap,
                    children: [
                      for (final entry in checklist.entries)
                        _BandCredential(
                          credential: entry.credential,
                          state: _stateOf(entry, band.currentCredentialId),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _BandState { done, current, pending }

_BandState _stateOf(ChecklistEntry entry, String currentCredentialId) {
  if (entry.isPresent) return _BandState.done;

  return entry.credential.credentialId == currentCredentialId
      ? _BandState.current
      : _BandState.pending;
}

class _BandCredential extends StatelessWidget {
  final CredentialDescriptor credential;
  final _BandState state;

  const _BandCredential({required this.credential, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final image = credential.image;
    final isCurrent = state == _BandState.current;

    return Opacity(
      opacity: state == _BandState.pending ? _dimmedOpacity : 1,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // A white gap, then the ring, both outside the icon so they take no
          // room and the icons do not shift when the current one changes.
          DecoratedBox(
            key: isCurrent ? const Key("missing_data_band_ring") : null,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: isCurrent
                  ? [
                      BoxShadow(color: theme.primary, spreadRadius: _ringRoom),
                      BoxShadow(color: theme.light, spreadRadius: _ringWidth),
                    ]
                  : null,
            ),
            child: IrmaAvatar(
              size: _iconSize,
              logoImage: image != null
                  ? Base64Image(base64: image.base64, mimeType: image.mimeType)
                  : null,
              initials: credential.name.isNotEmpty ? credential.name[0] : "?",
            ),
          ),
          if (state == _BandState.done)
            Positioned(
              right: _badgeOffset,
              bottom: _badgeOffset,
              child: MissingDataBadge(
                key: Key("missing_data_band_done_${credential.credentialId}"),
              ),
            ),
        ],
      ),
    );
  }
}
