import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";
import "../theme/yivi_space.dart";

class InformationBox extends StatelessWidget {
  final String message;

  const InformationBox({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: theme.borderRadius,
        border: Border.all(color: theme.neutralLight, width: 1),
      ),
      padding: const EdgeInsets.all(YiviSpace.x16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: theme.primary),
          const SizedBox(width: YiviSpace.x8),
          Expanded(
            child: Text(
              message,
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
