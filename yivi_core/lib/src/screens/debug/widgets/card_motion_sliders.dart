import "package:material_ui/material_ui.dart";

import "../../../providers/irma_repository_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../data/card_transition/choreography.dart";

/// Debug sliders for how a card opens from the stack (Wallet depth). Saved
/// in the preferences; used from the next card opened.
class CardMotionSliders extends StatefulWidget {
  const CardMotionSliders({super.key});

  @override
  State<CardMotionSliders> createState() => _CardMotionSlidersState();
}

class _CardMotionSlidersState extends State<CardMotionSliders> {
  CardMotion get _m => CardMotion.current.value;

  void _set(CardMotion m) {
    setState(() => CardMotion.current.value = m);
    IrmaRepositoryProvider.of(context).preferences.setCardMotion(m.encode());
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    Widget slider({
      required Key key,
      required String label,
      required double value,
      required double min,
      required double max,
      required int divisions,
      required String shown,
      required ValueChanged<double> onChanged,
    }) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("$label: $shown", style: palette.body(14)),
        Slider(
          key: key,
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          label: shown,
          onChanged: onChanged,
        ),
      ],
    );

    final m = _m;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Card opening (Wallet)", style: palette.display(16)),
          const SizedBox(height: 8),
          slider(
            key: const Key("debug_card_duration"),
            label: "Duration (s)",
            value: m.duration,
            min: 0.2,
            max: 0.9,
            divisions: 70,
            shown: m.duration.toStringAsFixed(2),
            onChanged: (v) => _set(m.copyWith(duration: v)),
          ),
          slider(
            key: const Key("debug_card_bounce"),
            label: "Bounce (0 none, 0.3 bouncy)",
            value: m.bounce,
            min: 0,
            max: 0.6,
            divisions: 60,
            shown: m.bounce.toStringAsFixed(2),
            onChanged: (v) => _set(m.copyWith(bounce: v)),
          ),
          slider(
            key: const Key("debug_card_above"),
            label: "Cards above (s; slower settles behind the card)",
            value: m.aboveDuration,
            min: 0.2,
            max: 0.9,
            divisions: 70,
            shown: m.aboveDuration.toStringAsFixed(2),
            onChanged: (v) => _set(m.copyWith(aboveDuration: v)),
          ),
          slider(
            key: const Key("debug_card_fall"),
            label: "Delay per falling card (ms)",
            value: m.fallStagger,
            min: 0,
            max: 45,
            divisions: 45,
            shown: m.fallStagger.round().toString(),
            onChanged: (v) => _set(m.copyWith(fallStagger: v.roundToDouble())),
          ),
          slider(
            key: const Key("debug_card_sink"),
            label: "Delay per sinking card (ms)",
            value: m.sinkStagger,
            min: 0,
            max: 140,
            divisions: 28,
            shown: m.sinkStagger.round().toString(),
            onChanged: (v) => _set(m.copyWith(sinkStagger: v.roundToDouble())),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              key: const Key("debug_card_reset"),
              onPressed: () => _set(CardMotion.defaults),
              child: const Text("Reset"),
            ),
          ),
        ],
      ),
    );
  }
}
