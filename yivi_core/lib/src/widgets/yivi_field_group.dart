import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../data/feature_flags.dart";
import "../providers/feature_flag_provider.dart";
import "../theme/theme.dart";
import "irma_divider.dart";

const _groupRadius = 12.0;

/// Fields that belong together, such as the rows of a document's manual entry.
///
/// With [FeatureFlag.formFieldsV2] on they are the rows of one white card,
/// separated by dividers, and a [YiviTextField] inside renders as a row. With
/// the flag off they are stacked with a gap, as before.
class YiviFieldGroup extends ConsumerWidget {
  final List<Widget> children;

  const YiviFieldGroup({super.key, required this.children});

  /// Whether [context] is below a [YiviFieldGroup] that renders as a card.
  static bool contains(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_YiviFieldGroupScope>() != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);
    final formFieldsV2 =
        ref.watch(featureFlagProvider(FeatureFlag.formFieldsV2)).value ?? false;

    if (!formFieldsV2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) SizedBox(height: theme.mediumSpacing),
            child,
          ],
        ],
      );
    }

    return _YiviFieldGroupScope(
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.light,
          borderRadius: BorderRadius.circular(_groupRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              offset: const Offset(0.0, 1.0),
              blurRadius: 6.0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0) const IrmaDivider(),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

class _YiviFieldGroupScope extends InheritedWidget {
  const _YiviFieldGroupScope({required super.child});

  @override
  bool updateShouldNotify(_YiviFieldGroupScope oldWidget) => false;
}
