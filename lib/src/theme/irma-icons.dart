import 'package:flutter/widgets.dart';

@immutable
class IrmaIconsData extends IconData {
  const IrmaIconsData(int codePoint)
      : super(
          codePoint,
          fontFamily: 'IrmaIcons',
        );
}

@immutable
class IrmaIcons {
  IrmaIcons._();

  // Generated code: do not hand-edit.
  static const IconData arrowDown = IrmaIconsData(0xe000);

  static const IconData remove = IrmaIconsData(0xe001);

  static const IconData update = IrmaIconsData(0xe002);
}
