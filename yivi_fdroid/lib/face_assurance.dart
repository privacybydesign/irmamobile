import "package:flutter/material.dart";
import "package:yivi_core/yivi_core.dart";

enum FaceAssuranceLevel {
  // Only the on-device "low" level is reachable in the F-Droid build today.
  // More levels (remote/certified) can be added here when they exist.
  low(label: "Low", description: "On-device, open source model.");

  const FaceAssuranceLevel({required this.label, required this.description});

  final String label;
  final String description;
}

const _faceVerifiedCredentialKeywords = <String>["passport", "idcard", "drivinglicence"];

bool _isFaceVerifiedCredential(Credential credential) {
  final id = credential.credentialId.toLowerCase();
  return _faceVerifiedCredentialKeywords.any(id.contains);
}

Widget? faceAssuranceContentBuilder(BuildContext context, Credential credential) {
  if (!_isFaceVerifiedCredential(credential)) return null;
  // The F-Droid flow only reaches the on-device "low" level for now. This is at the moment hardcoded. but also all there is at the moment.
  return _FaceAssuranceSection(level: FaceAssuranceLevel.low);
}

class _FaceAssuranceSection extends StatelessWidget {
  const _FaceAssuranceSection({required this.level});

  final FaceAssuranceLevel level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.verified_user, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Gezichtsverificatie",
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  level.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(level.description, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
        ],
      ),
    );
  }
}
