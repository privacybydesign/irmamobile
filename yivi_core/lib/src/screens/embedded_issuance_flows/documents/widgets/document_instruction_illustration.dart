import "dart:math" as math;

import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";

import "../../../../util/test_detection.dart";
import "document_scan_scene.dart";

/// The picture of the instruction screen, as on the canvas (Document
/// animations, C): the passport open on its photo page, the back of an ID
/// card or the front of a driving licence lying on a table, and a phone
/// hovering above it that shows the document on its screen, with the machine
/// readable zone outlined and a red band sweeping over it (see
/// [DocumentScanScene]).
///
/// The band loops every 2.4 s and the phone bobs every 3.2 s; both stand still
/// when the platform asks for less motion and under integration tests (so
/// `pumpAndSettle` can finish).
class DocumentInstructionIllustration extends StatefulWidget {
  const DocumentInstructionIllustration({
    required this.documentType,
    super.key,
  });

  final DocumentType documentType;

  @override
  State<DocumentInstructionIllustration> createState() =>
      _DocumentInstructionIllustrationState();
}

class _DocumentInstructionIllustrationState
    extends State<DocumentInstructionIllustration>
    with TickerProviderStateMixin {
  late final _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  /// The phone going up and back down, once per loop.
  late final _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  /// 0 at the bottom of the bob, 1 at its top, eased at both ends.
  late final _hover = _bob.drive(_UpAndDown());

  /// Where the band rests without motion: over the zone, fully visible.
  static const _restingPoint = 0.4;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = motionStill(context);
    if (still) {
      _sweep
        ..stop()
        ..value = _restingPoint;
      _bob
        ..stop()
        ..value = 0;
    } else {
      if (!_sweep.isAnimating) _sweep.repeat();
      if (!_bob.isAnimating) _bob.repeat();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Purely decorative: the screen's image label and texts say the same.
    return ExcludeSemantics(
      child: DocumentScanScene(
        documentType: widget.documentType,
        sweep: _sweep,
        hover: _hover,
      ),
    );
  }
}

/// Up and back down over the loop: (1 − cos 2πt) / 2.
class _UpAndDown extends Animatable<double> {
  @override
  double transform(double t) => (1 - math.cos(2 * math.pi * t)) / 2;
}
