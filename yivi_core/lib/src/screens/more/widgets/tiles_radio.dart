import "package:collection/collection.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../widgets/glass/glass_group.dart";
import "tiles.dart";

class RadioTilesCard extends StatefulWidget {
  final List<String> options;

  final Function(int index) onChanged;
  final int? defaultSelectedIndex;

  /// A heading above the group.
  final String? header;

  const RadioTilesCard({
    super.key,
    this.header,
    required this.options,
    required this.onChanged,
    this.defaultSelectedIndex,
  });

  @override
  State<RadioTilesCard> createState() => _RadioTilesCardState();
}

class _RadioTilesCardState extends State<RadioTilesCard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.defaultSelectedIndex != null) {
      _selectedIndex = widget.defaultSelectedIndex!;
    }
  }

  void _onChangeOptions(int index) {
    setState(() => _selectedIndex = index);
    widget.onChanged(_selectedIndex);
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return GlassGroup(
      header: widget.header,
      children: widget.options
          .mapIndexed(
            (i, option) => Semantics(
              selected: i == _selectedIndex,
              inMutuallyExclusiveGroup: true,
              child: Tile(
                isLink: false,
                labelTranslationKey: option,
                onTap: () => _onChangeOptions(i),
                trailing: i == _selectedIndex
                    ? Icon(Icons.check_rounded, color: palette.primary)
                    : const SizedBox(width: 24),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
