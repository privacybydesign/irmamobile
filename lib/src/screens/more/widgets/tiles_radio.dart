import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'tiles.dart';
import 'tiles_card.dart';

class RadioTilesCard extends StatefulWidget {
  final List<String> options;

  final Function(int index) onChanged;
  final int? defaultSelectedIndex;

  const RadioTilesCard({
    Key? key,
    required this.options,
    required this.onChanged,
    this.defaultSelectedIndex,
  }) : super(key: key);

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

  _onChangeOptions(int index) {
    setState(() => _selectedIndex = index);
    widget.onChanged(_selectedIndex);
  }

  @override
  Widget build(BuildContext context) {
    return TilesCard(
      children: widget.options
          .mapIndexed(
            (i, option) => Tile(
              labelTranslationKey: option,
              onTap: () => _onChangeOptions(i),
              trailing: i == _selectedIndex
                  ? const Icon(
                      Icons.check,
                    )
                  : const SizedBox(),
            ),
          )
          .toList(growable: false),
    );
  }
}
