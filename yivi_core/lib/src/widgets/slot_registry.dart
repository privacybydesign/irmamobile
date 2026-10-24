import "package:material_ui/material_ui.dart";

/// Where the widgets are that something flies from or to, by [K]: a slot
/// puts its context in while it builds, and takes it out when it goes or
/// gets another key, if it is still the one there.
class SlotRegistry<K> {
  final _slots = <K, BuildContext>{};

  BuildContext? operator [](K key) => _slots[key];

  void put(K key, BuildContext context) => _slots[key] = context;

  /// Forgets [key], if [context] is still the slot there.
  void drop(K key, BuildContext context) {
    if (_slots[key] == context) _slots.remove(key);
  }
}

/// Keeps [child]'s place in [registry] under [id].
class RegisteredSlot<K> extends StatefulWidget {
  final SlotRegistry<K> registry;
  final K id;
  final Widget child;

  const RegisteredSlot({
    super.key,
    required this.registry,
    required this.id,
    required this.child,
  });

  @override
  State<RegisteredSlot<K>> createState() => _RegisteredSlotState<K>();
}

class _RegisteredSlotState<K> extends State<RegisteredSlot<K>> {
  @override
  void didUpdateWidget(RegisteredSlot<K> old) {
    super.didUpdateWidget(old);
    old.registry.drop(old.id, context);
  }

  @override
  void dispose() {
    widget.registry.drop(widget.id, context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.registry.put(widget.id, context);
    return widget.child;
  }
}
