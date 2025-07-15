part of 'yivi_pin_screen.dart';

class _UnsecurePinDescriptionTile extends StatelessWidget {
  final bool followsRule;
  final String descriptionKey;
  const _UnsecurePinDescriptionTile({required this.followsRule, required this.descriptionKey});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(followsRule ? Icons.check : Icons.close, size: 16, color: followsRule ? Colors.green : Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(FlutterI18n.translate(context, descriptionKey), style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
