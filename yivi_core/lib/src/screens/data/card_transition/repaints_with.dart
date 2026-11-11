import "package:flutter/foundation.dart";
import "package:flutter/rendering.dart";

/// A render object that paints again whenever [repaintSource] notifies,
/// while it is attached: the listening that a card transition's layers and
/// a flying card's clip share.
mixin RepaintsWith on RenderObject {
  Listenable? _repaintSource;

  Listenable? get repaintSource => _repaintSource;

  set repaintSource(Listenable? value) {
    if (value == _repaintSource) return;
    if (attached) _repaintSource?.removeListener(markNeedsPaint);
    _repaintSource = value;
    if (attached) _repaintSource?.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _repaintSource?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _repaintSource?.removeListener(markNeedsPaint);
    super.detach();
  }
}
