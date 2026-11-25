import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_space.dart";
import "../../../widgets/surfaces/surface_card.dart";

/// A checkbox row on its own rounded surface.
class EnrollmentCheckCard extends StatelessWidget {
  final Widget child;

  const EnrollmentCheckCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(
        YiviSpace.x4,
        YiviSpace.x4,
        YiviSpace.x16,
        YiviSpace.x4,
      ),
      child: child,
    );
  }
}
