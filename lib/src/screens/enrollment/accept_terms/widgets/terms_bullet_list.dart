import 'package:flutter/material.dart';

import '../../../../widgets/bullet_list.dart';

class TermsBulletList extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const BulletList(
        translationKeys: [
          'enrollment.terms_and_conditions.point_1',
          'enrollment.terms_and_conditions.point_2',
          'enrollment.terms_and_conditions.point_3',
        ],
      );
}
