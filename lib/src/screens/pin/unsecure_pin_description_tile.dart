part of pin;

class _UnsecurePinDescriptionTile extends StatelessWidget {
  final bool followsRule;
  final String descriptionKey;
  const _UnsecurePinDescriptionTile({Key? key, required this.followsRule, required this.descriptionKey})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return ListTile(
      leading: Icon(
        followsRule ? Icons.check : Icons.close,
        color: followsRule ? Colors.green : Colors.red,
      ),
      horizontalTitleGap: 8.0,
      title: Text(
        FlutterI18n.translate(context, descriptionKey),
        style: theme.textTheme.bodyText1?.copyWith(fontWeight: FontWeight.w400),
      ),
      minVerticalPadding: 0.0,
      visualDensity: const VisualDensity(vertical: -4.0),
    );
  }
}
