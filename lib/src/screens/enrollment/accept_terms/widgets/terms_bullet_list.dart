import 'package:flutter/material.dart';

import '../../../../theme/theme.dart';
import '../../../../widgets/bullet_list.dart';

class TermsBulletList extends StatelessWidget {
  @override
  Widget build(BuildContext context) => BulletList(
        leading: Icon(
          Icons.check,
          color: IrmaTheme.of(context).success,
        ),
        translationKeys: const [
          'enrollment.terms_and_conditions.point_1',
          'enrollment.terms_and_conditions.point_2',
          'enrollment.terms_and_conditions.point_3',
        ],
      );
}
