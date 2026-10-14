part of "yivi_pin_screen.dart";

class _UnsecurePinDescriptionTile extends StatelessWidget {
  final bool followsRule;
  final String descriptionKey;
  const _UnsecurePinDescriptionTile({
    required this.followsRule,
    required this.descriptionKey,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final (fill, ink) = followsRule
        ? (palette.successSurface, palette.successText)
        : (palette.errorSurface, palette.danger);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
            child: Icon(
              followsRule ? Icons.check_rounded : Icons.close_rounded,
              size: 16,
              color: ink,
              semanticLabel: FlutterI18n.translate(
                context,
                followsRule
                    ? "credential.boolean_yes"
                    : "credential.boolean_no",
              ),
            ),
          ),
          Expanded(
            child: Text(
              FlutterI18n.translate(context, descriptionKey),
              style: palette.body(15).copyWith(height: 22 / 15),
            ),
          ),
        ],
      ),
    );
  }
}
