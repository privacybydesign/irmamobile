import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../data/feature_flags.dart";
import "../providers/feature_flag_provider.dart";
import "../theme/theme.dart";

const _groupRadius = 12.0;

/// Where a [YiviTextField] is as a row of a [YiviFieldGroup].
enum YiviFieldRowPosition { inner, last }

/// Fields that belong together, such as the rows of a document's manual entry.
///
/// With [FeatureFlag.formFieldsV2] on they are the rows of one white card, and
/// a [YiviTextField] inside renders as a row that draws its own divider. With
/// the flag off they are stacked with a gap, as before.
class YiviFieldGroup extends ConsumerWidget {
  final List<Widget> children;

  const YiviFieldGroup({super.key, required this.children});

  /// The position of the row that [context] is in, or null when [context] is
  /// not below a [YiviFieldGroup] that renders as a card.
  static YiviFieldRowPosition? rowPosition(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_YiviFieldRowScope>()
      ?.position;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);
    final formFieldsV2 =
        ref.watch(featureFlagProvider(FeatureFlag.formFieldsV2)).value ?? false;

    final radius = formFieldsV2
        ? BorderRadius.circular(_groupRadius)
        : BorderRadius.zero;
    final gap = formFieldsV2 ? 0.0 : theme.mediumSpacing;

    YiviFieldRowPosition? positionOf(int i) {
      if (!formFieldsV2) {
        return null;
      }

      return i == children.length - 1
          ? YiviFieldRowPosition.last
          : YiviFieldRowPosition.inner;
    }

    // The same widgets with the flag off and on, so that a field is not
    // rebuilt from scratch, losing its focus, when the flag value arrives a
    // frame after the screen opens.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: formFieldsV2 ? theme.light : null,
        borderRadius: radius,
        boxShadow: formFieldsV2
            ? [
                BoxShadow(
                  color: Colors.grey.shade300,
                  offset: const Offset(0.0, 1.0),
                  blurRadius: 6.0,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        clipBehavior: formFieldsV2 ? Clip.antiAlias : Clip.none,
        child: Column(
          crossAxisAlignment: formFieldsV2
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.start,
          children: [
            for (final (i, child) in children.indexed)
              _YiviFieldRowScope(
                position: positionOf(i),
                child: Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : gap),
                  child: child,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _YiviFieldRowScope extends InheritedWidget {
  final YiviFieldRowPosition? position;

  const _YiviFieldRowScope({required this.position, required super.child});

  @override
  bool updateShouldNotify(_YiviFieldRowScope oldWidget) =>
      position != oldWidget.position;
}
