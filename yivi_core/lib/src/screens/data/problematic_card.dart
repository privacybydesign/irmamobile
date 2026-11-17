part of "data_tab.dart";

/// A card for a credential the wallet stored but cannot render (see
/// [ProblematicCredential]). Shown in a danger style with the failure
/// reason and a trashcan to remove a credential that would otherwise be stuck in
/// storage — it has no detail screen to route to, so deletion is inline.
class _ProblematicCredentialCard extends ConsumerWidget {
  const _ProblematicCredentialCard({required this.credential});

  final ProblematicCredential credential;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final title = context.tr("data.problematic.title");

    return Material(
      color: palette.errorSurface,
      shape: const RoundedRectangleBorder(borderRadius: YiviCorners.cardRadius),
      child: Padding(
        padding: const EdgeInsets.all(YiviSpace.x16),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: palette.danger, size: 28),
            const SizedBox(width: YiviSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: palette.display(16).copyWith(color: palette.text),
                  ),
                  const SizedBox(height: YiviSpace.x4),
                  Text(
                    context.tr("data.problematic.explanation"),
                    style: palette.body(14).copyWith(color: palette.heading),
                  ),
                  const SizedBox(height: YiviSpace.x4),
                  Text(
                    credential.reason,
                    style: palette.body(12).copyWith(color: palette.heading),
                  ),
                ],
              ),
            ),
            const SizedBox(width: YiviSpace.x8),
            YiviIconButton(
              key: Key("${credential.credentialId ?? "problematic"}_delete"),
              icon: Icons.delete_outline_rounded,
              danger: true,
              label: context.tr("accessibility.remove"),
              onTap: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) =>
      confirmAndDeleteCredential(
        context,
        ref.read(irmaRepositoryProvider),
        credential.credentialInstanceIds,
      );
}
