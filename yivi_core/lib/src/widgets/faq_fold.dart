import "dart:io";

import "package:flutter/semantics.dart";
import "package:material_ui/material_ui.dart";

import "../theme/yivi_motion.dart";
import "../theme/yivi_palette.dart";
import "../theme/yivi_space.dart";
import "../util/i18n.dart";
import "../util/reveal_whole.dart";

/// A question that folds open to its [answer]: a row in a group, with a
/// chevron that turns. Once open (with [revealOnOpen]), the page scrolls so
/// the whole answer is in view, as far as a bar over the top allows.
class FaqFold extends StatefulWidget {
  final String question;
  final Widget answer;
  final bool revealOnOpen;

  const FaqFold({
    super.key,
    required this.question,
    required this.answer,
    this.revealOnOpen = true,
  });

  @override
  State<FaqFold> createState() => _FaqFoldState();
}

class _FaqFoldState extends State<FaqFold> {
  bool _open = false;

  Future<void> _toggle(Duration grow) async {
    setState(() => _open = !_open);
    // TalkBack does not read a changed expanded state by itself.
    if (Platform.isAndroid) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        context.tr(
          _open ? "accessibility.expanded" : "accessibility.collapsed",
        ),
        Directionality.of(context),
      );
    }
    if (!_open || !widget.revealOnOpen) return;
    await Future<void>.delayed(grow);
    if (!mounted) return;
    final scrollable = Scrollable.maybeOf(context, axis: Axis.vertical);
    if (scrollable == null) return;
    revealWhole(
      context,
      // The bar covers the top of a page that scrolls under it.
      topInset: MediaQuery.paddingOf(scrollable.context).top,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final duration = YiviMotion.duration(context, YiviMotion.quick);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          child: InkWell(
            onTap: () => _toggle(duration),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.all(YiviSpace.x16),
                child: Row(
                  spacing: YiviSpace.x12,
                  children: [
                    Expanded(
                      child: Text(
                        widget.question,
                        style: palette
                            .display(15)
                            .copyWith(height: 21 / 15, color: palette.text),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: duration,
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 22,
                        color: palette.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: duration,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _open
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(
                    YiviSpace.x16,
                    0,
                    YiviSpace.x16,
                    YiviSpace.x16,
                  ),
                  child: DefaultTextStyle.merge(
                    style: palette.paragraph.copyWith(
                      height: 22 / 15,
                      color: palette.heading,
                    ),
                    child: widget.answer,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
