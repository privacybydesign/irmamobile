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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          ToneDisc(
            icon: followsRule ? Icons.check_rounded : Icons.close_rounded,
            tone: followsRule ? YiviTone.success : YiviTone.danger,
            size: 24,
            iconSize: 16,
            semanticLabel: context.tr(
              followsRule ? "credential.boolean_yes" : "credential.boolean_no",
            ),
          ),
          Expanded(
            child: Text(
              context.tr(descriptionKey),
              style: palette.body(15).copyWith(height: 22 / 15),
            ),
          ),
        ],
      ),
    );
  }
}
