import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../theme/yivi_palette.dart";
import "../../util/adaptive_layout.dart";
import "glass_surface.dart";

/// Shows [builder]'s content in a floating glass sheet: inset 8 from the
/// screen edges, with rounded corners all round and a handle, as in the
/// design. On tablets it is a centred dialog with the same look.
///
/// The content usually starts with a [GlassSheetHeader].
Future<T?> showGlassSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  if (isExpandedLayout(context)) {
    return showDialog<T>(
      context: context,
      builder: (context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: MediaQuery.sizeOf(context).height * 0.85,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: _GlassSheet(handle: false, child: builder(context)),
            ),
          ),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: const Color(0x470C1824),
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(
        8,
        0,
        8,
        8 + MediaQuery.paddingOf(context).bottom,
      ),
      child: _GlassSheet(handle: true, child: builder(context)),
    ),
  );
}

class _GlassSheet extends StatelessWidget {
  final bool handle;
  final Widget child;

  const _GlassSheet({required this.handle, required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return GlassSurface(
      key: const Key("glass_sheet"),
      fill: palette.glassStrongFill,
      shape: const RoundedSuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(38)),
      ),
      padding: EdgeInsets.fromLTRB(16, handle ? 10 : 18, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (handle)
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: palette.handle,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          Flexible(child: child),
        ],
      ),
    );
  }
}

/// The top of a glass sheet: its title and a line under it, a round glass
/// close button, and a back button when [onBack] is set.
class GlassSheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  const GlassSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    Widget round(IconData icon, String label, VoidCallback onTap) => Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: GlassSurface(
          shape: const CircleBorder(),
          child: SizedBox.square(
            dimension: 38,
            child: Icon(icon, size: 18, color: palette.text),
          ),
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        if (onBack != null)
          round(
            Icons.arrow_back_rounded,
            FlutterI18n.translate(context, "ui.go_back"),
            onBack!,
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  key: const Key("glass_sheet_title"),
                  style: palette.display(19).copyWith(color: palette.text),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: palette
                      .body(14)
                      .copyWith(height: 20 / 14, color: palette.secondaryText),
                ),
            ],
          ),
        ),
        round(
          Icons.close_rounded,
          FlutterI18n.translate(context, "accessibility.close"),
          () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
