import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../../theme/theme.dart";
import "../attribute_comparison.dart";
import "../attribute_group.dart";
import "../attribute_image.dart";
import "../attribute_value_formatting.dart";
import "profile_header_renderer.dart";

/// The top of an identity credential, like the top of an ID card: the photo
/// (when shared) beside the name, with date of birth, place of birth,
/// nationality and gender below it. Without a photo the text starts at the
/// left edge; there is no placeholder, so a photo area always means the photo
/// is there.
class ProfileHeader extends StatelessWidget {
  final ProfileHeaderView view;

  const ProfileHeader({required this.view})
    : super(key: const Key("attribute_group_profile_header"));

  static const _prefix = "credential.profile_header";

  static const _icons = {
    "date_of_birth": Icons.cake_outlined,
    "place_of_birth": Icons.place_outlined,
    "nationality": Icons.flag_outlined,
    "gender": Icons.person_outline,
  };

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final isLast = AttributeGroupScope.maybeOf(context)?.isLast ?? true;

    String text(ProfileField field) =>
        field.text ?? FlutterI18n.translate(context, field.translationKey!);

    final details = [
      (view.dateOfBirth, "date_of_birth"),
      (view.placeOfBirth, "place_of_birth"),
      (view.nationality, "nationality"),
      (view.gender, "gender"),
    ].where((d) => d.$1 != null).toList();

    final name = view.name;
    final photo = view.photo;

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        Row(
          crossAxisAlignment: .start,
          children: [
            if (photo != null) ...[
              TappableAttributeImage(
                attribute: photo,
                maxWidth: 72,
                maxHeight: 96,
              ),
              SizedBox(width: theme.defaultSpacing),
            ],
            Expanded(
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                spacing: theme.tinySpacing,
                children: [
                  if (name != null)
                    Text(
                      text(name),
                      style: attributeValueStyle(
                        theme,
                        comparisonColor(theme, name.comparison),
                      ).copyWith(fontSize: 20),
                    ),
                  if (details.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: theme.tinySpacing),
                      child: Wrap(
                        spacing: theme.defaultSpacing,
                        runSpacing: theme.tinySpacing,
                        children: [
                          for (final (field, label) in details)
                            _IconField(
                              key: Key("profile_header_$label"),
                              icon: _icons[label]!,
                              label: FlutterI18n.translate(
                                context,
                                "$_prefix.$label",
                              ),
                              value: text(field!),
                              color: comparisonColor(theme, field.comparison),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        // Separates the header from the ordinary rows below it, if any.
        if (!isLast) ...[
          SizedBox(height: theme.smallSpacing),
          Container(
            key: const Key("profile_header_divider"),
            height: 1,
            color: theme.neutralExtraLight,
          ),
        ],
      ],
    );
  }
}

/// A detail as a small muted icon followed by its value. Screen readers hear
/// the label instead of the icon.
class _IconField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _IconField({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Semantics(
      label: "$label $value",
      excludeSemantics: true,
      child: Row(
        mainAxisSize: .min,
        spacing: theme.tinySpacing,
        children: [
          Icon(icon, size: 16, color: theme.neutralDark),
          Text(
            value,
            style: attributeValueStyle(theme, color).copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
